library(raster)
library(rgdal)
library(sf)
library(stringr)
library(ggplot2)
library(tidyr)
library(lubridate)

source('~/Documents/GitHub/XASU_rice/1_process_TIF_layers/get_max_val.R')
source('~/Documents/GitHub/XASU_rice/1_process_TIF_layers/process_VIs.R')

# # use yield layer for projection
yld <- raster('/Volumes/ABISSD/Yield.tif')
yld.5 <- aggregate(yld, 10) # 0.5 x 0.5 m resolution
crop_extent <- readOGR(paste("/Volumes/ABISSD/04-11-2019/Carr_N_Without_Ditch.shp", sep="/"))
yld.m <- mask(yld.5, crop_extent)

## what is the distribution of yield values?
hist(yld.m)
quantile(yld.m, probs = c(0.10, 0.9)) # 154.6; 194.5

## create a mask for the lower 10%
lower_10 <- raster::calc(yld.m, fun=function(x){ x[x > 154.6] <- NA; return(x)} )
upper_10 <- raster::calc(yld.m, fun=function(x){ x[x < 194.5] <- NA; return(x)} )

flydays <- c("04-11-2019","05-21-2019","06-13-2019","06-29-2019","07-11-2019","08-01-2019", "08-13-2019", "08-21-2019","08-28-2019","09-07-2019","09-13-2019") 
channels <- c("CIgreen.tif","GNDVI.tif","NAVI.tif","NDVI.tif","RENDVI.tif","TGI.tif","Thermal.tif")
path_to_raster <- "/Volumes/ABISSD/"

# set up a dataframe with the indices
vis.list <- str_replace(channels, '.tif', '')
vis.df <- data.frame(Day=flydays, Stage=c("fallow","VEG","VEG","VEG","REP_R0","REP_R2","REP_R4","GF","GF","GF","GF"),Channel=NA, Mean=NA, Lower=NA, Upper=NA)
vi_mean = rep(0,length(flydays))
vi_low = rep(0,length(flydays))
vi_high = rep(0,length(flydays))

## create df
for (i in 7:length(vis.list)) {
   for (j in 1:length(flydays)) {
     curr <- raster(paste(path_to_raster,flydays[j],channels[i], sep = "/"))
     if (i<7) # 
        { processed_rast <- process_VIs(vis.list[i], curr, yld.m, get_max_val(vis.list[i]))}
     else if (i==7) 
        { processed_rast <- process_VIs(vis.list[i], curr, yld.m, 60)}
     vis.df$Channel[j] <- vis.list[i]
     vis.df$Mean[j] <- cellStats(processed_rast, stat='mean', na.rm=TRUE)
     
     rast_low <- mask(processed_rast, lower_10)
     vis.df$Lower[j] <-  cellStats(rast_low, stat='mean', na.rm=TRUE)
     
     rast_hi <- mask(processed_rast, upper_10)
     vis.df$Upper[j] <-  cellStats(rast_hi, stat='mean', na.rm=TRUE)
     
     message(paste0("Done with ", vis.list[i], ", ", flydays[j]))
   }
   
   if(i==1) {
     all.df <- vis.df 
   } else {
     all.df <- rbind.data.frame(all.df, vis.df)
   }
   vis.df <- data.frame(Day=flydays, Stage=c("fallow","VEG","VEG","VEG","REP_R0","REP_R2","REP_R4","GF","GF","GF","GF"),Channel=NA, Mean=NA, Lower=NA, Upper=NA)
}
 
#write.table(all.df, file="avg_VI_3.txt", quote=F, sep="\t", row.names=F)
all.df <- read.table("~/Documents/GitHub/XASU_rice/Figures_for_MS/avg_VI_3.txt", header=T)

# plot, 1 col = 85 mm, 2 col = 180
all.df <- read.table('avg_VI_3.txt', header=T)
all.df$Day <- mdy(all.df$Day)
df.long <- pivot_longer(all.df, cols=Mean:Upper)

p.all <- ggplot(df.long, aes(x=Day, y=value, lty=name, group=name)) + 
  geom_line() + theme_classic() + facet_grid(Channel~., scales="free") + 
  labs(lty="Yield Group", col="Yield Group") +
  scale_linetype_manual(values=c(2,1,3), labels=c("Lower 10%","All","Upper 10%")) +
  theme(axis.text.x = element_text(angle = 90, vjust=0.5)) +
   

pdf("Figure1_VIs.pdf", width=7.08, height=6)
p.all
dev.off()
