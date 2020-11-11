output_images <- function(mat, path_to, channel_name) {
  ### this function will output 5 x 5 pixel subimages
  k <- 1 #k is a unique id for each subimage
  for (r in seq(1,(dim(mat)[1]-4),5)) {
    for (c in seq(1,(dim(mat)[2]-4),5)) {
      subimg <- round(mat[r:(r+4),c:(c+4)],digits=2)
      file_id <- paste(channel_name,k,".csv", sep="")
      
      if (is.na(mean(subimg)) == "FALSE") {
        write.table(subimg, file=paste(path_to_imgs,"/",file_id,sep=""), quote=F, sep=",", row.names=F, col.names=F)
      }
      k <- k+1
    }
  }
}