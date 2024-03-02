from PIL import Image, ImageFile
from io import BytesIO
import jxlpy

_VALID_JXL_MODES = {"RGB", "RGBA", "L", "LA"}


def _accept(data):
    return data[:2] == b'\xff\x0a' \
        or data[:12] == b'\x00\x00\x00\x0c\x4a\x58\x4c\x20\x0d\x0a\x87\x0a'


class JXLImageFile(ImageFile.ImageFile):

    format = "JXL"
    format_description = "Jpeg XL image"
    __loaded = 0
    __logical_frame = 0

    def _open(self):

        self.fc = self.fp.read()
        self._decoder = jxlpy.JXLPyDecoder(self.fc)
        
        self._jxlinfo = self._decoder.get_info()
        
        if self._jxlinfo['bits_per_sample'] != 8:
            raise NotImplementedError('bits_per_sample not equals 8')

        self._size = (self._jxlinfo['xsize'], self._jxlinfo['ysize'])
        self.is_animated = self._jxlinfo['have_animation']
        self.n_frames = self._decoder.get_n_frames()
        self._mode = self.rawmode = self._decoder.get_colorspace()

        self.info['icc'] = self._decoder.get_icc_profile()
        
        self.tile = []

        self._rewind()


    def _get_next(self):

        # Get next frame
        next_frame = self._decoder.get_frame()
        self.__physical_frame += 1

        # this actually means EOF, errors are raised in _jxl
        if next_frame is None:
            msg = "failed to decode next frame in JXL file"
            raise EOFError(msg)

        return next_frame

    def _rewind(self, hard=False):
        if hard:
            self._decoder.rewind()
        self.__physical_frame = 0
        self.__loaded = -1
        self.__timestamp = 0

    def _seek_check(self, frame):
        # if image is not animated then only the 0th frame is available
        if (not self.is_animated and frame != 0) or (
            self.n_frames is not None and (frame >= self.n_frames or frame < 0)
        ):
            msg = "attempt to seek outside sequence"
            raise EOFError(msg)

        return self.tell() != frame

    def _seek(self, frame):
        # print("_seek: phy: {}, fr: {}".format(self.__physical_frame, frame))
        if frame == self.__physical_frame:
            return  # Nothing to do
        if frame < self.__physical_frame:
            # also rewind libjxl decoder instance
            self._rewind(hard=True)

        while self.__physical_frame < frame:
            self._get_next()  # Advance to the requested frame

    def seek(self, frame):
        if not self._seek_check(frame):
            return

        # Set logical frame to requested position
        self.__logical_frame = frame

    def load(self):

        if self.__loaded != self.__logical_frame:
            self._seek(self.__logical_frame)

            data = self._get_next()
            self.__loaded = self.__logical_frame

            # Set tile
            if self.fp and self._exclusive_fp:
                self.fp.close()
            self.fp = BytesIO(data)
            self.tile = [("raw", (0, 0) + self.size, 0, self.rawmode)]

        return super().load()
    
    # this prevents Pillow ValueError since it doesn't try to mmap image data
    # when we implement selected custom functions
    def load_seek(self, pos):
        pass
    
    def tell(self):
        return self.__logical_frame


def _save(im, fp, filename, save_all=False):

    if im.mode not in _VALID_JXL_MODES:
        raise NotImplementedError('Only RGB, RGBA, L, LA are supported.')

    info = im.encoderinfo.copy()
    icc_profile = info.get("icc_profile") or b""
    
    # default quality is 70
    quality = info.get('quality', 70)
    if info.get('lossless'):
        quality = 100
    effort = info.get('effort', 7)
    decoding_speed = info.get('decoding_speed', 0)
    use_container = info.get('use_container', True)
    num_threads = info.get('threads', 0)
    
    enc = jxlpy.JXLPyEncoder(
        quality=quality, size=im.size, colorspace=im.mode, 
        effort=effort, decoding_speed=decoding_speed, use_container=use_container,
        num_threads=num_threads, icc_profile=icc_profile
    )
    
    enc.add_frame(im.tobytes())
    
    data = enc.get_output()
    fp.write(data)
    
    enc.close()


Image.register_open(JXLImageFile.format, JXLImageFile, _accept)
Image.register_save(JXLImageFile.format, _save)
Image.register_extension(JXLImageFile.format, ".jxl")
Image.register_mime(JXLImageFile.format, "image/jxl")
