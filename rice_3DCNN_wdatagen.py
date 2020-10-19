#!/usr/bin/env python
import tensorflow as tf
import numpy as np 
import pandas as pd 
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
import tensorflow.keras as keras
from tensorflow.keras import Sequential
from tensorflow.keras.layers import Dense, Flatten, Dropout, Reshape
from tensorflow.keras.layers import Conv2D, Conv3D, MaxPooling3D
from tensorflow.keras.optimizers import SGD
from matplotlib import pyplot
from my_classes import DataGenerator 

tf.config.list_physical_devices('GPU')

###### global variables for dataset  
channels = ["CIgreen","GNDVI", "NAVI","NDVI","RENDVI","TGI","Thermal"] #should match filenames e.g. 
days = ["04-11-2019","05-21-2019","06-13-2019","06-29-2019","07-11-2019","08-01-2019","08-13-2019","08-21-2019","08-28-2019","09-07-2019","09-13-2019"]
#path_to_labs = "E:/Data/Humnoke/Carr_North/infiles_for_2DCNN/labels/"
path_to_labs = "E:/Data/Humnoke/Carr_North/test_files/labels/"
#path_to_img = "E:/Data/Humnoke/Carr_North/infiles_for_2DCNN/images/"
path_to_img = "E:/Data/Humnoke/Carr_North/test_files/images/"

###### use data generator to generate training and validation data samples in each batch    
batch_size_train = 32
batch_size_val = 32

train_generator = DataGenerator(path_to_labs, path_to_img, batch_size_train, 'train', days, channels)
val_generator = DataGenerator(path_to_labs, path_to_img, batch_size_val, 'val', days, channels)

###### define CNN architecture 
model = Sequential()
model.add(Conv3D(filters=64, kernel_size=(3,3,3), padding="same", activation='relu', input_shape=(3,3,11,7)))
model.add(Conv3D(filters=128, kernel_size=(2,2,3), padding="same", activation='relu'))
model.add(Conv3D(filters=256, kernel_size=(1,1,11), padding="valid", activation='relu'))
model.add(Reshape((3,3,256)))
model.add(Flatten())
model.add(Dense(256, activation='relu')) # or 512
model.add(Dense(2304))
        
# deconvolution steps
model.add(Reshape((3,3,256)))
model.add(Conv2D(filters=128, kernel_size=(2,2), activation='relu', padding = 'same'))
model.add(Conv2D(filters=64, kernel_size=(3,3), activation='relu', padding = 'same'))
model.add(Conv2D(filters=1, kernel_size=(1,1), activation='linear'))
# gives 3x3x1 output image which is prediction for yield on 3x3 square 

model.compile(loss='mean_squared_error', optimizer='adam', metrics=['mse'])
model.summary()

##### fit model
history = model.fit(train_generator, validation_data=val_generator, epochs=5, verbose=2)

##### plot mse
pyplot.plot(history.history['mse'])
pyplot.plot(history.history['val_mse'])
pyplot.title('MSE')
pyplot.ylabel('error')
pyplot.xlabel('epoch')
pyplot.legend(['train','test'],loc='upper left')
pyplot.show()
