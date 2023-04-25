function AllVariables = loadBTY(GEBCODir)
%% Load netCDF file from GEBCO
ncid=netcdf.open([GEBCODir,'\GEBCO_2022.nc'],'nowrite'); % 'xxx.nc': netcdf file name
vars=netcdf.inqVarIDs(ncid); %Variable names
AllVariables = cell(2,width(vars)); %empty cell array to save variables
% Loop through the netCDF file and save each variable to the cell array
for i=vars(1:end)
    [varname]=netcdf.inqVar(ncid,i);
    var=netcdf.getVar(ncid,i);
    varsize=size(var);
    cellLoc = find(vars==i);
    AllVariables{1,cellLoc} = char(varname);
    AllVariables{2,cellLoc} = var;
end