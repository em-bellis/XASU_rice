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
        self.days = days
        self.file_list_imgs = glob.glob(self.path_to_img + "arrays/" + self.type + "/*.npy")
        self.file_list_imgs.sort()
        self.channels = channels
        self.num_files = len(self.file_list_imgs) - 1
        self.idxs = list(range(0,self.num_files))
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
        list_IDs_temp = [self.idxs[k] for k in bidxs] # these are the indices from the original, unshuffled list

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
            tmp = np.load(self.file_list_imgs[sampidx])
            X_vals.append(tmp)

        X_vals = np.stack(X_vals)

        # Generate labels
        y_vals=list()
        for sampidx in list_IDs_temp:
            sampname = self.file_list_imgs[sampidx].split('/')[-1].replace('npy','csv').replace('img','yld')
            labpath = f'{self.path_to_labs}{self.days[0]}/{self.type}/{sampname}'
            yld = read_csv(labpath,header=None)
            y_vals.append(yld)

        y_vals = np.stack(y_vals)
        y_vals = np.reshape(y_vals,(self.batch_size,5,5,1))

        return X_vals, y_vals
