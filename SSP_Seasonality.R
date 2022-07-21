# Analyze seasonality of sound speed at a give site
# Based on data from HYCOM

#### Parameters defined by user ####
siteabrev <- "NC"
region <- "WAT"
depthlist_range = 1:33 # Depth levels you would like to analyze (NOT the same as the actual depths!!)

setwd("H:/My Drive/PropagationModeling/SSPs") # Working directory
saveDir <- "H:/My Drive/PropagationModeling/SSPs" #export directory

#### Import and set up data ####
SSP_All <- read.csv(paste('SSP_',region, '_',siteabrev,'.csv', sep=""))
SSP_All <- cbind(SSP_All[1], SSP_All[13:54]) # Restrict time range to 07/2015 - 06/2019
SSP_All <- cbind(SSP_All, matrix(NaN,40,6))     # Add empty columns for months w/ no data for ease of use
colnames(SSP_All)[44:49] <- c('X20160501','X20170201','X20170601','X20171001','X20180101','X20180501')
SSP_All <- SSP_All[order(colnames(SSP_All))] # Order columns by month
# Now all columns 12n+2 are July, all columns 12n+3 are August, etc.

depthlist <- drop(t(SSP_All[1]))                      # Average SSPs for the first day of each month
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

#### Graphical Analysis ####

# Plot mean SSP of the first day of each month
x_min <- min(SSP_All[depthlist_range,2:49], na.rm=TRUE)-5 # Graph x-limits
x_max <- max(SSP_All[depthlist_range,2:49], na.rm=TRUE)+5
plot(SSP_M01[depthlist_range],-depthlist[depthlist_range], 'l', col="#0080FF",   # Jan - blue
     xlim=c(x_min,x_max),
     ylim=c(-depthlist[max(depthlist_range)],-depthlist[min(depthlist_range)]), 
     xlab="c (m/s)", ylab="Depth (m)", main=paste('SSP at', siteabrev))
points(SSP_M02[depthlist_range],-depthlist[depthlist_range], 'l', col="#0000FF") 
points(SSP_M03[depthlist_range],-depthlist[depthlist_range], 'l', col="#8000FF")
points(SSP_M04[depthlist_range],-depthlist[depthlist_range], 'l', col="#FF00FF") # April - Pink
points(SSP_M05[depthlist_range],-depthlist[depthlist_range], 'l', col="#FF0080")
points(SSP_M06[depthlist_range],-depthlist[depthlist_range], 'l', col="#FF0000")
points(SSP_M07[depthlist_range],-depthlist[depthlist_range], 'l', col="#FF8000")
points(SSP_M08[depthlist_range],-depthlist[depthlist_range], 'l', col="#FFFF00") # July - Orange
points(SSP_M09[depthlist_range],-depthlist[depthlist_range], 'l', col="#80FF00")
points(SSP_M10[depthlist_range],-depthlist[depthlist_range], 'l', col="#00FF00")
points(SSP_M11[depthlist_range],-depthlist[depthlist_range], 'l', col="#00FF80")
points(SSP_M12[depthlist_range],-depthlist[depthlist_range], 'l', col="#00FFFF") # October - Green

# Plot mean SSP across all months with standard deviation
SSP_MAnnual <- rowMeans(SSP_All[2:49], na.rm=TRUE)
plot(SSP_MAnnual[depthlist_range], -depthlist[depthlist_range], 'l', col="#000000",
     xlim=c(x_min,x_max),
     ylim=c(-depthlist[max(depthlist_range)],-depthlist[min(depthlist_range)]), 
     xlab="c (m/s)", ylab="Depth (m)", main=paste('SSP at', siteabrev))
#calculate and plot stdevs on top
SSP_stdev <- matrix(NA,40,1)
for(j in 1:40) {
  SSP_stdev[j] <- sd(SSP_All[j,2:49], na.rm=TRUE)
}
arrows(SSP_MAnnual-SSP_stdev,-depthlist,SSP_MAnnual+SSP_stdev,-depthlist,
       code=3, angle=90, length=.05)

sumtab <- cbind(depthlist,SSP_MAnnual,SSP_stdev)
colnames(sumtab) <- c("Depth","c_mean","c_stdev")

#Calculate params at 800m
M800 <- c(SSP_M01[31],SSP_M02[31],SSP_M03[31],SSP_M04[31],SSP_M05[31],SSP_M06[31],
          SSP_M07[31],SSP_M08[31],SSP_M09[31],SSP_M10[31],SSP_M11[31],SSP_M12[31])
range800 <- range(M800)
min_month <- which(M800 == range800[1])
max_month <- which(M800 == range800[2])

sumtab800 <- cbind(depthlist[31],SSP_MAnnual[31],SSP_stdev[31],range800[1],min_month,range800[2],max_month)
colnames(sumtab800) <- c("Depth","c_mean","c_stdev","c_min","min_mo","c_max","max_mo")

#Calculate month with min and month with max

# Save text file with output
filename = paste(saveDir,'/',siteabrev,'_SSP_SeasonalStats.txt',sep="")
sink(filename)
sumtab
summary(sumtab)
sumtab800
sink(file = NULL)

# At 800m, save the mean sound speed, the range (min/max), and standard deviation
# What two months were the extremes (we might use this for propagation modeling sensitivity test)

#### Statistical Analysis ####
#Region of interest for Pm: 200m+
