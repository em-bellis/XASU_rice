import numpy as np
import glob
from pandas import read_csv

# set 'static' variables

# functions to create 5x5x5x7 npy array (pixels x pixels x timepoints x channels)
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
    for day in days:
        # this next line needs to be changed for better generality
        chpath = f'{path_to_img}{day}/{type}/{channel}{sampname}'
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

# set 'static' variables
channels = ["CIgreen","GNDVI", "NAVI","NDVI","RENDVI","TGI","Thermal"] #should match filenames e.g. 
days = ["06-29-2019","07-11-2019","08-01-2019","08-13-2019","08-21-2019"]
path_to_labs = "/storage/ebellis/SetA/labels/"
path_to_img = "/storage/ebellis/SetA/images/"
type = "test"

# save numpy array
sample_list = read_csv(type + '_list', header=None) # only include subimages that have data for all five days
sample_fps = path_to_labs + days[0] + "/" + type + "/" + sample_list
file_list = sample_fps[0].tolist()
file_list.sort()

num_files = len(file_list) - 1
idxs = list(range(0,num_files))

for sampidx in idxs: 
    newname = file_list[sampidx].split("/")[-1].replace('yld','img').replace('.csv','')
    sampname = newname.replace('img','') + ".csv"
    tmp = load_samp(sampname)
    np.save(path_to_img + "arrays/" + type + "/" + newname, tmp)

