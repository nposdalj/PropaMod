function AllVariables = loadBTYJAH(distDec,hlat_range,hlon_range,GEBCODir,GEBCOFile)
%% Load file from GEBCO
[~, ~, exten] = fileparts(fullfile(GEBCODir,GEBCOFile));
if strcmp(exten,'.tif')
    [A, R] = readgeoraster(fullfile(GEBCODir,GEBCOFile));
    A = double(A);
    % Step 2: Create a meshgrid for pixel coordinates
    [rowLon, colLon] = meshgrid(1:R.RasterSize(1), 1);
    [rowLat, colLat] = meshgrid(1, 1:R.RasterSize(2));
    % Step 3: Convert intrinsic coordinates to geographic coordinates
    [lat, ~] = intrinsicToGeographic(R, rowLat, colLat);
    [~, lon] = intrinsicToGeographic(R, rowLon, colLon);
    lon = lon';
    AllVariables{1,1} = 'x';
    AllVariables{1,2} = 'y';
    AllVariables{1,3} = 'z';
    AllVariables{1,4} = 'R';
    AllVariables{2,1} = lon;
    AllVariables{2,2} = lat';
    AllVariables{2,3} = abs(flipud(A));
    AllVariables{2,4} = R;
elseif strcmp(exten,'.nc')
    ncid=netcdf.open(fullfile(GEBCODir,GEBCOFile),'nowrite'); % 'xxx.nc': netcdf file name
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
    % Need this version for certain .nc files...
    % lonLoc = (find(strcmp(AllVariables,'x'))+1)/2; % Find which cell contains lon
    % latLoc = (find(strcmp(AllVariables,'y'))+1)/2; % Find which cell contains lat
    % elevationLoc = (find(strcmp(AllVariables,'z'))+1)/2; % Find which cell contains elevation
    % ... and this version for others.
    lonLoc = (find(strcmp(AllVariables,'lon'))+1)/2; % Find which cell contains lon
    latLoc = (find(strcmp(AllVariables,'lat'))+1)/2; % Find which cell contains lat
    elevationLoc = (find(strcmp(AllVariables,'elevation'))+1)/2; % Find which cell contains elevation

    % Extract lat, lon, and elevation for entire site
    latValsIDX = find(AllVariables{2,latLoc}<hlat_range(1) & AllVariables{2,latLoc}>hlat_range(2));
    latVals = AllVariables{2,latLoc}(latValsIDX);
    lonValsIDX = find(AllVariables{2,lonLoc}<hlon_range(1) & AllVariables{2,lonLoc}>hlon_range(2));
    lonVals = AllVariables{2,lonLoc}(lonValsIDX);

    depthVals = AllVariables{2,elevationLoc}(lonValsIDX,latValsIDX); %index depth based on +/- lat and lon away from reciever

    AllVariables{2,lonLoc} = lonVals;
    AllVariables{2,latLoc} = latVals;
    % AllVariables{2,4} = depthVals; % Original line; JAH changed as below.
    % AllVariables{2,3} = abs(depthVals); %JAH changed from 4 t0 3
    AllVariables{2,4} = -depthVals; % WASD changed to elevationLoc
end






