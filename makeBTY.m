function [Range, bath] = makeBTY(fpath, fname, slat, slon, hlat, hlon)
% VZ: Modified from Eric Snyder's makeBTY.m code
% NOTE: I'm using the hydrophone as the source and ship as receiver for now
global rangeStep
global lat
global lon
global z
global lati
global loni
global rad



%% Parameters for testing function
% slat = 29.2570;
% slon = -88.1003;

% hlat = 28 + 58.732/60;
% hlon = -(88 + 28.082/60);

% r = sqrt( (slat-hlat)^2 + (slon-hlon)^2); 
% theta = atand((slat-hlat)/(slon-hlon));

% rdes = r*1.3;

% slat = rdes*sind(theta)+hlat; 
% slon = rdes*cosd(theta)+hlon; % just extends lat/lon out a little

% fpath = 'D:\GOM\createModelParametersForBellhop\bath_2D\models';
% fname = 'GOM';




%% interpolate w/ interp2 to extract a line of bathymetry?

fpn = fullfile(fpath, [fname, '.bty']);

% lati = linspace(hlat, slat, length(0:rangeStep:dist*1000));
% loni = linspace(hlon, slon, length(0:rangeStep:dist*1000));


[xi, yi] = latlon2xy(lati(rad, :), loni(rad, :), hlat, hlon);

ri = sqrt(xi.^2 + yi.^2)./1000;

%bathi = interp2(lat.', lon.', z.', lati, loni);
bathi = griddata(lat, lon, z, lati(rad, :), loni(rad, :), 'linear');

Range = ri.';
bath = abs(bathi).';

[Rsort, I] = sort(Range);
bathSort = bath(I);

writebdry( fpn, 'C', ([Rsort, bathSort]) ) % write bty file

%% Plot (for testing)
% 
% Nlat = find(lat>hlat-.2 & lat<slat+.2);
% Nlon = find(lon>hlon-.2 & lon<slon+.2);
% 
% figure
% 
% plot3(loni, lati, bathi, 'linewidth', 1.5)
% hold on
% plot3(hlon, hlat, -750, 'r^')
% plot3(slon, slat, -10, 'rx')
% surf( lon(Nlon), lat(Nlat), z(Nlat, Nlon))
% colormap winter
% shading interp
% hold off
% title('Extracted bathymetry between source and receiver')
% legend('interpolated bathy line', 'hydrophone', 'ship location')