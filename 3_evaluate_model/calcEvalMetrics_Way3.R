library(raster)
library(rgdal)
library(sf)
library(stringr)
library(ggplot2)
library(RColorBrewer)
library(xgboost)
library(tidyverse)
library(wesanderson)

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

for (i in 1:length(channels)) {
  in_rast <- raster(paste0(path_to, channels[i]))
  in_rast <- raster::calc(in_rast, fun=function(x){ x[x < 0] <- NA; return(x)} )  # 0 is minimum value
  in_rast <- projectRaster(in_rast, yld.5dm)
  in_rast <- mask(in_rast, yld.5dm)
  
  if(i == 1) {
    daystack <- in_rast
  } else {
    daystack <- stack(daystack, in_rast)
  }
}

#writeRaster(daystack, filename = "Way3_070520_daystack")
#writeRaster(yld.5dm, filename = "Way3_Yld_processed.tif", format = "GTiff")

#####################
# at this point, a raster layer of predictions is generated on the server, using the "Way3_070520_daystack" and "Way3_Yld_processed.tif" files
#
# now, load the trained models and generate predictions
#####################

# mask so all have same number of NA's and number of images is same
mostnas_idx <- which.max(as.matrix(cellStats(daystack, stat='countNA')))
yld.dayna <- mask(yld.5dm, daystack[[mostnas_idx]])
daystack <- mask(daystack, daystack[[mostnas_idx]])
daystack_yld <- stack(daystack, yld.dayna)

preds_cnn <- raster('~/Desktop/Projects/rice_irrigation/projectCNN_070520_Way3.tif')
preds_cnn <- extend(preds_cnn, 20)
preds_cnn <- crop(preds_cnn, extent(daystack_yld))
preds_cnn <- mask(preds_cnn, daystack[[mostnas_idx]])
names(preds_cnn) <- 'preds_2d'
daystack_yld <- stack(daystack_yld, preds_cnn)

way3df <- as.data.frame(na.omit(as.matrix(daystack_yld))) # drop any rows with NA for any vegetation index
colnames(way3df) <- colnames(test.df)[1:8]
colnames(way3df)[9] <- 'preds_2d'

# add a column for predictions
way3df$Yield_Mgha <- buac_to_Mgha(way3df$Yield)
way3df$preds_lin <- buac_to_Mgha(predict(mod.lin, way3df))
way3df$preds_null <- buac_to_Mgha(mod.null)

way3df$preds_2d <- buac_to_Mgha(way3df$preds_2d)

dtest <- xgb.DMatrix(data = as.matrix(way3df[,c(1:7)]), label = as.matrix(way3df[,8]))
way3df$preds_xgb = buac_to_Mgha(predict(bst, dtest))

# calculate metrics
# rmse
rmse(way3df$Yield_Mgha, way3df$preds_2d)
rmse(way3df$Yield_Mgha, way3df$preds_xgb)
rmse(way3df$Yield_Mgha, way3df$preds_lin)
rmse(way3df$Yield_Mgha, way3df$preds_null)

#r2
r2(way3df$Yield_Mgha, way3df$preds_2d)
r2(way3df$Yield_Mgha, way3df$preds_xgb)
r2(way3df$Yield_Mgha, way3df$preds_lin)
r2(way3df$Yield_Mgha, way3df$preds_null)

#mbe
mbe(way3df$Yield_Mgha, way3df$preds_2d)
mbe(way3df$Yield_Mgha, way3df$preds_xgb)
mbe(way3df$Yield_Mgha, way3df$preds_lin)
mbe(way3df$Yield_Mgha, way3df$preds_null)

#mae
mae(way3df$Yield_Mgha, way3df$preds_2d)
mae(way3df$Yield_Mgha, way3df$preds_xgb)
mae(way3df$Yield_Mgha, way3df$preds_lin)
mae(way3df$Yield_Mgha, way3df$preds_null)

## figure
all <- read.csv('../Figures_for_MS/setb_way3_070520.csv', header = T)
all <- all %>% 
  pivot_longer(cols = -model)

p <- ggplot(all, aes(x = name, y = value, fill = model)) +
  geom_bar(stat = "identity", position = "dodge", col = "black", lwd = 0.2) +
  theme_light() +
  theme(panel.grid.minor.x = element_blank()) +
  scale_fill_manual(values = wes_palette("Zissou1", 5, type = c("discrete"))[c(1,3,5)], 
                    name = "Model") +
  xlab("")

pdf('../Figures_for_MS/Figure6.pdf', height = 2.5, width = 3)
p
dev.off()
