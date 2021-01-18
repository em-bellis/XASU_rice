import numpy as np
import os
import glob
import sys, getopt
from pandas import read_csv

####### this script processes .csv files into .npy format to speed up training and testing
####### Requires: a list named ‘val_list’,‘train_list’, or 'test_list' listing one image label per line (e.g. ‘yld10000.csv’) to be in working directory.
####### usage: python process_to_npy_2DCNN.py 1 val; where the first argument is the index of the 'day' to process and the second is the type of dataset

days = ["06-29-2019","07-11-2019","08-01-2019","08-13-2019","08-21-2019"]

daysidx = int(sys.argv[1])
print('Day index is ', daysidx, '; day is ', days[daysidx])
type = str(sys.argv[2])
print ('Type is ', type)

# set 'static' variables
channels = ["CIgreen","GNDVI", "NAVI","NDVI","RENDVI","TGI","Thermal"] #should match filenames e.g. 
path_to_labs = "/storage/ebellis/SetA/labels/"
path_to_img = "/storage/ebellis/SetA/images/"

# functions to create 5x5x1x7 npy array (pixels x pixels x day x channels)
def load_file(filepath):
    'Loads a single file as a numpy array'
    dataframe = read_csv(filepath, header=None)
    return dataframe.values

def load_group(filenames, prefix):
    'Loads a list of files into a 3D array of pixels x pixels x features'
    loaded = list()
    for name in filenames:
        data = load_file(prefix + name)
        loaded.append(data)
    # stack group so that features are the 3rd dimension
    loaded = np.dstack(loaded)
    return loaded

def load_channel(channel, sampname):
    'Load a channel across all days for a sample'
    chpaths = list()
    chpath = f'{path_to_img}{days[daysidx]}/{type}/{channel}{sampname}'
    chpaths.append(chpath)
    daystack = load_group(chpaths, '')
    return daystack

def load_samp(sampname):
    'Load images into a a 4D array of pixels x pixels x timepoints x channels'
    chanstack = list()
    daystack = list()
    for channel in channels:
        # load each channel across all days separately
        daystack = load_channel(channel, sampname)
        chanstack.append(daystack)
    chanstack = np.stack(chanstack, axis=-1)
    return chanstack

# save numpy array
sample_list = read_csv(type + '_list', header=None) # only include subimages that have data for all five days
sample_fps = path_to_labs + days[0] + "/" + type + "/" + sample_list # use labels from first day is ok for all
file_list = sample_fps[0].tolist()
file_list.sort()

num_files = len(file_list) - 1
idxs = list(range(0,num_files))

# make directory to save if it does not exist
if not os.path.exists(path_to_img + days[daysidx] + "/" + type + "/arrays/"):
    os.makedirs(path_to_img + days[daysidx] + "/" + type + "/arrays/")

for sampidx in idxs: 
    newname = file_list[sampidx].split("/")[-1].replace('yld','img').replace('.csv','')
    sampname = newname.replace('img','') + ".csv"
    tmp = load_samp(sampname)
    np.save(path_to_img + days[daysidx] + "/" + type + "/arrays/" + newname, tmp)