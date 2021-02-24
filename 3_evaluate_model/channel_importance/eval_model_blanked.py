#*********************************************************************************
# Description:  takes in csv data and converts to numpy array.
#               should have list of samples (e.g. yld1000.csv) in same directory
#
# Usage: python eval_model_blanked.py <set> <index for day> <channel to blank>
#        python eval_model_blanked.py SetA 5 CIgreen
#*********************************************************************************
import os
import sys, getopt
import tensorflow as tf
import numpy as np 
import pandas as pd 
import tensorflow.keras as keras
from tensorflow.keras import Sequential
from tensorflow.keras.layers import Dense, Flatten, Dropout, Reshape
from tensorflow.keras.layers import Conv2D, Conv3D, MaxPooling3D
from tensorflow.keras.optimizers import SGD
from my_classes import DataGenerator 

set = str(sys.argv[1])
daysidx = int(sys.argv[2])
blanked = str(sys.argv[3])

###### global variables for dataset  
channels = ["CIgreen","GNDVI", "NAVI","NDVI","RENDVI","TGI","Thermal"] #should match filenames e.g. 
days = ["04-11-2019","05-21-2019","06-13-2019","06-29-2019","07-11-2019","08-01-2019","08-13-2019","08-21-2019","08-28-2019","09-07-2019","09-13-2019"]
day = days[daysidx]
path_to_labs = f'/storage/ebellis/{set}/labels/'
path_to_img = f'/storage/ebellis/{set}/images/08-01-2019/test/arrays_blanked/{blanked}/'

###### use data generator to generate test data samples in each batch    
batch_size_test = 32
test_generator = DataGenerator(path_to_labs, path_to_img, batch_size_test, 'test', day, channels)

model = tf.keras.models.load_model(f'../{set}/Aug01/models')

##### evaluate model
scores = model.evaluate(test_generator)
print(f'MSE for 2DCNN on test set for {set} on {day} with mean {blanked} blanked is {scores[1]:.0f}')
