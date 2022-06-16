% plotSSP
% Plot Sound Speed Profile for region of choice.
% Configured for use with HYCOM's files
% Latitudes and longitudes are configured for Western Atlantic (WAT)

% AD: HYCOM data provides data points for every 1/12 degree. I believe 
% that is at most every ~9.25 km. This MIGHT allow us to see significant
% differences in sound speed across a 20-km range, but given such a low
% resolution, I think those differences will be somewhat imprecise.

clearvars
close all

%% Parameters defined by user
% Before running, make sure desired data has been downloaded from HYCOM
% using ext_hycom_gofs_3_1.m.
fileName = '0001_20160201T120000'; % File name to match.
siteabrev = 'WAT';
FilePath = 'C:\Users\HARP\Documents\MATLAB\Propagation_Modelling';

%% load data
load([FilePath,'\', siteabrev, '\', fileName]);
temp_frame = D.temperature;
sal_frame = D.salinity;
temp_frame = flip(permute(temp_frame, [2 1 3]),1); % To make maps work, swaps lat/long and flips lat
sal_frame = flip(permute(sal_frame, [2 1 3]),1);
depth_frame = zeros(301, 238, 40); % Generates a 3D depth frame to match with sal and temp
for i=1:301
    for j=1:238
        depth_frame(i,j,1:40) = D.Depth;
    end
end

cdat = nan(301,238,40); % Generates an empty frame to input sound speeds
for i=1:(301*238*40) % Only adds sound speed values ABOVE the seafloor
    if temp_frame(i) ~= 0 & sal_frame(i) ~= 0
        cdat(i) = salt_water_c(temp_frame(i),depth_frame(i),sal_frame(i)); % Sound Speed data
    end
end

%% Plot sound speed by depth

Xtix = D.Longitude; % Adjust plot tick marks (found this code somewhere on google, as always)
reducedXtix = string(Xtix);
reducedXtix(mod(Xtix,1) ~= 0) = "";
Ytix = flip(D.Latitude);
reducedYtix = string(Ytix);
reducedYtix(mod(Ytix,1) ~= 0) = "";

% MAKE FIGURE
figure(5) % Sound Speed at various depths
subplot(1,4,1)                                      % 0M, SURFACE
depthlevel = heatmap(cdat(:,:,1), 'Colormap', turbo);
grid off
title("0 m")
depthlevel.XDisplayLabels = reducedXtix;
depthlevel.YDisplayLabels = reducedYtix;
subplot(1,4,2)                                      % -300M
depthlevel = heatmap(cdat(:,:,25), 'Colormap', turbo);
grid off
title("300 m")
depthlevel.XDisplayLabels = reducedXtix;
depthlevel.YDisplayLabels = reducedYtix;
subplot(1,4,3)                                      % -600M
depthlevel = heatmap(cdat(:,:,29), 'Colormap', turbo);
grid off
title("600 m")
depthlevel.XDisplayLabels = reducedXtix;
depthlevel.YDisplayLabels = reducedYtix;
subplot(1,4,4)                                      % -1000M
depthlevel = heatmap(cdat(:,:,33), 'Colormap', turbo);
grid off
title("1000 m")
depthlevel.XDisplayLabels = reducedXtix;
depthlevel.YDisplayLabels = reducedYtix;

%% Plot sound speed profiles by longitude line slices

cdat_slice = permute(cdat, [3 1 2]); % Place depth in first position (y), latitude in second position (x)
depthlist = abs(transpose(D.Depth)); % List of depth values to assign to the y's in cdat_slice

Xtix = flip(D.Latitude); % Adjust plot tick marks (found this code somewhere on google, as always)
reducedXtix = string(Xtix);
reducedXtix(mod(Xtix,1) ~= 0) = "";
Ytix = 1:5000;
reducedYtix = string(Ytix);
reducedYtix(mod(Ytix,500) ~= 0) = "";

%MAKE FIGURE
long = 190; % User-selected parameter! Longitude line along which to cut
figure(5000 + long)
longcut_table = cdat_slice(:,:,long);
longcut_table(longcut_table(:,:)==0) = NaN;
[latq, depthq] = meshgrid(1:1:301,1:1:5000);
longcut_table = interp2((1:301).', (depthlist).', longcut_table, latq, depthq);
longcut = heatmap(longcut_table, 'Colormap', turbo);
%longcut = heatmap(cdat_cut(1:5000,1:301,long), 'Colormap', turbo);
grid off
longcut.XDisplayLabels = reducedXtix;
longcut.YDisplayLabels = reducedYtix;
xlabel("Latitude (degrees N)")
ylabel("Depth (m)")
title("Longitude Line 190(?)")
