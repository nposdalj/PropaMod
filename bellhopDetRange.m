% code to calculate detection range around HARP
% Vanessa ZoBell June 9, 2022
%
% Data needed to run: 
% bathymetry data (sbc_bathymetry.txt)
% sound speed profiles
% 



clear variables





global zc
global rangeStep
global lat
global lon
global z
global lati
global loni

%% Bathymetry along Radials

% Reading in bathymetry data
Bath = load('D:\Ch.5_ShipMap\Bathymetry Data\sbc_bathymetry.txt');
lon = Bath(:,1);                                        % vector for longitude
lat = Bath(:,2);                                        % vector for latitude
z = Bath(:,3);                                       % vector for depth (depth down is negative)
%btyz(btyz > 0) = nan;                                   % getting rid of land
%indNan = find(isnan(btyz));
%lat(indNan) = nan; 
%lon(indNan) = nan; 
z = -z;                                           % making depth down  positive


S = ones(1, length(z));
C = -z; %making color of depth for plot negative down depths
%figure
%geoscatter(lat, lon, S, -btyz);
%borders('continental us','FaceColor', 'black')



hlat = 34.2755
hlon = -120.0185;

% Center of source cell
hydLoc = [34.2755, -120.0185, 565];


% Radial intervals and length
radials = 1:10:360;                                      % radials in 10 degree intervals
dist = 40;                                                % distance in km
distDeg = km2deg(dist);                                  % radial length in degrees
rangeStep = 50;

zssp = [1:1:2000]
ssp = ones(1, length(zssp))*1500
SD = 3
RD = 30
R = 40000
RD = 0:1:2000;


fpath = 'D:\Ch.5_ShipMap\PropagationModeling\Bellhop'
 for rad = 1:length(radials)


            % gives lat lon point 20 km away in the direction of radials from source center
            [latout(rad), lonout(rad)] = reckon(hydLoc(1, 1), hydLoc(1, 2), distDeg, radials(rad),'degrees');
            
            % RANGE STEP
            lati(rad, :) = linspace(hydLoc(1, 1), latout(rad), length(0:rangeStep:dist*1000));
            loni(rad, :) = linspace(hydLoc(1, 2), lonout(rad), length(0:rangeStep:dist*1000));
            
            [R, bath] = makeBTY(fpath, ['Radial_' num2str(radials(rad))],latout(rad), lonout(rad), hydLoc(1, 1), hydLoc(1, 2)); % make bathymetry file
            r = 0:rangeStep:dist*1000;
            R = r
            makeEnv(fpath, ['Radial_' num2str(radials(rad))], zssp, ssp, SD, RD, length(R), R, 'C'); % make environment file
            bellhop(fullfile(fpath, ['Radial_' num2str(radials(rad))])); % run bellhop on env file
            
            plotshd 'Radial_1.shd'
            plotbty 'Radial_1.bty'
            
 end
 