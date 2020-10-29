import numpy as np
import tensorflow.keras as keras
import random
import glob
from pandas import read_csv


class DataGenerator(keras.utils.Sequence):
    def __init__(self, path_to_labs, path_to_img, batch_size, type, days, channels, shuffle=True):
        'Initialization'
        self.path_to_img = path_to_img
        self.path_to_labs = path_to_labs
        self.batch_size = batch_size
        self.type = type
        self.file_list = glob.glob(self.path_to_labs + self.type + "/*.csv")
        self.num_files = len(self.file_list)
        self.days = days
        self.channels = channels
        self.idxs = list(range(0,self.num_files))
        self.labpaths = glob.glob(self.path_to_labs + self.type + "/*.csv")
        self.shuffle = shuffle
        super().__init__()
        self.on_epoch_end()  # This line must be last (after all initialization takes place)

    def __len__(self):
        'Denotes the number of batches per epoch'
        bpe = int(np.floor(len(self.idxs)/self.batch_size))
        return bpe

    def __getitem__(self, index):
        'Generate one batch of data'
        # Generate indexes of the batch
        bidxs = [i for i in range(index*self.batch_size, (index+1)*self.batch_size)]

        # Find list of IDs
        list_IDs_temp = [self.idxs[k] for k in bidxs]

        # Generate data
        X, y = self.data_generation(list_IDs_temp)
        return X, y

    def on_epoch_end(self):
        'Updates indexes after each epoch'
        self.idxs = np.arange(self.num_files)
        if self.shuffle is True:
            random.shuffle(self.idxs)

    def data_generation(self, list_IDs_temp):
        'Generates data containing batch_size samples'
        # Generate array of images
        X_vals = list()
        for sampidx in list_IDs_temp:
            tmp = self.load_samp(sampidx)
            X_vals.append(tmp)

        X_vals = np.stack(X_vals)

        # Generate labels
        y_vals=list()
        for sampidx in list_IDs_temp:
            yld = read_csv(self.labpaths[sampidx],header=0)
            y_vals.append(yld)

        y_vals = np.stack(y_vals)
        y_vals = np.reshape(y_vals,(self.batch_size,3,3,1))

        return X_vals, y_vals

    def load_samp(self, sampidx):
        'Load images into a a 4D array of pixels x pixels x timepoints x channels'
        chanstack = list()
        daystack = list()
        for channel in self.channels:
            # load each channel across all days separately
            daystack = self.load_channel(sampidx, channel)
            chanstack.append(daystack)
        chanstack = np.stack(chanstack, axis=-1)
        return chanstack

    def load_channel(self, sampidx, channel):
        'Load a channel across all days for a sample'
        chpaths = list()
        for day in self.days:
            # this next line needs to be changed for better generality
            chpath = glob.glob(self.path_to_img + day + "/" + self.type + "/" + channel + "*.csv")
            chpaths.append(chpath[sampidx])
        daystack = self.load_group(chpaths, '')
        return daystack

    def load_group(self, filenames, prefix):
        'Loads a list of files into a 3D array of pixels x pixels x features'
        loaded = list()
        for name in filenames:
            data = self.load_file(prefix + name)
            loaded.append(data)
        # stack group so that features are the 3rd dimension
        loaded = np.dstack(loaded)
        return loaded

    def load_file(self, filepath):
        'Loads a single file as a numpy array'
        dataframe = read_csv(filepath, header=0)
        return dataframe.values
