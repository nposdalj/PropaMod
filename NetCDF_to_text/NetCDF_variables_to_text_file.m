%
%   This matlab code writes a netcdf file's variables to seperate text
%   files.
%       vars.txt: number of variables (starts from zero)
%       varsizes.txt: dimensions of variables
%       varnames.txt: names of variables
%       var0,var1,....txt: variables (matrices/arrays)
%
%
%   Tahsin Gormus
%   April 2017, Istanbul
%
close all
clear
clc
delete varnames.txt
delete varsizes.txt
%% NC to txt file
NCdir = 'I:\My Drive\Bathymetry\WAT\GEBCO\netCDF\GEBCO_13_Jun_2022_6f9df15f1a01';
txtdir = 'I:\My Drive\Bathymetry\WAT\GEBCO\txt';
ncid=netcdf.open([NCdir,'\gebco_2021_n46.7138671875_s25.2685546875_w-82.177734375_e-60.0.nc'],'nowrite'); % 'xxx.nc': netcdf file name
vars=netcdf.inqVarIDs(ncid);
dlmwrite([txtdir,'\vars.txt'],vars);
for i=vars(1:end)
    [varname]=netcdf.inqVar(ncid,i);
    dlmwrite([txtdir,'\varnames.txt'],varname,'delimiter','','-append');
    var=netcdf.getVar(ncid,i);
    varsize=size(var);
    dlmwrite([txtdir,'\varsizes.txt'],varsize,'delimiter',';','-append');
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
    end
end

%% Convert from grid to columns
%load txt files
latdir = [txtdir,'\var0.txt'];
lat = importdata(latdir);
londir = [txtdir,'\var1.txt'];
lon = importdata(londir);
depthdir = [txtdir,'\var2.txt'];
depth = importdata(depthdir);

[X,Y] = meshgrid (lat, lon);