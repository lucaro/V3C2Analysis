import easyocr
import cv2
import json
import numpy as np
import os
import os.path
import glob

def convert(o):
    if isinstance(o, np.generic): return o.item()  
    raise TypeError

readers = [
    easyocr.Reader(['la', 'en', 'de', 'fr', 'es', 'cs', 'is'], gpu = False),
    #easyocr.Reader(['ch_tra'], gpu = False),
    #easyocr.Reader(['fa'], gpu = False),
    #easyocr.Reader(['hi'], gpu = False), 
    #easyocr.Reader(['ja'], gpu = False), 
    #easyocr.Reader(['ko'], gpu = False),
    #easyocr.Reader(['th'], gpu = False),
]

basedir = "keyframes/"

dirs = os.listdir(basedir)


for d in dirs:

    outfile = 'ocr/' + d + '.json'
    if os.path.isfile(outfile):
        print("found " + outfile + ", skipping")
        continue
    
    files = glob.glob(basedir + d + "/*.png")
    
    ocr = {}

    for f in files:
        i = f.split("_")[-2]
        img = cv2.imread(f)
        
        results = []
        for reader in readers:
            results = results + reader.readtext(img)
        
        h = list(filter(lambda result : len(result) > 2 and len(result[1]) > 0 and result[2] >= 0.1, results))
        
        if len(h) > 0:
            ocr[i] = h
            
    with open(outfile,'w') as f:    
        json.dump(ocr, f, indent=1, default=convert)
        
    print(d)
    
    