from PIL import Image
from jxlpy import JXLImagePlugin

im = Image.open('test.jxl')
im = im.resize((im.width*2, im.height*2))
im.save('test_2x.jxl', lossless=True, effort=7)
