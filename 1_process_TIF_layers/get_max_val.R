get_max_val <- function(vi) {
  if (vi == "CIgreen") { # set max interval based on Vegetation Index to discard values outside of range
      maxVal <- 18
      minVal <- 0
  } else if (vi == "GNDVI"| vi == "NAVI"| vi == "NDVI"| vi=="RENDVI"| vi=="TGI") {
      maxVal <- 8
      minVal <- 0
  } else if (vi=="Thermal") {
    maxVal <- 60
    minVal <- -1000
  } else {
  stop("Invalid Vegetation Index.")
  }

  return(maxVal)
}