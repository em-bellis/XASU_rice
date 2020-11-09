source("get_max_val.R")
library(raster)

process_VIs <- function(vi, in_rast, ex_rast, maxVal) {
  # This function processes an input raster to have the same extent, crs, and resolution as an example input raster
  # Vegetation indices are also processed to set appropriate values to NA
  # ex: process_VIs("CIgreen", CIgreen.tif, yld.m)
  
  in_rast <- raster::calc(in_rast, fun=function(x){ x[x > maxVal | x < minVal] <- NA; return(x)} )
  in_rast <- projectRaster(in_rast, ex_rast) # some of the layers are not in UTM coordinates
  in_rast <- mask(in_rast, ex_rast)
  
  return(in_rast)
}