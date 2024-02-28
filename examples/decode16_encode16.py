import requests
import jxlpy
import os

remote_source = 'https://people.csail.mit.edu/ericchan/hdr/jxl_images/20140606_102418_IMGP0297.jxl'
local_source = os.path.basename(remote_source)

# download image if necessary
if not os.path.exists(local_source):
    r = requests.get(remote_source)
    assert(r.status_code == 200)
    with open(local_source, 'wb') as f:
        f.write(r.content)

with open(local_source, 'rb') as f:
    fc = f.read()


dec = jxlpy.JXLPyDecoder(fc)
info = dec.get_info()
icc = dec.get_icc_profile()
colorspace = dec.get_colorspace()

print('\n=== DECODING SOURCE IMAGE ===\n')
print('Read information about image:', info)
print('Colorspace:', colorspace)
print('ICC:', icc)

while True:

    frame = dec.get_frame()
    if frame is None:
        break
    
    print('Beginning of Image data:', list(frame[:99]))

    enc = jxlpy.JXLPyEncoder(quality=100, colorspace='RGB', size=(info.get('xsize'), info.get('ysize')), effort=3, bit_depth=info.get('bits_per_sample'), alpha_bit_depth=info.get('alpha_bits'), icc_profile=icc)
    enc.add_frame(frame)

    with open('test16.jxl', 'wb') as f:
        f.write(enc.get_output())


# decode just encoded image
with open('test16.jxl', 'rb') as f:
    fc = f.read()

dec = jxlpy.JXLPyDecoder(fc)
info = dec.get_info()
colorspace = dec.get_colorspace()

print('\n=== DECODING RE-ENCODED IMAGE ===\n')
print('Read information about image:', info)
print('Colorspace:', colorspace)

while True:

    frame = dec.get_frame()
    if frame is None:
        break
    
    print('Beginning of Image data:', list(frame[:99]))

