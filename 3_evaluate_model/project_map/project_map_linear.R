##### The purpose of this script is to process remote sensing layers from the Hashem lab to create machine learning ready input files

##### contact Emily Bellis (ebellis@astate.edu) with questions
library(raster)
library(rgdal)
library(sf)
library(stringr)
library(ggplot2)
library(RColorBrewer)

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

## divide into training, testing and validation sets=
## Set B
e.train <- c(617769.6, 618159.6, 3828596, 3828776)
e.val <- c(617769.6,617964.6,3828776, 3828956)
e.test <- c(617964.6,618159.6,3828776, 3828956)

## process all other layers (downsample, crop, mask); make raster stacks for each day; split into test, train, and validation sets; split each of these into 5x5 pixel subimages and then save each image and channel separately as .csv file 
flydays <- c("04-11-2019","05-21-2019","06-13-2019","06-29-2019","07-11-2019","08-01-2019", "08-13-2019", "08-21-2019","08-28-2019","09-07-2019","09-13-2019") 
channels <- c("CIgreen.tif","GNDVI.tif","NAVI.tif","NDVI.tif","RENDVI.tif","TGI.tif","Thermal.tif")
path_to_raster <- "/Volumes/ABISSD/"

############################### output project for 1 day based on linear model
daystack <- create_daystack(path_to_raster, "08-01-2019", channels, yld.5dm) # raster stack for a single day
  
# mask so all have same number of NA's and number of images is same
mostnas_idx <- which.max(as.matrix(cellStats(daystack, stat='countNA')))
yld.dayna <- mask(yld.5dm, daystack[[mostnas_idx]])
daystack <- mask(daystack, daystack[[mostnas_idx]])

# predict 
r1_linear <- raster::predict(daystack, mod, progress = 'text')
pred <- raster('~/projectCNN_Aug01_v2.tif')

# plot
cuts=c(10, 150,160,170,180,190,200,250) 
cuts2=c(10, 154,166,178,187,194,250) #  quantile(yld.5dm, c(0.1, 0.25, 0.5, 0.75, 0.9))
cuts3 <- c(-100, -75, -50, -25, 0, 25, 50, 75, 100)

plot(yld.5dm, breaks = cuts2, col=brewer.pal(6, "RdYlBu"), main = "Observed Yield")
plot(pred, breaks = cuts2, col=brewer.pal(6, "YlGnBu"), main = "Predicted (2D-CNN)")
plot(r1_linear, breaks = cuts2, col=brewer.pal(6, "YlGnBu"), main = "Predicted (linear)")

cnn_diff <- yld.5dm - pred
lin_diff <- yld.5dm - r1_linear
cnn_lin <- pred - r1_linear

plot(cnn_diff, breaks = cuts3, col=brewer.pal(8, "RdYlBu"), main = "2D-CNN")
plot(lin_diff, breaks = cuts3, col=brewer.pal(8, "RdYlBu"), main = "linear")
plot(cnn_lin, breaks = cuts3, col=brewer.pal(8, "RdYlBu"), main = "linear")


buac_to_tha <- function(bushels) {
  return(bushels * 46 /  2204.62 * 2.47105)
}

