#source('~/Documents/GitHub/XASU_rice/1_process_TIF_layers/get_max_val.R')
#source('~/Documents/GitHub/XASU_rice/1_process_TIF_layers/process_VIs.R')

create_daystack <- function(path_to_raster, flyday, channel_list, ex_rast) {
  ### this function will process rasters and create a stack of channels for one day
  vis.list <- str_replace(channel_list, '.tif', '')
  for (i in 1:length(channel_list)) {
    curr <- raster(paste(path_to_raster,flyday,channel_list[i], sep = "/"))
    if (i<7) { 
      processed_rast <- process_VIs(vis.list[i], curr, ex_rast, get_max_val(vis.list[i]),0)
    } else if (i==7) { 
     processed_rast <- process_VIs(vis.list[i], curr, ex_rast, 60,-400)
    }
  
    if(i == 1){
      daystack <- processed_rast
    } else {
      daystack <- stack(daystack, processed_rast)
    }
  }
  return(daystack)
}
