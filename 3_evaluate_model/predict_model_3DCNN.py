#!/usr/bin/env python
import os
import glob
import sys, getopt
import tensorflow as tf
import numpy as np 
import tensorflow.keras as keras
from tensorflow.keras import Sequential
from tensorflow.keras.layers import Dense, Flatten, Dropout, Reshape, Conv2D, Conv3D, MaxPooling3D
from tensorflow.keras.optimizers import SGD
from my_classes import DataGenerator 
from pandas import read_csv

set = str(sys.argv[1])

outFile = open(f'preds_3dcnn_{set}_val.csv', 'w')

#### function to load .npy and print predicted and observed vals to file
def writeToList(lab, img):
    if os.path.isfile(lab) and os.path.isfile(img):
        tmp = np.load(img)
        preds = model.predict(np.expand_dims(tmp, 0)).squeeze()
        preds = list(np.ndarray.flatten(preds))
        labs = read_csv(lab, header = None).values
        labs = list(np.ndarray.flatten(labs))

        i = 0

        while i < len(preds):
            outFile.write(f'{preds[i]:.2f},{labs[i]}\n')
            i += 1    

###### load model and make predictions    
model = tf.keras.models.load_model('models')

outFile.write('predicted,observed\n')

files = glob.glob(f'/storage/ebellis/{set}/images/arrays/val/*npy')  
for file in files:
    img = file
    lab = img.replace('img','yld').replace('images/arrays','labels/08-01-2019').replace('npy','csv')
    writeToList(lab, img)

outFile.close()
