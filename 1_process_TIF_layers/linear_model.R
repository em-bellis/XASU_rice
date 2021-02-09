##### The purpose of this script is to process remote sensing layers from the Hashem lab to create machine learning ready input files

##### contact Emily Bellis (ebellis@astate.edu) with questions
library(raster)
library(rgdal)
library(sf)
library(stringr)
library(ggplot2)
library(tidyverse)

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
yld.5dm <- mask(yld.5d, crop_extent) 

## divide into training, testing and validation sets
## Set A
# e.train <- (c(617964.6,618159.6, 3828596, 3828956))
# e.val <- (c(617769.6,617964.6,3828596, 3828776))
# e.test <- (c(617769.6,617964.6,3828776, 3828956))

# ## Set B
# e.train <- c(617769.6, 618159.6, 3828596, 3828776)
# e.val <- c(617769.6,617964.6,3828776, 3828956)
# e.test <- c(617964.6,618159.6,3828776, 3828956)

# ## Set C
# e.train <- c(617769.6, 617964.6, 3828596, 3828956)
# e.val <- c(617964.6,618159.6,3828596, 3828776)
# e.test <- c(617964.6,618159.6,3828776, 3828956)

# ## Set D
e.val <- c(617964.6,618159.6,3828596, 3828776)
e.test <- (c(617769.6,617964.6,3828596, 3828776))
e.train <- c(617769.6, 618159.6, 3828776,3828956)

## process all other layers (downsample, crop, mask)
flydays <- c("04-11-2019","05-21-2019","06-29-2019","07-11-2019","08-01-2019", "08-13-2019", "08-21-2019","08-28-2019","09-07-2019","09-13-2019") 
channels <- c("CIgreen.tif","GNDVI.tif","NAVI.tif","NDVI.tif","RENDVI.tif","TGI.tif","Thermal.tif")
path_to_raster <- "/Volumes/ABISSD/"
vis.list <- str_replace(channels, '.tif', '')

############################### Output model performance by day
## set up dataframe
results <- data.frame(row.names = 1:length(flydays), Set = "B", Date = flydays, Train_MSE = "", Val_MSE = "", Test_MSE = "")

for (j in 1:length(flydays)) { 
  daystack <- create_daystack(path_to_raster, flydays[j], channels, yld.5dm)
  
  # mask so all have same number of NA's and number of images is same
  mostnas_idx <- which.max(as.matrix(cellStats(daystack, stat='countNA')))
  yld.dayna <- mask(yld.5dm, daystack[[mostnas_idx]])
  daystack <- mask(daystack, daystack[[mostnas_idx]])
  daystack <- stack(daystack, yld.dayna)
  
  # split into test, validation, training sets
  train <- crop(daystack, e.train)
  val <- crop(daystack, e.val)
  test <- crop(daystack, e.test)
  
  # create dataframe for each set
  train.df <- as.data.frame(na.omit(as.matrix(train))) # drop any rows with NA for any vegetation index
  test.df <- as.data.frame(na.omit(as.matrix(test)))
  val.df <- as.data.frame(na.omit(as.matrix(val)))

  # fit linear model
  mod <- lm(Yield ~ CIgreen + GNDVI + NAVI + NDVI + RENDVI + TGI + Thermal, data = train.df)
  
  # calculate MSE on training, test, and validation sets
  train.df$preds <- predict(mod, train.df)
  train.mse <- mean((train.df$Yield - train.df$preds)^2)
  results$Train_MSE[j] <- train.mse
  
  test.df$preds <- predict(mod, test.df)
  test.mse <- mean((test.df$Yield - test.df$preds)^2)
  results$Test_MSE[j] <- test.mse
  
  val.df$preds <- predict(mod, val.df)
  val.mse <- mean((val.df$Yield - val.df$preds)^2)
  results$Val_MSE[j] <- val.mse
  
  message(paste0("Done with ", flydays[j]))
}



