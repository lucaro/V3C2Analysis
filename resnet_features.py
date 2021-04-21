import tensorflow as tf
import numpy as np
import os
import time
import datetime
import pickle
import cv2
import sys
import traceback

gpu_devices = tf.config.experimental.list_physical_devices('GPU')
tf.config.experimental.set_memory_growth(gpu_devices[0], True)
#tf.config.experimental.set_virtual_device_configuration(gpu_devices[0], [tf.config.experimental.VirtualDeviceConfiguration(memory_limit=3000)])

base_path = 'v3c2/'

files = os.listdir(base_path)


model = tf.keras.applications.InceptionResNetV2(
    include_top=False,
    weights="imagenet",
    pooling="avg")

for file in files:
  outfile = base_path + file + '.pickle'
  if os.path.isfile(outfile):
    print('found ' + outfile + ', skipping')
    continue
  try:
    print('starting ' + file)
    VideoCap = cv2.VideoCapture(base_path + file)
    VideoFrame = int(VideoCap.get(cv2.CAP_PROP_FRAME_COUNT))
    print(VideoFrame)
    framenumber = 0
    frames = []
    all_features = []
    while framenumber < VideoFrame:
        _, frame = VideoCap.read()
        if frame is None:
            continue

        frame = cv2.resize(frame[:, :, ::-1], (299, 299))
        img = tf.keras.applications.inception_resnet_v2.preprocess_input(frame)
        framenumber += 1
        frames.append(img)
        if len(frames) >= 10:
          in_tensor = tf.stack(frames, axis=0)
          features = model.predict(in_tensor)
          all_features.extend(features)
          frames = []
          print('.', end='', flush=True)

    if len(frames) > 0:
      in_tensor = tf.stack(frames, axis=0)
      features = model.predict(in_tensor)
      all_features.extend(features)

    print(' ')
    print('storing...')
    pickle.dump(all_features, open(base_path + file + '.pickle', 'wb'))
    print('completed ' + file, datetime.datetime.now().strftime("%d/%m/%Y %H:%M:%S"))
  except Exception as e:
    print(e)
    traceback.print_exc(file=sys.stdout)
