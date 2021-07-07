import jxlpy

size = (64, 64)
data = bytes([0, 188, 212] * (size[0] * size[1]))

enc = jxlpy.JXLPyEncoder(quality=100, colorspace='RGB', size=size, effort=7)
enc.add_frame(data)

with open('test.jxl', 'wb') as f:
    f.write(enc.get_output())

enc.close()
