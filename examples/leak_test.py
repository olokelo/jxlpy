from PIL import Image
from jxlpy import JXLImagePlugin
from io import BytesIO
import jxlpy
import os
import sys
import psutil
import requests
import gc

def get_mem(text):
    process = psutil.Process(os.getpid())
    print("{}: {}".format(text, process.memory_info().rss))

r = requests.get("https://w2w-images.sftcdn.net/image/upload/v1620662834/Ghacks/IMG_20200308_194050.jxl")
if r.status_code != 200:
    raise Exception("Couldn't load image from the web")
fc = r.content

for iters in (1, 10, 50):

    print("=== TESTING FOR {} ITERATIONS ===".format(iters), iters)

    get_mem("Decode before")

    for i in range(iters):

        dec = jxlpy.JXLPyDecoder(fc)

        while True:

            frame = dec.get_frame()
            if frame is None:
                break

    del dec, frame
    gc.collect()

    get_mem("Decode after")


    get_mem("Decode+Encode before")

    for i in range(iters):
        
        dec = jxlpy.JXLPyDecoder(fc)
        info = dec.get_info()
        colorspace = dec.get_colorspace()
        size = (info.get('xsize'), info.get('ysize'))
        enc = jxlpy.JXLPyEncoder(quality=50, colorspace=colorspace, size=size, effort=7)
        
        while True:

            frame = dec.get_frame()
            if frame is None:
                break
            enc.add_frame(frame)
    
    del dec, enc, frame
    gc.collect()

    get_mem("Decode+Encode after")
    
    
    get_mem("Pillow Decode before")
    
    bio = BytesIO(fc)
    for i in range(iters):
        
        bio.seek(0)
        im = Image.open(bio)
        #im.save('/tmp/img.jxl', quality=50, effort=7)
        #im.close()
    
    del bio, im
    gc.collect()
    
    get_mem("Pillow Decode after")
    
