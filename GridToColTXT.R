#load libraries
require(utils)
require(dplyr)

txtdir = 'I:/My Drive/Bathymetry/WAT/GEBCO/txt' #Directory with txt files

#Load lat, lon, and depth txt files (output from MATLAB)
latdir = paste(txtdir,'/var0.txt',sep="")
lat = read.delim(latdir,header=FALSE)

londir = paste(txtdir,'/var1.txt',sep="")
lon = read.delim(londir,header=FALSE)

latlon = expand.grid(lat$V1, lon$V1)
latlon$depth = 1

depthdir = paste(txtdir,'/var2.txt',sep="")
depthDF = read.delim(depthdir,header=FALSE,sep=",")
depth = unname(data.matrix(depthDF))

#Find first and last sequence for every 5147th value for blocking in for loop
sequFIRST = seq(1,nrow(latlon),5147)
sequLAST = seq(5147,nrow(latlon),5147)

#Take each row and transpose it as a column to match the lat/lon dataframe
for(i in 1:nrow(depth)){
  Row = depth[i,]
  latlon$depth[sequFIRST[i]:sequLAST[i]] = Row
}

#Save as txt file
latlonOCEAN = latlon[!(latlon$depth >= 0),]
write.table(latlonOCEAN, file = paste(txtdir,"/bathy.txt",sep=""), sep = "\t",
            row.names = FALSE, col.names = FALSE)
