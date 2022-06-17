% code to calculate detection range around HARP
% Vanessa ZoBell June 9, 2022
%
% Data needed to run:
% bathymetry data (sbc_bathymetry.txt)
% sound speed profiles
%



clear variables
clear all


global zc
global rangeStep
global lat
global lon
global z
global lati
global loni
global rad


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
radials = 0:10:350;                                      % radials in 10 degree intervals
dist = 40;                                                % distance in km
distDeg = km2deg(dist);                                  % radial length in degrees
rangeStep = 100;


SD = 3
RD = 30
R = 40000
RD = 0:1:2000;
r = 0:rangeStep:dist*1000;


fpath = 'C:\Users\HARP\Documents\GitHub\PropagationModeling'
for rad = 1:length(radials)
    
    
    % gives lat lon point 20 km away in the direction of radials from source center
    [latout(rad), lonout(rad)] = reckon(hydLoc(1, 1), hydLoc(1, 2), distDeg, radials(rad),'degrees');
    
    % RANGE STEP
    lati(rad, :) = linspace(hydLoc(1, 1), latout(rad), length(0:rangeStep:dist*1000));
    loni(rad, :) = linspace(hydLoc(1, 2), lonout(rad), length(0:rangeStep:dist*1000));
    
    [Range, bath] = makeBTY(fpath, ['Radial_' num2str(radials(rad))],latout(rad), lonout(rad), hydLoc(1, 1), hydLoc(1, 2)); % make bathymetry file
    bathTest(rad, :) = bath;
    zssp = [1:1:max(bath)+1];
    ssp = ones(1, length(zssp))*1500;
    makeEnv(fpath, ['Radial_' num2str(radials(rad))], zssp, ssp, SD, RD, length(r), r, 'C'); % make environment file
    bellhop(fullfile(fpath, ['Radial_' num2str(radials(rad))])); % run bellhop on env file
    
    %plotshd('Radial_1.shd')
    %plotbty 'Radial_1.bty'
    clear Range bath
end

freq = 12000
[ PlotTitle, PlotType, freqVec, freq0, atten, Pos, pressure ] = read_shd( 'Radial_10.shd', freq );
%    Reads source at the specified frequency.
test = pressure(1, 1, :, :);


freq = 12000
[ PlotTitle, PlotType, freqVec, freq0, atten, Pos, pressure ] = read_shd( 'Radial_10.shd', freq );

test = squeeze(pressure(1, 1,:,:));
PL = -20*log10(abs(test));
PL(isinf(PL)) = 2000



figure
pcolor(220 - PL);
xlim([0 401])
ylim([0 800])
axis ij
shading interp;
xlabel('Range [m]')
ylabel('Depth [m]')
test=flipud(colormap('jet'));
colormap(test);
t=colorbar;
set(get(t,'ylabel'),'String', ['\fontsize{10} Received Level [dB]']);
caxis([20 120])

plot(pressure(1, 1, :, :))
figure
    plotshd('Radial_50.shd')
    plotbty 'Radial_50.bty'