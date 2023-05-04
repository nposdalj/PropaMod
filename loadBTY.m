function AllVariables = loadBTY(distDec,hlat_range,hlon_range,GEBCODir)
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

% Find which cell contains lat, lon, and elevation/depth
lonLoc = (find(strcmp(AllVariables,'lon'))+1)/2; % Find which cell contains lon
latLoc = (find(strcmp(AllVariables,'lat'))+1)/2; % Find which cell contains lat
elevationLoc = (find(strcmp(AllVariables,'elevation'))+1)/2; % Find which cell contains elevation

% Extract lat, lon, and elevation for entire site
latValsIDX = find(AllVariables{2,latLoc}<hlat_range(1) & AllVariables{2,latLoc}>hlat_range(2));
latVals = AllVariables{2,latLoc}(latValsIDX);
lonValsIDX = find(AllVariables{2,lonLoc}<hlon_range(1) & AllVariables{2,lonLoc}>hlon_range(2));
lonVals = AllVariables{2,lonLoc}(lonValsIDX);

depthVals = AllVariables{2,elevationLoc}(lonValsIDX,latValsIDX); %index depth based on +/- lat and lon away from reciever

AllVariables{2,1} = lonVals;
AllVariables{2,2} = latVals;
AllVariables{2,4} = depthVals;






