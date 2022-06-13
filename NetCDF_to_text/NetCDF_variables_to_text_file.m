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
ncid=netcdf.open('xxx.nc','nowrite'); % 'xxx.nc': netcdf file name
vars=netcdf.inqVarIDs(ncid);
dlmwrite('vars.txt',vars);
for i=vars(1:end)
    [varname]=netcdf.inqVar(ncid,i);
    dlmwrite('varnames.txt',varname,'delimiter','','-append');
    var=netcdf.getVar(ncid,i);
    varsize=size(var);
    dlmwrite('varsizes.txt',varsize,'delimiter',';','-append');
    if numel(varsize)<3
        dlmwrite(sprintf('var%d.txt',i),var);
    elseif numel(varsize)==3
        for j=1:varsize(3)
            dlmwrite(sprintf('var%d.txt',i),var(:,:,j),'-append');
        end
    elseif numel(varsize)==4
        for j=1:(varsize(3)*varsize(4))
            dlmwrite(sprintf('var%d.txt',i),var(:,:,j),'-append');
        end
    end
end