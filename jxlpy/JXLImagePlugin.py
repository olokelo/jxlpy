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
    __loaded = -1
    __frame = 0

    def _open(self):

        self.fc = self.fp.read()
        self._decoder = jxlpy.JXLPyDecoder(self.fc)
        
        self._jxlinfo = self._decoder.get_info()
        
        if self._jxlinfo['bits_per_sample'] != 8:
            raise NotImplementedError('bits_per_sample not equals 8')
        self._size = (self._jxlinfo['xsize'], self._jxlinfo['ysize'])
        self.is_animated = self._jxlinfo['have_animation']
        self._mode = self.rawmode = self._decoder.get_colorspace()
        self.tile = []


    def seek(self, frame):

        self.load()
    
        if self.__frame+1 != frame:
            # I believe JPEG XL doesn't support seeking in animations
            raise NotImplementedError(
                'Seeking more than one frame forward is currently not supported.'
            )
        self.__frame = frame


    def load(self):

        if self.__loaded != self.__frame:
        
            data = self._decoder.get_frame()
            
            if data is None:
                EOFError('no more frames')
            
            self.__loaded = self.__frame
            
            if self.fp and self._exclusive_fp:
                self.fp.close()
            self.fp = BytesIO(data)
            self.tile = [("raw", (0, 0) + self.size, 0, self.rawmode)]
        
        return super().load()
    
    
    def tell(self):
        return self.__frame


def _save(im, fp, filename, save_all=False):

    if im.mode not in _VALID_JXL_MODES:
        raise NotImplementedError('Only RGB, RGBA, L, LA are supported.')

    info = im.encoderinfo.copy()
    
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
        num_threads=num_threads
    )
    
    enc.add_frame(im.tobytes())
    
    data = enc.get_output()
    fp.write(data)
    
    enc.close()


Image.register_open(JXLImageFile.format, JXLImageFile, _accept)
Image.register_save(JXLImageFile.format, _save)
Image.register_extension(JXLImageFile.format, ".jxl")
Image.register_mime(JXLImageFile.format, "image/jxl")
