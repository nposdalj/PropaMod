# Analyze seasonality of sound speed at a give site
# Based on data from HYCOM

#### Parameters defined by user ####
siteabrev <- "GS"
region <- "WAT"
depthlist_range = 20:40 # Depth levels you would like to analyze (NOT the same as the actual depths!!)

setwd("H:/My Drive/PropagationModeling/SSPs") # Working directory

#### Import and set up data ####
SSP_All <- read.csv(paste('SSP_',region, '_',siteabrev,'.csv', sep=""))
SSP_All <- cbind(SSP_All[1], SSP_All[13:54]) # Restrict time range to 07/2015 - 06/2019
SSP_All <- cbind(SSP_All, matrix(NaN,40,6))     # Add empty columns for months w/ no data for ease of use
colnames(SSP_All)[44:49] <- c('X20160501','X20170201','X20170601','X20171001','X20180101','X20180501')
SSP_All <- SSP_All[order(colnames(SSP_All))] # Order columns by month
# Now all columns 12n+2 are July, all columns 12n+3 are August, etc.

depthlist <- drop(t(SSP_All[1]))
SSP_M01 <- rowMeans(SSP_All[12*(0:3)+8], na.rm=TRUE)  # Jan
SSP_M02 <- rowMeans(SSP_All[12*(0:3)+9], na.rm=TRUE)  # Feb
SSP_M03 <- rowMeans(SSP_All[12*(0:3)+10], na.rm=TRUE) # Mar
SSP_M04 <- rowMeans(SSP_All[12*(0:3)+11], na.rm=TRUE) # Apr
SSP_M05 <- rowMeans(SSP_All[12*(0:3)+12], na.rm=TRUE) # May
SSP_M06 <- rowMeans(SSP_All[12*(1:4)+1], na.rm=TRUE)  # Jun
SSP_M07 <- rowMeans(SSP_All[12*(0:3)+2], na.rm=TRUE)  # Jul
SSP_M08 <- rowMeans(SSP_All[12*(0:3)+3], na.rm=TRUE)  # Aug
SSP_M09 <- rowMeans(SSP_All[12*(0:3)+4], na.rm=TRUE)  # Sep
SSP_M10 <- rowMeans(SSP_All[12*(0:3)+5], na.rm=TRUE)  # Oct
SSP_M11 <- rowMeans(SSP_All[12*(0:3)+6], na.rm=TRUE)  # Nov
SSP_M12 <- rowMeans(SSP_All[12*(0:3)+7], na.rm=TRUE)  # Dec

#### Analysis ####
plot(SSP_M01[depthlist_range],-depthlist[depthlist_range], 'l', col="#0080FF",   # Jan - blue
     xlim=c(1480,1530), ylim=c(-1000,-200), 
     xlab="c (m/s)", ylab="Depth (m)", title=paste('SSP at', siteabrev))
points(SSP_M02[depthlist_range],-depthlist[depthlist_range], 'l', col="#0000FF") 
points(SSP_M03[depthlist_range],-depthlist[depthlist_range], 'l', col="#8000FF")
points(SSP_M04[depthlist_range],-depthlist[depthlist_range], 'l', col="#FF00FF") # April - Pink
points(SSP_M05[depthlist_range],-depthlist[depthlist_range], 'l', col="#FF0080")
points(SSP_M06[depthlist_range],-depthlist[depthlist_range], 'l', col="#FF0000")
points(SSP_M07[depthlist_range],-depthlist[depthlist_range], 'l', col="#FF8000")
points(SSP_M08[depthlist_range],-depthlist[depthlist_range], 'l', col="#FFFF00") # July - Orange
points(SSP_M09[depthlist_range],-depthlist[depthlist_range], 'l', col="#80FF00")
points(SSP_M10[depthlist_range],-depthlist[depthlist_range], 'l', col="#00FF00")
points(SSP_M11[depthlist_range],-depthlist[depthlist_range], 'l', col="#00FF80") # October - Green
points(SSP_M12[depthlist_range],-depthlist[depthlist_range], 'l', col="#00FFFF")