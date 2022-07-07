import jxlpy

with open('test.jxl', 'rb') as f:
    fc = f.read()

dec = jxlpy.JXLPyDecoder(fc)
info = dec.get_info()
colorspace = dec.get_colorspace()

print('Read informations about image:', info)
print('Colorspace:', colorspace)

while True:

    frame = dec.get_frame()
    if frame is None:
        break
    
    print('First pixel is:', list(frame[:3] if colorspace == 'RGB' else frame[:4]))
