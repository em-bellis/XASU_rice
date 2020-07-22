##### The purpose of this script is to process remote sensing layers from the Hashem lab to create machine learning ready input files
##### It is highly recommended to be consistent with file names for each of the indices as below 
##### All layers must eventually have the same resolution, extent, and crs; the number of pixels in each layer must also be the same at the end of this process 
##### contact Emily Bellis (ebellis@astate.edu) with questions

library(raster)
library(rgdal)
library(sf)
library(stringr)
library(ggplot2)

path_to <- "/Volumes/Extreme SSD/Data/Humnoke/Carr_North"

## get yield data layer, downsample, mask; base all other layers on this layer
yld <- raster('/Volumes/Extreme SSD/Data/Yield.tif') # utm, 5 cm resolution
yld.5 <- aggregate(yld, 100) # 5 x 5 m resolution
crop_extent <- readOGR(paste(path_to, "04-11-2019/Carr_N_Without_Ditch.shp", sep="/"))
yld.5d <- crop(yld.5, crop_extent)
yld.5dm <- mask(yld.5d, crop_extent) # 5616 cells; 5235 of these are non-NA

## save yield dataframe
yld.df <- as.data.frame(yld.5dm)
goodrows <- which(!is.na(yld.df))
warnval <- length(goodrows)
yld.flt <- yld.df[goodrows,]
#write.table(yld.flt, file=paste(path_to,"/yld.csv",sep=""), quote=F, sep=",", row.names=F)

## process all other layers (downsample, crop, mask); make raster stacks for each day and then save as .csv file 
flydays <- c("04-11-2019","05-21-2019","06-13-2019","06-29-2019","07-11-2019","08-01-2019", "08-13-2019", "08-21-2019","08-28-2019","09-07-2019","09-13-2019") 
channels <- c("CIgreen.tif","GNDVI.tif","NAVI.tif","NDVI.tif","RENDVI.tif","TGI.tif","Thermal.tif")

for (j in 1:length(flydays)) {
  for (i in 1:length(channels)) {
    curr <- raster(paste(path_to,flydays[j],channels[i], sep = "/"))
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
  
  # check NAs
  rNA <- sum(!is.na(daystack))
  #plot(rNA, main=paste("NAs on ", flydays[j]))
  print(flydays[j])
  print(freq(rNA))

  # create and save dataframe 
  tmp <-as.data.frame(daystack)
  tmp2 <- tmp[goodrows,]
  if(nrow(tmp2) != warnval)stop('Wrong number of pixels in dataframe!')
  nam <- paste(path_to,"/", "layers",str_remove_all(flydays[j], "-"),".csv",sep="") #r seems to have some issues with variable names that have a '-'; remove with str_remove_all function  
  #write.table(tmp2, file=nam, quote=F, sep=",", row.names=F)
}

## check distribution of variables 
fly <- read.csv(paste(path_to,"/layers",str_remove_all(flydays[1], "-"), ".csv",sep=""))

for (i in 2:length(flydays)) {
  fly2 <- read.csv(paste(path_to,"/layers",str_remove_all(flydays[i], "-"), ".csv",sep=""))
  fly <- rbind.data.frame(fly, fly2)
}

for (i in 1:length(fly)){
  ggplot(fly, aes(x=fly[,i])) + geom_histogram() + xlab(colnames(fly[i]))
}

