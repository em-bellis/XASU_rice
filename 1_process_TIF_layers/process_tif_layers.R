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
train <- crop(yld.5dm, e.train)

e.val <- (c(617769.6,617964.6,3828596, 3828776))
val <- crop(yld.5dm, e.val)

e.test <- (c(617769.6,617964.6,3828776, 3828956))
test <- crop(yld.5dm, e.test)

############################### Output yield 'labels'
# scan yield image and create sub-images of 5x5 pixels
sets <- c(test, train, val)
names(sets) <- c("test","train","val")

for (m in 1:3) {
	mat <- as.matrix(sets[[m]])
	output_labels(mat, path_to, names(sets)[[m]])
}

## process all other layers (downsample, crop, mask); make raster stacks for each day; split into test, train, and validation sets; split each of these into 3x3 pixel subimages and then save each image and channel separately as .csv file 
flydays <- c("04-11-2019","05-21-2019","06-13-2019","06-29-2019","07-11-2019","08-01-2019", "08-13-2019", "08-21-2019","08-28-2019","09-07-2019","09-13-2019") 
channels <- c("CIgreen.tif","GNDVI.tif","NAVI.tif","NDVI.tif","RENDVI.tif","TGI.tif","Thermal.tif")
path_to_raster <- "/Volumes/ABISSD/"
vis.list <- str_replace(channels, '.tif', '')

############################### Output images
for (j in 1:length(flydays)) {
  for (i in 1:length(channels)) { # downsample, crop, and make raster stack for each day
    curr <- raster(paste(path_to_raster,flydays[j],channels[i], sep = "/"))
    if (i<7) { 
      processed_rast <- process_VIs(vis.list[i], curr, yld.5dm, get_max_val(vis.list[i]),0)
    } else if (i==7) { 
      processed_rast <- process_VIs(vis.list[i], curr, yld.5dm, 60,-400)
    }
    
    # something going on w/Thermal on 6-13-19, seems to be relative to Kelvin?
    if (maxValue(processed_rast) < (-200) && i==7) {
      warning(paste('Adding 300 to thermal for ', flydays[j]))
      processed_rast <- processed_rast + 300 # something going on w/Thermal on 6-13 seem to be relative to Kelvin?
    }
    
    if(i == 1){
      daystack <- processed_rast
    } else {
      daystack <- stack(daystack, processed_rast)
    }
  }
  plot(daystack) # stack of channel data for one day
  
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
		  dir.create(paste(path_to,"images/",flydays[j],"/",names(sets)[[m]], sep=""), recursive=T)
	
		  k <- 1 #k is a unique id for each subimage
		  for (r in seq(1,(dim(mat)[1]-4),5)) {
			  for (c in seq(1,(dim(mat)[1]-4),5)) {
				  subimg <- round(mat[r:(r+4),c:(c+4)],digits=2)
				  file_id <- paste(names(sets[[m]][[i]]),k,".csv", sep="")
		
				  if (is.na(mean(subimg)) == "FALSE") {
					  write.table(subimg, file=paste(path_to,"images/",flydays[j],"/",names(sets)[[m]],"/",file_id,sep=""), quote=F, sep=",", row.names=F, col.names=F)
				  }
		
				  k <- k+1
			  }
		  }		
	  }
 }
}

