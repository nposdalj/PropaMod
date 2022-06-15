% plotSSP
% Plot Sound Speed Profile for region of choice.

% AD - in development
% Currently configured for use with HYCOM's files

% NOTE: HYCOM data provides data points for every 1/12 degree.I believe 
% that is at most every ~9.25 km. This MIGHT allow us to see significant
% differences in sound speed across a 20-km range, but given such a low
% resolution, I think those differences will be somewhat imprecise.

clearvars
close all

%% Parameters defined by user
filePrefix = 'OS_CCE1'; % File name to match.
siteabrev = 'Global';
FilePath = 'C:\Users\HARP\Documents\MATLAB\Propagation_Modelling';
NCfilePath = [FilePath,'\',siteabrev]; %directory of TPWS files
salfile   = 'rarchv.2018_331_00_3zs.nc'; % Enter salinity file here
tempfile  = 'rarchv.2018_331_00_3zt.nc'; % Enter temperature file here
depthfile = 'rarchv.2018_331_00_3zs.nc'; % Enter depth file here

latlims = [25 45];      % Enter desired lat limits here.  Rec for WAT: 25 45
longlims = [265 280];   % Enter desired long limits here. Rec for WAT: 265 280

%% load .NC files
ncdisp([NCfilePath,'\',salfile]);
saldat = ncread([NCfilePath,'\',salfile], "salinity"); %Load salinity data
ncdisp([NCfilePath,'\',tempfile]);
tempdat = ncread([NCfilePath,'\',tempfile], "temperature"); %Load potential temperature data

saldat = flip(permute(saldat, [2 1 3 4]),1); % To make maps work, swaps lat/long and flips lat
tempdat = flip(permute(tempdat, [2 1 3 4]),1);

lattwelfths = 12*latlims;   % Multiply lat, long values to work w/ HYCOM data (data every 1/12 degree)
longtwelfths = 12*longlims; 

layer1 = saldat(longtwelfths(1):longtwelfths(2),lattwelfths(1):lattwelfths(2),1);

%% Map salinity and temperature at surface
figure(1) % Map salinity @ 1m
layersal = saldat(1:400,2550:3000,1);
heatmap(layersal, 'Colormap', turbo)
grid off

%NOTE: temperature data provides potential temperature which may not be
%what we want
figure(2) % Map potential temperature @ 1m
layertemp = tempdat(1:400,2550:3000,1);
heatmap(layertemp, 'Colormap', turbo)
grid off

%% Merge data to sound speed
% Development goal: Get 3D grid of sound speeds

maxdepth = 11;
dataset_size = (lattwelfths(2) - lattwelfths(1))*(longtwelfths(2) - longtwelfths(1))*maxdepth;

%format of saldat is lat, long, depth
%format of tempdat is lat, long, depth

%generate salinity and temperature matrices for region
saldat_reg = saldat(1:400,2550:3000,1:11);
tempdat_reg = tempdat(1:400,2550:3000,1:11);
% create analogous "depthdat"
depthdat_reg = zeros(400, 451, 11);
for i=1:maxdepth
    depthdat_reg(1:400,1:451,i) = i;
end

cdat = salt_water_c(tempdat_reg, depthdat_reg, saldat_reg);

%% Map sound speed
figure(3) % Map sound speed @ 1m
layerc = cdat(1:400,1:451,1);
heatmap(layerc, 'Colormap', turbo)
grid off

figure(4) % Map sound speed @ 10m
layerc = cdat(1:400,1:451,10);
heatmap(layerc, 'Colormap', turbo)
grid off

load('C:\Users\HARP\Documents\MATLAB\Propagation_Modelling\0001_20160201T120000');
temp_structure = D.temperature;
sal_structure = D.salinity;
temp_structure = flip(permute(temp_structure, [2 1 3]),1); % To make maps work, swaps lat/long and flips lat
sal_structure = flip(permute(sal_structure, [2 1 3]),1);
depth_structure = zeros(301, 238, 40);
for i=1:301
    for j=1:238
        depth_structure(i,j,1:40) = D.Depth;
    end
end

cdat = salt_water_c(temp_structure,depth_structure,sal_structure);

figure(5) % Sound Speed at various depths
subplot(1,4,1) % 0 m (surface)
heatmap(cdat(1:301,1:238,1), 'Colormap', turbo)
grid off
xlabel("0 m")
subplot(1,4,2) % -300 m (surface)
heatmap(cdat(1:301,1:238,25), 'Colormap', turbo)
grid off
xlabel("300 m")
subplot(1,4,3) % -600 m (surface)
heatmap(cdat(1:301,1:238,29), 'Colormap', turbo)
grid off
xlabel("600 m")
subplot(1,4,4) % -1000 m (surface)
heatmap(cdat(1:301,1:238,33), 'Colormap', turbo)
grid off
xlabel("1000 m")

Xtix = 1:238;
reducedXtix = string(Xtix);
reducedXtix(mod(Xtix,30) ~= 0) = "";
Ytix = 1:301;
reducedYtix = string(Ytix);
reducedYtix(mod(Ytix,30) ~= 0) = "";

depth0 = heatmap(cdat(1:301,1:238,1), 'Colormap', turbo);
grid off
xlabel("0 m")
depth0.XDisplayLabels = reducedXtix;
depth0.YDisplayLabels = reducedYtix;
