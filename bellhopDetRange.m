% code to calculate detection range around HARP
% Vanessa ZoBell June 9, 2022
%
% Data needed to run:
% bathymetry data (sbc_bathymetry.txt)
% sound speed profiles
%
%omg
% Variables to change: 
% fpath: path to where the bellhop code is.
%   - makeBTY.m
%   - makeENV.m
%   - read_shd.m
% Bath: Path and file to your bathymetry file.
% SSP_WAT: Path and file to your sound speed profile data.
%
%
%
%
% TO DO: 
% - make radial filenames save so that there's 3 digits so they are in
% order (example 010, 020, etc)


clear variables
clear all

drive = 'P:';
fpath = [drive, '\My Drive\PropagationModeling']; %fpath = 'C:\Users\HARP\PropagationModeling'


global rangeStep
global lat
global lon
global z
global lati
global loni
global rad


SITE = 'NC';
%outDir = [fpath, '\Radials\', SITE]; % EDIT - Set up Google Drive folder - for loading in items and saving
bellhopSaveDir = 'C:\Users\HARP\Documents\GitHub\PropagationModeling';

%% Bathymetry 

% Reading in bathymetry data
disp('Loading bathymetry data...')
tic % EDIT - these can help
Bath = load([fpath, '\Bathymetry\bathy.txt']); %Bath = load('C:\Users\HARP\PropagationModeling\bathy.txt');
lon = Bath(:,2);                                        % vector for longitude
lat = Bath(:,1);                                        % vector for latitude
z = Bath(:,3);                                       % vector for depth (depth down is negative)
toc
%btyz(btyz > 0) = nan;                                   % getting rid of land
%indNan = find(isnan(btyz));
%lat(indNan) = nan;
%lon(indNan) = nan;
z = -z;                                           % making depth down  positive

% 
% S = ones(1, length(z));
% C = -z; %making color of depth for plot negative down depths
% figure
% geoscatter(lat, lon, S, -z);
% borders('continental us','FaceColor', 'black')
% 
%% Sound Speed Profiles

SSP_WAT = readtable([fpath, '\SSPs\SSP_WAT_MissingDepthsFilled.xlsx']); %EDIT -> GDrive
NCSSPcourse = [SSP_WAT.Depth SSP_WAT.NC];
idxNan = isnan(NCSSPcourse(:, 2));
NCSSPcourse(idxNan, :) = [];

vq = interp1(NCSSPcourse(:, 1), NCSSPcourse(:, 2), 1:1:NCSSPcourse(end, 1));
NCSSP = [1:1:NCSSPcourse(end, 1); vq]';


%% Hydrophone location and depth
hlat = 39.8326;
hlon = -69.9800;
hdepth = 960;


% Center of source cell
hydLoc = [hlat, hlon, hdepth];


% Radial intervals and length
radials = 0:5:355;                                       % radials in 10 degree intervals
dist = 20;                                               % distance in km to farthest point you want
distDeg = km2deg(dist);                                  % radial length in degrees
rangeStep = 10;                                          % in meters

% source depth
SD = 800;
disp(['Source depth: ', num2str(SD), ' m'])
% receiver depth
%RD = 30
% range
%R = 20000                                               % in meters
% receiver depth
RD = 0:rangeStep:1000;
% range with steps
r = 0:rangeStep:dist*1000;

disp('General setup complete. Beginning radial construction...')
for rad = 1:length(radials)
    disp(['Constructing Radial ' num2str(radials(rad)), ':'])
    
    % gives lat lon point 20 km away in the direction of radials from source center
    [latout(rad), lonout(rad)] = reckon(hydLoc(1, 1), hydLoc(1, 2), distDeg, radials(rad),'degrees');
    
    % RANGE STEP, interpolating a line from the center point to the point
    % at edge of circle
    lati(rad, :) = linspace(hydLoc(1, 1), latout(rad), length(0:rangeStep:dist*1000));
    loni(rad, :) = linspace(hydLoc(1, 2), lonout(rad), length(0:rangeStep:dist*1000));
    
    % make bathymetry file to be used in bellhop
    disp(['Making bathymetry file for Radial ' num2str(radials(rad)) '...'])
    tic
    [Range, bath] = makeBTY(bellhopSaveDir, ['Radial_' num2str(radials(rad))],latout(rad), lonout(rad), hydLoc(1, 1), hydLoc(1, 2)); % make bathymetry file
    bathTest(rad, :) = bath;
    toc
   
    % make sound speed profile the same depth as the bathymetry
    zssp = [1:1:max(bath)+1];
    
    ssp = NCSSP([1:length(zssp)], 2);
    %ssp = [NCSSP(:,2); NaN(length(zssp)-length(NCSSP),1)];%ssp = NCSSP([1:length(zssp), 2); %AD - I changed this as a workaround
    % make environment file to be used in bellhop
    disp(['Making environment file for Radial ', num2str(radials(rad)),'...'])   % Status update
    makeEnv(bellhopSaveDir, ['Radial_' num2str(radials(rad))], zssp, ssp, SD, RD, length(r), r, 'C'); % make environment file
    % running bellhop
    disp(['Running Bellhop for Radial ', num2str(radials(rad)),'...']) % Status update
    tic
    %bellhop(fullfile('C:\Users\HARP\Documents\GitHub\PropagationModeling', ['Radial_' num2str(radials(rad))])); % run bellhop on env file

    bellhop(fullfile(bellhopSaveDir, ['Radial_' num2str(radials(rad))])); % run bellhop on env file
        %NOTE: Swap fpath with outDir here
    toc
    
    %plotshd('Radial_1.shd')
    %plotbty 'Radial_1.bty'
    

    %[ PlotTitle, PlotType, freqVec, freq0, atten, Pos, pressure ] = read_shd([fpath, ['\Radial_' num2str(radials(rad)) '.shd']]);
   % PLslice = squeeze(pressure(1, 1,:,:));
   % save([outDir '\' SITE '_Radial_' num2str(radials(rad)) '.mat'], 'PL')
    % you can take this out!!^^^^ don't need to save matlab
    clear Range bath
end
disp('Completed constructing all radials.')


matFiles = ls(fullfile(bellhopSaveDir,'*Radial*.shd'));
disp('Save successful.')


size(matFiles,1)
% join this to the loop above
for rad = 1:length(radials)
   
    
    
    iffn = fullfile(bellhopSaveDir,matFiles(rad,:));

    [ PlotTitle, PlotType, freqVec, freq0, atten, Pos, pressure ] = read_shd([bellhopSaveDir, ['\Radial_' num2str(radials(rad)) '.shd']]);
    PLslice = squeeze(pressure(1, 1,:,:));
    PL = -20*log10(abs(PLslice));
    
    
        
    [x1,y1] = meshgrid(1:10:(10*size(PL,2)),1:10:(10*size(PL,1))); %10 in 1:10:(10*size(PL,2)) varies with resolution; note to self to remove hard-coding
    % [x1,y1] = meshgrid(1:100:(100*size(PL,2)),1:10:(10*size(PL,1)));
    
    [xq1,yq1] = meshgrid(1:(10*size(PL,2)),1:(10*size(PL,1))); %10 in 1:(10*size(PL,2)) varies with resolution; note to self to remove hard-coding
    % [xq1,yq1] = meshgrid(1:(100*size(PL,2)),1:(10*size(PL,1)));
    
    zq = interp2(x1,y1, PL,xq1, yq1);
    
    PL800(rad, :) = zq(790, :); % PL800(mf, :) = zq(790, :);
    
    clear zq yq1 xq1 x1 y1 
    disp(['\Radial_' num2str(radials(rad)) '.shd'])
    
end

PL800_backup = PL800;

PL800(isinf(PL800)) = NaN;
PL800(isinf(PL800)) = NaN;
PL800 > 125 == NaN; %AD - what is this line for
RL800 = 220 - PL800;
RL800(RL800 < 125) = NaN; 

R = 1:1:20010;
figure(10); 
Radiance = polarPcolor(R, radials, RL800, 'Colormap', jet);
colormap('jet')
t=colorbar;
test=flipud(colormap('jet'));
colormap(test);
set(get(t,'ylabel'),'String', ['\fontsize{10} Received Level [dB]']);





test = load('NC_Radial_0.mat')
test = test.PL

x = meshgrid(1:10:2010);
y = meshgrid(1:10:810);
v = test; 

xq = meshgrid(1:1:2000);
yq = meshgrid(1:1:800);


[x1,y1] = meshgrid(1:100:(100*size(PL,2)),1:10:(10*size(PL,1)));

[xq1,yq1] = meshgrid(1:(100*size(PL,2)),1:(10*size(PL,1)));

zq = interp2(x1,y1, PL,xq1, yq1);

PL800 = zq(790, :)
PL800(isinf(PL800)) = NaN
figure
plot(xq1, 220 - PL800)



figure
pcolor(zq);
xlim([0 20100])
ylim([0 810])
axis ij
shading interp;
xlabel('Range [m]')
ylabel('Depth [m]')
test=flipud(colormap('jet'));
colormap(zq);
t=colorbar;
set(get(t,'ylabel'),'String', ['\fontsize{10} Received Level [dB]']);


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
    plotshd('Radial_260.shd')
    plotbty 'Radial_260.bty'
    
    
    
    
    
    
plotshd('Radial_0.shd')
plotbty 'Radial_0.bty'

figure(5)
radiant = 145;
plotshd(['Radial_', num2str(radiant), '.shd'])
ylim([0 2500])
plotbty(['Radial_', num2str(radiant), '.bty'])
hold on
plot(0:2000:20000, 790, 'or')
hold off