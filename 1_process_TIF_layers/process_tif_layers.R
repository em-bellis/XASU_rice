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
# Set A
e.train <- (c(617964.6,618159.6, 3828596, 3828956))
e.val <- (c(617769.6,617964.6,3828596, 3828776))
e.test <- (c(617769.6,617964.6,3828776, 3828956))

## process all other layers (downsample, crop, mask); make raster stacks for each day; split into test, train, and validation sets; split each of these into 5x5 pixel subimages and then save each image and channel separately as .csv file 
flydays <- c("04-11-2019","05-21-2019","06-13-2019","06-29-2019","07-11-2019","08-01-2019", "08-13-2019", "08-21-2019","08-28-2019","09-07-2019","09-13-2019") 
channels <- c("CIgreen.tif","GNDVI.tif","NAVI.tif","NDVI.tif","RENDVI.tif","TGI.tif","Thermal.tif")
path_to_raster <- "/Volumes/ABISSD/"
vis.list <- str_replace(channels, '.tif', '')

############################### Output images and labels by day
#for (j in 1:length(flydays)) { 
for (j in 1:1) { 
  daystack <- create_daystack(path_to_raster, flydays[j], channels, yld.5dm)
  
  # mask so all have same number of NA's and number of images is same
  mostnas_idx <- which.max(as.matrix(cellStats(daystack, stat='countNA')))
  yld.dayna <- mask(yld.5dm, daystack[[mostnas_idx]])
  daystack <- mask(daystack, daystack[[mostnas_idx]])
  
  ## split into test, validation, training sets
  train <- crop(daystack, e.train)
  val <- crop(daystack, e.val)
  test <- crop(daystack, e.test)
  
  sets <- c(test, train, val)
  names(sets) <- c("test","train","val")
  
  ## create and save 5x5 pixel images for one day
  for (m in 1:3) { #m iterating over datasets
  	for (i in 1:length(channels)) { #i iterating over channels
    	mat <- as.matrix(sets[[m]][[i]])
    	path_to_imgs <- paste(path_to,"images/",flydays[j],"/",names(sets)[[m]], sep="")
		  dir.create(path_to_imgs, recursive=T)
	
		  output_images(mat, path_to_imgs,names(sets[[m]][[i]]))
	  }
  }
  
  ## create and save 5x5 pixel labels for one day
  test <- crop(yld.dayna, e.test)
  train <- crop(yld.dayna, e.train)
  val <- crop(yld.dayna, e.val)
  
  sets <- c(test, train, val)
  names(sets) <- c("test","train","val")
  
  for (m in 1:3) { #m iterating over datasets
    mat <- as.matrix(sets[[m]])
    path_to_labs <- paste(path_to,"labels/",flydays[j],"/",names(sets)[[m]], sep="")
      
    output_labels(mat, path_to_labs)
  }
  message(paste0("Done with ", flydays[j]))
}


