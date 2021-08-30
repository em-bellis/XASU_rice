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
path_to <- "/Volumes/LaCie/Dr.\ Reba/Humnok/Way_3/2020/07-05-2020/Index\ clips/"

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
  mod <- lm(observed ~ predicted)
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
yld <- raster('~/Desktop/2020_Way_Yield_Maps/Way_3_N_2020_Yield/Way_2020_Yield1.tif')
crop_extent <- readOGR(paste0(path_to,"../Shapefiles/Way_3_North_Without_Ditch.shp"))
yld.5d <- crop(yld, crop_extent)
yld.5dm <- mask(yld.5d, crop_extent) # 5616 cells; 5235 of these are non-NA

## process all other layers (downsample, crop, mask); make raster stacks for each day; split into test, train, and validation sets; split each of these into 5x5 pixel subimages and then save each image and channel separately as .csv file 
channels <- c("CIgr_clip.tif","GNDVI_Clip.tif","NAVI_Clip.tif","../Raw\ raster\ clips/ndvi_Clip.tif","RENDVI_Clip.tif","TGI_Clip.tif","Thermal_Clip.tif")

############################### output project for 1 day based on linear model
cigr <- raster(paste0(path_to, channels[1]))
cigr <- projectRaster(cigr, yld.5dm)

tgi <- raster(paste0(path_to, channels[6]))
tgi <- projectRaster(tgi, yld.5dm)
 
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

####### stats
results <- read.csv('../Figures_for_MS/results_summary.csv', header = T)
library(lme4)
glm