function [Range, bath] = makeBTY_old(fpath, fname, slat, slon, hlat, hlon, GEBCODir)
% VZ: Modified from Eric Snyder's makeBTY.m code
% NOTE: I'm using the hydrophone as the source and ship as receiver for now
global rangeStep
global lati
global loni
global rad
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

% Extract lat, lon, and elevation that matches site location
latRange = [hlat+1 hlat-1]; %+/- 1 degree for lat
latValsIDX = find(AllVariables{2,latLoc}<latRange(1) & AllVariables{2,latLoc}>latRange(2));
latVals = AllVariables{2,latLoc}(latValsIDX);
lonRange = [hlon+1 hlon-1]; %+/- 1 degree for lon
lonValsIDX = find(AllVariables{2,lonLoc}<lonRange(1) & AllVariables{2,lonLoc}>lonRange(2));
lonVals = AllVariables{2,lonLoc}(lonValsIDX);

depthVals = AllVariables{2,elevationLoc}(lonValsIDX,latValsIDX); %index depth based on +/- lat and lon away from reciever

%create two columns for lat and lon
[X,Y] = meshgrid(latVals,lonVals);
latlon = [X(:),Y(:),];

%Find the first and last sequence for every nth value for blocking of depth
nth = height(latVals);
sequFIRST = 1:nth:height(latlon);
sequLAST = nth:nth:height(latlon);

%Take each row of depth and transpose it as a column to match the lat/lon matrix
for ii = 1:height(depthVals)
    Row = -1*depthVals(:,ii);
    latlon(sequFIRST(ii):sequLAST(ii),3) = Row;
end
%% Interpolate w/ interp2 to extract a line of bathymetry?
fpn = fullfile(fpath, [fname, '.bty']);
[xi, yi] = latlon2xy(lati(rad, :), loni(rad, :), hlat, hlon);
ri = sqrt(xi.^2 + yi.^2)./1000;
bathi = griddata(latlon(:,1), latlon(:,2), latlon(:,3), lati(rad, :), loni(rad, :), 'linear');

Range = ri.';
bath = abs(bathi).';

[Rsort, I] = sort(Range);
bathSort = bath(I);

writebdry( fpn, 'C', ([Rsort, bathSort]) ) % write bty file