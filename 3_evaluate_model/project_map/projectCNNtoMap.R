# This code will project a map of yield projections using model weights trained from a 2DCNN

## process input image (downsample, mask many of the NA's, create raster stack)
library(raster)
library(rgdal)
library(sf)
library(stringr)
library(ggplot2)
library(reticulate)

setwd("/home/ebellis/rice/project")
source('get_max_val.R')
source('process_VIs.R')
source('output_labels.R')
source('create_daystack.R')
source('output_images.R')

path_to <- "/storage/ebellis/tifs/"

## get yield data layer, downsample, mask; base all other layers on this layer
yld <- raster(paste0(path_to,'Yield.tif')) # utm, 5 cm resolution
yld.5 <- aggregate(yld, 10) # 0.5 x 0.5 m resolution
crop_extent <- readOGR(paste0(path_to,"04-11-2019/Carr_N_Without_Ditch.shp"))
yld.5d <- crop(yld.5, crop_extent)
yld.5dm <- mask(yld.5d, crop_extent) # 5616 cells; 5235 of these are non-NA

## process all other layers (downsample, crop, mask); make raster stacks for each day; split into test, train, and validation sets; split each of these into 5x5 pixel subimages and then save each image and channel separately as .csv file 
flydays <- c("04-11-2019","05-21-2019","06-13-2019","06-29-2019","07-11-2019","08-01-2019", "08-13-2019", "08-21-2019","08-28-2019","09-07-2019","09-13-2019") 
channels <- c("CIgreen.tif","GNDVI.tif","NAVI.tif","NDVI.tif","RENDVI.tif","TGI.tif","Thermal.tif")

j = 6 # just looking at Aug 01
daystack <- create_daystack(path_to, flydays[j], channels, yld.5dm) # raster stack for a single day

# mask so all have same number of NA's and number of images is same
mostnas_idx <- which.max(as.matrix(cellStats(daystack, stat='countNA')))
yld.dayna <- mask(yld.5dm, daystack[[mostnas_idx]])
daystack <- mask(daystack, daystack[[mostnas_idx]])

# create a new raster layer with extent of the yield layer, fill with NA's
pred_yld <- yld.5dm
values(pred_yld) <- NA
pred_yld

## stuff for python
use_condaenv("rice_21", required = T)
np <- import("numpy")
sys <- import("sys")

library(tensorflow)
library(keras)
library(tfestimators)

# load model
augmod <- load_model_tf('Aug01_SetB_model/', custom_objects = NULL, compile = TRUE)

# a function that will take as input a 5x5 pixel region of predictors, and output yield, saving it in the prediction layer
projectModel <- function(r, c) {
  tmp <- as.array(crop(daystack, extent(daystack, r,(r+4),c,(c+4)))) # get a 5x5x7 array
  tmp <- round(tmp,2) # just keep 2 decimal places
  if (is.na(mean(tmp)) == "FALSE") {
    patch <- matrix(predict(augmod, np$expand_dims(tmp, 0L)) %>% np$squeeze(), nrow = 5, byrow=T) # patch of raster with predictions
  } else {
    patch <- tmp[1:5,1:5,1]
  }
  return(patch)
}

# starting at first indec
for (r in seq(1,(dim(pred_yld)[1]-4),5)) {
  for (c in seq(1,(dim(pred_yld)[2]-4),5)) {
    pred_yld[r:(r+4), c:(c+4)] <- projectModel(r,c)
  }
}

writeRaster(pred_yld, "projectCNN_Aug01.tif",format="GTiff")

