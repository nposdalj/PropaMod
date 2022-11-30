#This code uses the .txt outputs from the MATLAB code NetCDF_variables_to_text_file.m...
#and re-formats it to match what the bellhop_PropMod.m code requires


#load libraries
require(utils)
require(dplyr)

GDrive = 'I'
Region = 'WAT'
txtdir = paste(GDrive,':/My Drive/PropagationModeling/Bathymetry/',Region,'/GEBCO/txt',sep="") #Directory with txt files
savedir = paste(GDrive,':/My Drive/PropagationModeling/Bathymetry/',Region,sep="") #Directory where to save Bathy.txt file

#Load lat, lon, and depth txt files (output from MATLAB)
latdir = paste(txtdir,'/var0.txt',sep="")
lat = read.delim(latdir,header=FALSE)
nth = nrow(lat)

londir = paste(txtdir,'/var1.txt',sep="")
lon = read.delim(londir,header=FALSE)

latlon = expand.grid(lat$V1, lon$V1)
latlon$depth = 1

depthdir = paste(txtdir,'/var2.txt',sep="")
depthDF = read.delim(depthdir,header=FALSE,sep=",")
depth = unname(data.matrix(depthDF))

#Find first and last sequence for every 5147th value for blocking in for loop
sequFIRST = seq(1,nrow(latlon),nth)
sequLAST = seq(nth,nrow(latlon),nth)

#Take each row and transpose it as a column to match the lat/lon dataframe
for(i in 1:nrow(depth)){
  Row = depth[i,]
  latlon$depth[sequFIRST[i]:sequLAST[i]] = Row
}

#Save as txt file
latlonOCEAN = latlon[!(latlon$depth >= 0),]
write.table(latlonOCEAN, file = paste(savedir,"/bathy.txt",sep=""), sep = "\t",
            row.names = FALSE, col.names = FALSE)
