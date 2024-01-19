function [rb, zb] = makeBATH( rlat, rlon, slat, slon,nbpts)
% JAH modified from E Snyder makeBTY 7-2021
% updated for WGS-84 ellipsoid distance 2-2022
% take source lat/lon and receiver lat/lon and make bathymetry profile
% rb = range of bathymetry
% zb = depth of bathymetry
global bathy
lat = bathy.lat;
lon = bathy.lon;
z = bathy.depth;

[r,lai,loi] = wgs84(rlat,rlon,slat,slon,nbpts);

% interp2 to extract a line of bathymetry
bathi = interp2(lat.', lon.', z.', lai, loi);
bath = - bathi;
[rb, I] = sort(r);
zb = bath(I);

