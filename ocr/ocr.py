import easyocr
import cv2
import json
import numpy as np
import os
import os.path
import glob
from datetime import datetime
import random

def convert(o):
    if isinstance(o, np.generic): return o.item()
    raise TypeError

readers = [
    easyocr.Reader(['la', 'en', 'de', 'fr', 'es', 'cs', 'is']),
    easyocr.Reader(['ch_tra']),
    easyocr.Reader(['fa']),
    easyocr.Reader(['hi']),
    easyocr.Reader(['ja']),
    easyocr.Reader(['ko']),
    easyocr.Reader(['th'])
]

basedir = "/srv/scratch3/rossetto/keyframes/"

dirs = os.listdir(basedir)

counter = 0

random.shuffle(dirs)
for d in dirs:

    outfile = d + '.json'
    if os.path.isfile(outfile):
        #print("found " + outfile + ", skipping")
        continue

    files = glob.glob(basedir + d + "/*.png")

    ocr = {}

    print("starting", d)

    for f in files:
        i = f.split("_")[-2]
        img = cv2.imread(f)

        print('-', end='', flush=True)

        results = []
        for reader in readers:
            results = results + reader.readtext(img)

        h = list(filter(lambda result : len(result) > 2 and len(result[1]) > 0 and result[2] >= 0.1, results))

        if len(h) > 0:
            ocr[i] = h

        print('.', end='', flush=True)

    with open(outfile,'w') as f:
        json.dump(ocr, f, indent=1, default=convert)

    print()
    print("completed " + d + " at ", datetime.now())

    counter = counter + 1
    if counter >= 3:
        break
