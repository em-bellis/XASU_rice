##### Update 6.12.20: rework to output 3x3 images for yield instead of a single value
##### Update 5.27.20: rework to output 3x3 images instead of csv of individual pixels

##### The purpose of this script is to process remote sensing layers from the Hashem lab to create machine learning ready input files
##### It is highly recommended to be consistent with file names for each of the indices as below 
##### All layers must eventually have the same resolution, extent, and crs; the number of pixels in each layer must also be the same at the end of this process 
##### contact Emily Bellis (ebellis@astate.edu) with questions

library(raster)
library(rgdal)
library(sf)
library(stringr)
library(ggplot2)

path_to <- "/Volumes/ExtremeSSD/Data/Humnoke/Carr_North/infiles_for_2DCNN/"

## get yield data layer, downsample, mask; base all other layers on this layer
yld <- raster('/Volumes/ExtremeSSD/Data/Yield.tif') # utm, 5 cm resolution
yld.5 <- aggregate(yld, 100) # 5 x 5 m resolution
crop_extent <- readOGR(paste("/Volumes/ExtremeSSD/Data/Humnoke/Carr_North/04-11-2019/Carr_N_Without_Ditch.shp", sep="/"))
yld.5d <- crop(yld.5, crop_extent)
yld.5dm <- mask(yld.5d, crop_extent) # 5616 cells; 5235 of these are non-NA

## divide into training, testing and validation sets  
e.train <- (c(617964.6,618159.6, 3828596, 3828956))
train <- crop(yld.5dm, e.train)

e.val <- (c(617769.6,617964.6,3828596, 3828776))
val <- crop(yld.5dm, e.val)

e.test <- (c(617769.6,617964.6,3828776, 3828956))
test <- crop(yld.5dm, e.test)

## scan yield image and create subsets of 3x3 pixels. For each of these, output a label that is the average of all 9 cells
sets <- c(test, train, val)
names(sets) <- c("test","train","val")

for (m in 1:3) {
	mat <- as.matrix(sets[[m]])

	i <- 1
	for (r in 1:(dim(mat)[1]-2)) {
		for (c in 1:(dim(mat)[2]-2)){
			avg <- round(mean(mat[r:(r+2),c:(c+2)]), digits=1)
			file_id <- paste("yld",i,".csv", sep="")
			subimg <- round(mat[r:(r+2),c:(c+2)],2)
		
			if (is.na(avg) == "FALSE") {
				write.table(subimg, file=paste(path_to,"labels/",names(sets)[[m]],"/",file_id,sep=""), quote=F, sep=",", row.names=F)
			}
		
			i <- i+1
		}
	}
}

## process all other layers (downsample, crop, mask); make raster stacks for each day; split into test, train, and validation sets; split each of these into 3x3 pixel subimages and then save each image and channel separately as .csv file 

flydays <- c("04-11-2019","05-21-2019","06-13-2019","06-29-2019","07-11-2019","08-01-2019", "08-13-2019", "08-21-2019","08-28-2019","09-07-2019","09-13-2019") 
channels <- c("CIgreen.tif","GNDVI.tif","NAVI.tif","NDVI.tif","RENDVI.tif","TGI.tif","Thermal.tif")
path_to_raster <- "/Volumes/ExtremeSSD/Data/Humnoke/Carr_North/"

for (j in 1:length(flydays)) {
  for (i in 1:length(channels)) { # downsample, crop, and make raster stack for each day
    curr <- raster(paste(path_to_raster,flydays[j],channels[i], sep = "/"))
    curr.rp <- projectRaster(curr, yld.5dm)
    curr.rpm <- mask(curr.rp, yld.5dm)
    
    # something going on w/Thermal on 6-13-19, seems to be relative to Kelvin?
    if (maxValue(curr.rpm) < (-200) && i==7) {
      warning(paste('Adding 300 to thermal for ', flydays[j]))
      curr.rpm <- curr.rpm + 300 # something going on w/Thermal on 6-13 seem to be relative to Kelvin?
    }
    
    if(i == 1){
      daystack <- curr.rpm
    } else {
      daystack <- stack(daystack, curr.rpm)
    }
  }
  plot(daystack)
  
  ## split into test, validation, training sets
  train <- crop(daystack, e.train)
  val <- crop(daystack, e.val)
  test <- crop(daystack, e.test)
  
  sets <- c(test, train, val)
  names(sets) <- c("test","train","val")
  
  ## create and save 3x3 pixel images 
  for (m in 1:3) { #m iterating over datasets
  	for (i in 1:length(channels)) { #i iterating over channels
    	mat <- as.matrix(sets[[m]][[i]])
		dir.create(paste(path_to,"images/",flydays[j],"/",names(sets)[[m]], sep=""), recursive=T)
	
		k <- 1 #k is a unique id for each subimage
		for (r in 1:(dim(mat)[1]-2)) {
			for (c in 1:(dim(mat)[2]-2)){
				subimg <- mat[r:(r+2),c:(c+2)]
				file_id <- paste(names(sets[[m]][[i]]),k,".csv", sep="")
		
				if (is.na(mean(subimg)) == "FALSE") {
					write.table(subimg, file=paste(path_to,"images/",flydays[j],"/",names(sets)[[m]],"/",file_id,sep=""), quote=F, sep=",", row.names=F)
				}
		
				k <- k+1
			}
		}		
	}
  }
}

