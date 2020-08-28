### visualize difference in MSE over time
library(ggplot2)
library(dplyr)
library(lubridate)

# file of MSE over time, where each date in turn is 'blanked' out with the average value for that date
mses <- read.csv('Documents/GitHub/XASU_rice/blankone_b64.csv',header=F)[,1:2]
mses$date <- mdy(mses$V1)
p <- ggplot(mses, aes(x=date, y=V2)) + geom_line() + geom_point(size=2) + theme_classic() + xlab("Masked Day") + ylab("Test Set MSE") + geom_hline(yintercept =155, lty=2)

pdf('~/Desktop/Projects/rice_irrigation/TemporalVar.pdf', width=3, height=3)
p
dev.off()
