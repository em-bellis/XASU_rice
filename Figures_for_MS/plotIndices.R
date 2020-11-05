library(raster)
library(rgdal)
library(sf)
library(stringr)
library(ggplot2)
library(tidyr)
library(lubridate)

# # use yield layer for projection
# yld <- raster('/Volumes/ExtremeSSD/Data/Yield.tif')
# crop_extent <- readOGR(paste("/Volumes/ExtremeSSD/Data/Humnoke/Carr_North/04-11-2019/Carr_N_Without_Ditch.shp", sep="/"))
# yld.m <- mask(yld, crop_extent)
# 
# flydays <- c("04-11-2019","05-21-2019","06-13-2019","06-29-2019","07-11-2019","08-01-2019", "08-13-2019", "08-21-2019","08-28-2019","09-07-2019","09-13-2019") 
# channels <- c("CIgreen.tif","GNDVI.tif","NAVI.tif","NDVI.tif","RENDVI.tif","TGI.tif","Thermal.tif")
# path_to_raster <- "/Volumes/ExtremeSSD/Data/Humnoke/Carr_North/"
# 
# # set up a dataframe with the indices
# vis.list <- str_replace(channels, '.tif', '')
# vis.df <- data.frame(Day=flydays, Stage=c("fallow","VEG","VEG","VEG","REP_R0","REP_R2","REP_R4","GF","GF","GF","GF"))
# veg_index = rep(0,length(flydays))
# minVal <- 0
# 
# for (i in 7:length(vis.list)) {
#   if (i == 1) { # set max interval based on Vegetation Index to discard values outside of range
#     maxVal <- 18
#   } else if (i == 6) {
#     maxVal <- 8} 
#   else {
#     maxVal <- 1
#   }
# 
#   for (j in 1:length(flydays)) {
#     curr <- raster(paste(path_to_raster,flydays[j],channels[i], sep = "/"))
#     #curr <- calc(curr, fun=function(x){ x[x > maxVal | x < minVal] <- NA; return(x)} )
#     curr.rp <- projectRaster(curr, yld.m) # some of the layers are not in UTM coordinates
#     curr.rpm <- mask(curr.rp, yld.m)
# 
#     veg_index[j] <- cellStats(curr.rpm, stat='mean', na.rm=TRUE)
#     message(paste0("Done with ", vis.list[i], ", ", flydays[j]))
#   }
#   
#   vis.df <- cbind.data.frame(vis.df, veg_index)
#   #names(vis.df)[2+i] <- vis.list[i]
#   names(vis.df)[i] <- vis.list[i]
# }
# 
# 
# #write.table(vis.df, file="avg_VI_2.txt", quote=F, sep="\t", row.names=F)
vis.df <- read.table("avg_VI.txt", header=T)

# plot
vis.df$Day <- mdy(vis.df$Day)
df.long <- pivot_longer(vis.df, cols=CIgreen:Thermal)
df.nnr <- subset(df.long, name!="Thermal" & name!="CIgreen" & name!="TGI")
df.tml <- subset(df.long, name=="Thermal")
df.chl <- subset(df.long, name=="CIgreen" | name=="TGI")

ggplot(df.nnr, aes(x=Day, y=value, col=name, lty=name)) + 
  geom_line() + geom_point() + theme_classic() + labs(lty="Veg. Index", col="Veg. Index") + 
  annotate("rect", xmin = as.Date("2019-07-11"), xmax = as.Date("2019-08-13"), ymin =0, ymax = 1, alpha = .2) +
  annotate("text", x=as.Date("2019-07-11"), y=1, label="R0") +
  annotate("text", x=as.Date("2019-08-01"), y=1, label="R2") +
  annotate("text", x=as.Date("2019-08-13"), y=1, label="R4")


ggplot(df.chl, aes(x=Day, y=value, col=name, lty=name)) + 
  geom_line() + geom_point() + theme_classic() + labs(lty="Veg. Index", col="Veg. Index") + 
  annotate("rect", xmin = as.Date("2019-07-11"), xmax = as.Date("2019-08-13"), ymin =0, ymax = 10, alpha = .2) +
  annotate("text", x=as.Date("2019-07-11"), y=10, label="R0") +
  annotate("text", x=as.Date("2019-08-01"), y=9.2, label="R2") +
  annotate("text", x=as.Date("2019-08-13"), y=7.7, label="R4")

ggplot(df.tml, aes(x=Day, y=value, col=name, lty=name)) + 
  geom_line() + geom_point() + theme_classic() + labs(lty="Veg. Index", col="Veg. Index") + 
  annotate("rect", xmin = as.Date("2019-07-11"), xmax = as.Date("2019-08-13"), ymin =0, ymax = 36, alpha = .2) +
  annotate("text", x=as.Date("2019-07-11"), y=32, label="R0") +
  annotate("text", x=as.Date("2019-08-01"), y=30, label="R2") +
  annotate("text", x=as.Date("2019-08-13"), y=36, label="R4")


