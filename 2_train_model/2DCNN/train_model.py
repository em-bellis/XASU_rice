#!/usr/bin/env python
import tensorflow as tf
import numpy as np 
import pandas as pd 
import tensorflow.keras as keras
from tensorflow.keras import Sequential
from tensorflow.keras.layers import Dense, Flatten, Dropout, Reshape
from tensorflow.keras.layers import Conv2D, Conv3D, MaxPooling3D
from tensorflow.keras.optimizers import SGD
from my_classes import DataGenerator 

###### global variables for dataset  
channels = ["CIgreen","GNDVI", "NAVI","NDVI","RENDVI","TGI","Thermal"] #should match filenames e.g. 
#days = ["04-11-2019","05-21-2019","06-13-2019","06-29-2019","07-11-2019","08-01-2019","08-13-2019","08-21-2019","08-28-2019","09-07-2019","09-13-2019"]
days = ["06-29-2019","07-11-2019","08-01-2019","08-13-2019","08-21-2019"]
path_to_labs = "/storage/ebellis/SetA/labels/"
path_to_img = "/storage/ebellis/SetA/images/"

###### use data generator to generate training and validation data samples in each batch    
batch_size_train = 32
batch_size_val = 32
day = days[2]
print('Training 2DCNN model for ', day)

train_generator = DataGenerator(path_to_labs, path_to_img, batch_size_train, 'train', day, channels)
val_generator = DataGenerator(path_to_labs, path_to_img, batch_size_val, 'val', day, channels)

###### define CNN architecture 
model = Sequential()
model.add(Conv2D(filters=64, kernel_size=(3,3), padding="same", activation='relu', input_shape=(5,5,7))) # 5x5 images with 7 channels (veg. indices)
model.add(Conv2D(filters=128, kernel_size=(2,2), padding="same", activation='relu'))
model.add(Conv2D(filters=256, kernel_size=(1,1), padding="valid", activation='relu'))
model.add(Reshape((5,5,256)))
model.add(Flatten())
model.add(Dense(256, activation='relu')) # or 512
model.add(Dense(6400))
        
# deconvolution steps
model.add(Reshape((5,5,256)))
model.add(Conv2D(filters=128, kernel_size=(2,2), activation='relu', padding = 'same'))
model.add(Conv2D(filters=64, kernel_size=(3,3), activation='relu', padding = 'same'))
model.add(Conv2D(filters=1, kernel_size=(1,1), activation='linear'))
# gives 5x5x1 output image which is prediction for yield on 5x5 square 

model.compile(loss='mean_squared_error', optimizer='adam', metrics=['mse'])

# model = tf.keras.models.load_model('models')

EPOCHS = 50
checkpoint_filepath = 'models/'
model_checkpoint_callback = tf.keras.callbacks.ModelCheckpoint(
    filepath=checkpoint_filepath,
    save_weights_only=False,
    monitor='val_mse',
    mode='min',
    save_best_only=True)

##### fit model
model.fit(train_generator, validation_data=val_generator, epochs=EPOCHS, verbose=2, callbacks=[model_checkpoint_callback])
