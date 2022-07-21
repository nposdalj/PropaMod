function BathData = ReadBathymetryFile(filename)
% opens files and returns bathymetry data in an N x 2 array : {r, z} - r & z in metres
% filename - must include full path ... if omitted, this becomes interactive (file dialog)
%        
% 30 May 2003 ALM

Here = pwd;
InFile = -1;
if nargin >= 1
   InFile = fopen(filename, 'rt');
end   
% if open fails or there was no filename get filename interactively
if InFile == -1 
   [File, Path] = uigetfile('*.bty', 'Bathymetry file');
   if File ~= 0
      filename = [Path File]
   else
      disp('WARNING ReadBathymetryFile: File Selection Cancelled');
      return;
   end
   InFile = fopen(filename, 'rt');
   if InFile < 0 
      disp('ERROR ReadBathymetryFile: File Open Failed');
      return;
   end
end   
% at this stage should have a file pointer InFile (or have returned)
fgetl(InFile);
NPt = fscanf(InFile, '%f', 1);
BathData = fscanf(InFile, '%f', [2, NPt]);
% convert range from km to m
BathData(1, :) = BathData(1, :)*1000;    
fclose(InFile);
% return to working directory
cd(Here);