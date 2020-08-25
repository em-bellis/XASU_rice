#!/usr/bin/env python 

import glob
import numpy as np

def file_mse(preds_file):
    preds = np.load(preds_file)
    labpaths = glob.glob("/Volumes/ExtremeSSD/Data/Humnoke/Carr_North/infiles_for_2DCNN/labels/test/*.csv")
 
    sse=0
    for sampidx in range(0,1056):
        yld =np.array(read_csv(labpaths[sampidx],header=0))
        yld = np.reshape(yld,(3,3,1))
        sqerr = np.square(b32[sampidx] - yld)
        sse = sse + np.sum(sqerr)

    return(sse/(1056*9))


