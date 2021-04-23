##### The purpose of this script is to process remote sensing layers from the Hashem lab to create machine learning ready input files

##### contact Emily Bellis (ebellis@astate.edu) with questions
library(raster)
library(rgdal)
library(sf)
library(stringr)
library(ggplot2)
library(RColorBrewer)
library(xgboost)

setwd('~/Documents/GitHub/XASU_rice/1_process_TIF_layers/')
source('~/Documents/GitHub/XASU_rice/1_process_TIF_layers/get_max_val.R')
source('~/Documents/GitHub/XASU_rice/1_process_TIF_layers/process_VIs.R')
source('~/Documents/GitHub/XASU_rice/1_process_TIF_layers/output_labels.R')
source('~/Documents/GitHub/XASU_rice/1_process_TIF_layers/create_daystack.R')
source('~/Documents/GitHub/XASU_rice/1_process_TIF_layers/output_images.R')

path_to <- "/Volumes/ABISSD/"

# function to convert yield units
buac_to_Mgha <- function(bushels) {
  return(bushels * 46 /  2204.62 * 2.47105)
}

# function to calculate RMSE
rmse <- function(observed, predicted) {
  root_mean_square_error <- sqrt(mean((observed - predicted)^2))
  return(root_mean_square_error)
}

# function to calculate R^2
r2 <- function(observed, predicted) {
  mod <- lm(predicted ~ observed)
  return(summary(mod)[8])
}

# function to calculate MBE
mbe <- function(observed, predicted) {
  mean_bias <- mean(predicted - observed)
  return(mean_bias)
}

mae <- function(observed, predicted) {
  mean_error <- mean(abs(observed - predicted))
  return(mean_error)
}

## get yield data layer, downsample, mask; base all other layers on this layer
yld <- raster(paste0(path_to,'Yield.tif')) # utm, 5 cm resolution
yld.5 <- aggregate(yld, 10) # 0.5 x 0.5 m resolution
crop_extent <- readOGR(paste0(path_to,"04-11-2019/Carr_N_Without_Ditch.shp"))
yld.5d <- crop(yld.5, crop_extent)
yld.5dm <- mask(yld.5d, crop_extent) # 5616 cells; 5235 of these are non-NA

Set <- 'A'

## divide into training, testing and validation sets=
## Set A
if (Set == 'A') {
  e.train <- (c(617964.6,618159.6, 3828596, 3828956))
  e.val <- (c(617769.6,617964.6,3828596, 3828776))
  e.test <- (c(617769.6,617964.6,3828776, 3828956))
} else if (Set == "B") {
## Set B
  e.train <- c(617769.6, 618159.6, 3828596, 3828776)
  e.val <- c(617769.6,617964.6,3828776, 3828956)
  e.test <- c(617964.6,618159.6,3828776, 3828956)
} else if (Set == "C") {
## Set C
 e.train <- c(617769.6, 617964.6, 3828596, 3828956)
 e.val <- c(617964.6,618159.6,3828596, 3828776)
 e.test <- c(617964.6,618159.6,3828776, 3828956)
} else if (Set == "D") {
## Set D
 e.val <- c(617964.6,618159.6,3828596, 3828776)
 e.test <- (c(617769.6,617964.6,3828596, 3828776))
 e.train <- c(617769.6, 618159.6, 3828776,3828956)
}

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
daystack_yld <- stack(daystack, yld.dayna)

preds_cnn <- raster(paste0('~/projectCNN_Aug01_Set',Set,'.tif'))
preds_cnn <- extend(preds_cnn, 20)
preds_cnn <- crop(preds_cnn, extent(daystack_yld))
preds_cnn <- mask(preds_cnn, daystack[[mostnas_idx]])
names(preds_cnn) <- 'preds_2d'
daystack_yld <- stack(daystack_yld, preds_cnn)

# split into test, validation, training sets
train_yld <- crop(daystack_yld, e.train)
test_yld <- crop(daystack_yld, e.test)

# create a data frame for each set 
train.df <- as.data.frame(na.omit(as.matrix(train_yld))) # drop any rows with NA for any vegetation index
test.df <- as.data.frame(na.omit(as.matrix(test_yld)))

