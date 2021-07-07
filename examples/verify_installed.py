import jxlpy
pillow_support = False
try:
    from jxlpy import JXLImagePlugin
    pillow_support = True
except:
    pass

print('Module version:', jxlpy.__version__)
print('libjxl version:', jxlpy._jxl_version)
print('Pillow plugin:', pillow_support)
