##### The purpose of this script is to process remote sensing layers from the Hashem lab to create machine learning ready input files

##### contact Emily Bellis (ebellis@astate.edu) with questions
library(raster)
library(rgdal)
library(sf)
library(stringr)
library(ggplot2)

setwd('~/Documents/GitHub/XASU_rice/1_process_TIF_layers/')
source('~/Documents/GitHub/XASU_rice/1_process_TIF_layers/get_max_val.R')
source('~/Documents/GitHub/XASU_rice/1_process_TIF_layers/process_VIs.R')
source('~/Documents/GitHub/XASU_rice/1_process_TIF_layers/output_labels.R')
source('~/Documents/GitHub/XASU_rice/1_process_TIF_layers/create_daystack.R')
source('~/Documents/GitHub/XASU_rice/1_process_TIF_layers/output_images.R')

path_to <- "/Volumes/ABISSD/"

## get yield data layer, downsample, mask; base all other layers on this layer
yld <- raster(paste0(path_to,'Yield.tif')) # utm, 5 cm resolution
yld.5 <- aggregate(yld, 10) # 0.5 x 0.5 m resolution
crop_extent <- readOGR(paste0(path_to,"04-11-2019/Carr_N_Without_Ditch.shp"))
yld.5d <- crop(yld.5, crop_extent)
yld.5dm <- mask(yld.5d, crop_extent) # 5616 cells; 5235 of these are non-NA

## divide into training, testing and validation sets
## Set A
#e.test <- (c(617769.6,617964.6,3828776, 3828956))

# ## Set B
#e.test <- c(617964.6,618159.6,3828776, 3828956)

## Set C
#e.test <- c(617964.6,618159.6,3828596, 3828776) #corrected (bottom right)


## Set D
e.test <- (c(617769.6,617964.6,3828596, 3828776))

## process all other layers (downsample, crop, mask); make raster stacks for each day; split into test, train, and validation sets; split each of these into 5x5 pixel subimages and then save each image and channel separately as .csv file 
flydays <- c("04-11-2019","05-21-2019","06-13-2019","06-29-2019","07-11-2019","08-01-2019", "08-13-2019", "08-21-2019","08-28-2019","09-07-2019","09-13-2019") 
channels <- c("CIgreen.tif","GNDVI.tif","NAVI.tif","NDVI.tif","RENDVI.tif","TGI.tif","Thermal.tif")
path_to_raster <- "/Volumes/ABISSD/"
vis.list <- str_replace(channels, '.tif', '')

############################### Output images and labels by day
for (j in 6:6) { 
  daystack <- create_daystack(path_to_raster, flydays[j], channels, yld.5dm)
  
  # mask so all have same number of NA's and number of images is same
  mostnas_idx <- which.max(as.matrix(cellStats(daystack, stat='countNA')))
  yld.dayna <- mask(yld.5dm, daystack[[mostnas_idx]])
  daystack <- mask(daystack, daystack[[mostnas_idx]])
  
  ## split into test, validation, training sets
  test <- crop(daystack, e.test)
  
  ## create and save 5x5 pixel images for one day
  for (i in 1:length(channels)) { #i iterating over channels
    mat <- as.matrix(test[[i]])
    path_to_imgs <- paste(path_to,"SetD_blank/images/",flydays[j],"/test/blanks/", sep="")
		dir.create(path_to_imgs, recursive=T)
		output_images_blank(mat, path_to_imgs,names(test[[i]]))
	  }

  message(paste0("Done with ", flydays[j]))
}



