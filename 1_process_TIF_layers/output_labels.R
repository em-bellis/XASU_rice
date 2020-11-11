output_labels <- function(mat, path_to, section) {
  ### this function will output 5 x 5 pixel labels
  i <- 1
  for (r in seq(1,(dim(mat)[1]-4),5)) { # 5 x 5 pixel non-overlapping subimages
    for (c in seq(1,(dim(mat)[2]-4),5)) {
      avg <- round(mean(mat[r:(r+4),c:(c+4)]), digits=0)
      file_id <- paste("yld",i,".csv", sep="")
      subimg <- round(mat[r:(r+4),c:(c+4)],digits=0)
      
      dir.create(paste(path_to,"labels/",section, sep=""), recursive=T)
      
      if (is.na(avg) == "FALSE") {
        write.table(subimg, file=paste(path_to,"labels/",section,"/",file_id,sep=""), quote=F, sep=",", row.names=F, col.names = F)
      }
      i <- i+1
    }
  }
}