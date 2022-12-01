% This MATLAB code was moddified from Tahsin Gormus's script (see citation
% below) to convert NetCDF files from GEBCO to text files and to get the
% data ready to be used for the propagation modeling code. 
% NP 11/30/2022

%   This matlab code writes a netcdf file's variables to seperate text
%   files by Tahsin Gormus.
%       vars.txt: number of variables (starts from zero)
%       varsizes.txt: dimensions of variables
%       varnames.txt: names of variables
%       var0,var1,....txt: variables (matrices/arrays)
%   Tahsin Gormus
%   April 2017, Istanbul

close all; clear; clc;
delete varnames.txt
delete varsizes.txt
%% User Defined Parameters
% Set directories
NCdir = 'I:\My Drive\PropagationModeling\Bathymetry\GlobalCoverage\GEBCO\netCDF';
txtdir = 'I:\My Drive\PropagationModeling\Bathymetry\GlobalCoverage\GEBCO\txt';
NCfn = 'gebco_2022'; %.nc file name

% What files do you want to work with?
LoadNC = 1; % (1) Load the .nc files
ConvTXT = 0; % (1) Convert the .nc file to .txt files and save them
LoadTXT = 0; % (1) Load the .txt files
%% Load .nc files
if LoadNC == 1
ncid=netcdf.open([NCdir,'\',NCfn,'.nc'],'nowrite'); % 'xxx.nc': netcdf file name
vars=netcdf.inqVarIDs(ncid);
dlmwrite([txtdir,'\vars.txt'],vars);
AllVariables = cell(2,width(vars));
for i=vars(1:end)
    [varname]=netcdf.inqVar(ncid,i);
    dlmwrite([txtdir,'\varnames.txt'],varname,'delimiter','','-append');
    var=netcdf.getVar(ncid,i);
    varsize=size(var);
    dlmwrite([txtdir,'\varsizes.txt'],varsize,'delimiter',';','-append');
    cellLoc = find(vars==i);
    AllVariables{1,cellLoc} = char(varname);
    AllVariables{2,cellLoc} = var;
    %% Convert .nc file to .txt file
    if ConvTXT == 1
    if numel(varsize)<3
        dlmwritetemp = sprintf('var%d.txt',i);
        dlmwrite([txtdir,'\',dlmwritetemp],var);
    elseif numel(varsize)==3
        for j=1:varsize(3)
            dlmwritetemp = sprintf('var%d.txt',i);
            dlmwrite([txtdir,'\',dlmwritetemp],var(:,:,j),'-append');
        end
    elseif numel(varsize)==4
        for j=1:(varsize(3)*varsize(4))
            dlmwritetemp = sprintf('var%d.txt',i);
            dlmwrite([txtdir,'\',dlmwritetemp],var(:,:,j),'-append');
        end
    else
    end
    end
end
else
end
%% Load .txt files
if LoadTXT == 1
    %load txt files
    latdir = [txtdir,'\var1.txt'];
    lat = importdata(latdir);
    londir = [txtdir,'\var0.txt'];
    lon = importdata(londir);
    depthdir = [txtdir,'\var3.txt'];
    depth = importdata(depthdir);
end
%% Convert from grid to columns
lonLoc = (find(strcmp(AllVariables,'lon'))+1)/2; % Find which cell contains lon
latLoc = (find(strcmp(AllVariables,'lat'))+1)/2; % Find which cell contains lat
elevationLoc = (find(strcmp(AllVariables,'elevation'))+1)/2; % Find which cell contains elevation

[X,Y] = meshgrid (AllVariables{2,latLoc}, AllVariables{2,lonLoc});
latlon = [X(:),Y(:)];