test.df$Yield_Mgha <- buac_to_Mgha(test.df$Yield)

# add a column for predictions for each model
mod.lin = lm(Yield ~ CIgreen + GNDVI + NAVI + NDVI + RENDVI + TGI + Thermal, data = train.df)
test.df$preds_lin <- buac_to_Mgha(predict(mod.lin, test.df))

mod.null = mean(train.df$Yield)
test.df$preds_null <- buac_to_Mgha(mod.null)

test.df$preds_2d <- buac_to_Mgha(test.df$preds_2d)

## xgboost model (did not save, so retrain)
dtrain <- xgb.DMatrix(data = as.matrix(train.df[,c(1:7)]), label = as.matrix(train.df[,8]))
dtest <- xgb.DMatrix(data = as.matrix(test.df[,c(1:7)]), label = as.matrix(test.df[,8]))
rownames(dtest) <- NULL
bst <- xgboost(data = dtrain, nrounds=200, max.depth=2, verbose=2, eta = 0.2)
test.df$preds_xgb = buac_to_Mgha(predict(bst, dtest))

# calculate metrics
# rmse
rmse(test.df$Yield_Mgha, test.df$preds_2d)
rmse(test.df$Yield_Mgha, test.df$preds_xgb)
rmse(test.df$Yield_Mgha, test.df$preds_lin)
rmse(test.df$Yield_Mgha, test.df$preds_null)

#r2
r2(test.df$Yield_Mgha, test.df$preds_2d)
r2(test.df$Yield_Mgha, test.df$preds_xgb)
r2(test.df$Yield_Mgha, test.df$preds_lin)
r2(test.df$Yield_Mgha, test.df$preds_null)

#mbe
mbe(test.df$Yield_Mgha, test.df$preds_2d)
mbe(test.df$Yield_Mgha, test.df$preds_xgb)
mbe(test.df$Yield_Mgha, test.df$preds_lin)
mbe(test.df$Yield_Mgha, test.df$preds_null)

#mae
mae(test.df$Yield_Mgha, test.df$preds_2d)
mae(test.df$Yield_Mgha, test.df$preds_xgb)
mae(test.df$Yield_Mgha, test.df$preds_lin)
mae(test.df$Yield_Mgha, test.df$preds_null)



####### 3dcnn is calculated based on predictions output from model.predict run on cluster
setA <- read.csv('preds_3dcnn_SetA.csv')
setB <- read.csv('preds_3dcnn_SetB.csv')
setC <- read.csv('preds_3dcnn_SetC.csv')
setD <- read.csv('preds_3dcnn_SetD.csv')

#mae
mae(buac_to_Mgha(setA$observed), buac_to_Mgha(setA$predicted))
mae(buac_to_Mgha(setB$observed), buac_to_Mgha(setB$predicted))
mae(buac_to_Mgha(setC$observed), buac_to_Mgha(setC$predicted))
mae(buac_to_Mgha(setD$observed), buac_to_Mgha(setD$predicted))

#mbe
mbe(buac_to_Mgha(setA$observed), buac_to_Mgha(setA$predicted))
mbe(buac_to_Mgha(setB$observed), buac_to_Mgha(setB$predicted))
mbe(buac_to_Mgha(setC$observed), buac_to_Mgha(setC$predicted))
mbe(buac_to_Mgha(setD$observed), buac_to_Mgha(setD$predicted))

#r2
r2(buac_to_Mgha(setA$observed), buac_to_Mgha(setA$predicted))
r2(buac_to_Mgha(setB$observed), buac_to_Mgha(setB$predicted))
r2(buac_to_Mgha(setC$observed), buac_to_Mgha(setC$predicted))
r2(buac_to_Mgha(setD$observed), buac_to_Mgha(setD$predicted))

#rmse
rmse(buac_to_Mgha(setA$observed), buac_to_Mgha(setA$predicted))
rmse(buac_to_Mgha(setB$observed), buac_to_Mgha(setB$predicted))
rmse(buac_to_Mgha(setC$observed), buac_to_Mgha(setC$predicted))
rmse(buac_to_Mgha(setD$observed), buac_to_Mgha(setD$predicted))
