#!/usr/bin/env python 

import glob
import numpy as np
from pandas import read_csv

###### function to get MSE
def file_mse(preds_file):
    preds = np.load(preds_file)
    labpaths = glob.glob("/Volumes/ExtremeSSD/Data/Humnoke/Carr_North/infiles_for_2DCNN/labels/test/*.csv") 
    sse=0
    for sampidx in range(0,1056):
        yld =np.array(read_csv(labpaths[sampidx],header=0))
        yld = np.reshape(yld,(3,3,1))
        sqerr = np.square(preds[sampidx] - yld)
        sse = sse + np.sum(sqerr)
    return(sse/(1056*9))


###### plot MSE for all the blank one data
vals = np.zeros(11)
pred_files = glob.glob("/Volumes/ExtremeSSD/Preds/blank_one_out/*_3Db64.npy")

for i in range(0,11):
    vals[i] = file_mse(pred_files[i])

df = np.concatenate((pred_files, vals),axis=0).reshape(2,11)
np.array(df)
np.savetxt('blank_one_3Db64.txt', df, fmt='%s')