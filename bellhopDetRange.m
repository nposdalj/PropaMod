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

% This script will:
        % Construct sound propagation radials around your site with your
        % specified parameters
        % Save a .txt file w/ your selected parameters in Export directory
        % Save .bty, .env, .shd, and .prt files to intermediate directory
        % Move these outputs to the Export directory
        % Generate radial and polar plots and save to Export directory

clear variables
clear all
%% Define global vars
global rangeStep
global lat
global lon
global z
global lati
global loni
global rad
global radStep
global depthStep

%% Params defined by user + Info for user

% CONFIGURE PATHS - INPUT AND EXPORT
Site = 'NC';
Region = 'WAT';

%outDir = [fpath, '\Radials\', SITE]; % EDIT - Set up Google Drive folder - for loading in items and saving
bellhopSaveDir = 'C:\Users\HARP\Documents\GitHub\PropagationModeling';
Gdrive = 'I';
fpath = [Gdrive, ':\My Drive\PropagationModeling']; % Input directory
    % fpath must contain:   % bathymetry file: \Bathymetry\bathy.txt
                            % Site SSP data: \SSPs\SSP_WAT_[Site].xlsx
saveDir = [fpath, '\Radials\', Site]; % Export directory

%intermedDir = 'C:\Users\HARP\Documents\PropMod_Radials_Intermediate'; % Intermediate save directory on your local disk
intermedDir = 'C:\Users\nposd\Desktop\PropagationModelingIntermediate'; %For Natalie's computer

% SPECIFY PARAMETERS FOR INPUT
SL = 220; % Source Level
SD = 800; % Source depth
hlat = 39.8326;     % Hydrophone location params
hlon = -69.9800;
hdepth = 960;       % Unused value?

% CONFIGURE OUTPUT RANGE AND RESOLUTION
total_range = 20000;    % Radial range around your site, in meters
rangeStep = 10;         % Range resolution
radStep = 5;            % Angular resolution (i.e. angle between radials)
depthStep = 10;         % Depth resolution

% CONFIGURE PLOT OUTPUT
generate_plots = 1; % 1 = Yes, generate plots;  0 = No, do not generate plots

RL_threshold = 125; % Threshold below which you want to ignore data; will be plotted as blank (white space)

% Polar Plots
makeDepthPlots = [150, 50, 800]; % [min depth, step size, max depth]

% Radial Plots
makeRadialPlots = [0,60,300]; % [first radial to plot, step size, last radial to plot

total_range = 20000; % Desired radial range, in meters
rangeStep = 10; % Range step size, in meters
nrr = total_range/rangeStep; %total # of range step output to be saved for pDetSim
%% Bathymetry 
disp('Loading bathymetry data...') % Read in bathymetry data
tic
Bath = load([fpath, '\Bathymetry\bathy.txt']);
lon = Bath(:,2);    % vector for longitude
lat = Bath(:,1);    % vector for latitude
z = Bath(:,3);      % vector for depth (depth down is negative)
z = -z;                 % Make depth down positive
toc

%% Sound Speed Profiles
SSP_WAT = readtable([fpath, '\SSPs\SSP_WAT_MissingDepthsFilled.xlsx']);
NCSSPcoarse = [SSP_WAT.Depth SSP_WAT.NC];
idxNan = isnan(NCSSPcoarse(:, 2));
NCSSPcoarse(idxNan, :) = [];

vq = interp1(NCSSPcoarse(:, 1), NCSSPcoarse(:, 2), 1:1:NCSSPcoarse(end, 1)); % Fill in missing depths - every 1 m
NCSSP = [1:1:NCSSPcoarse(end, 1); vq]';
%% Hydrophone location and depth

% Center of source cell
hydLoc = [hlat, hlon, hdepth];

% Radial intervals and length
radials = 0:radStep:(360-radStep);                       % radials in #-degree intervals (# is in radStep)
dist = (total_range/1000);                               % distance in km to farthest point in range
distDeg = km2deg(dist);                                  % radial length in degrees

% Source Depth
disp(['Source depth: ', num2str(SD), ' m'])
RD = 0:rangeStep:1000; % Receiver depth
r = 0:rangeStep:total_range;  % range with steps
rr = r'; %output to be saved for pDetSim

%% Build Radials

disp('General setup complete. Beginning radial construction...')
tic
for rad = 1:length(radials)
    disp(['Constructing Radial ' num2str(sprintf('%03d', radials(rad))), ':'])
    
    % gives lat lon point 20 km away in the direction of radials from source center
    [latout(rad), lonout(rad)] = reckon(hydLoc(1, 1), hydLoc(1, 2), distDeg, radials(rad),'degrees');
    
    % RANGE STEP, interpolating a line from the center point to the point
    % at edge of circle
    lati(rad, :) = linspace(hydLoc(1, 1), latout(rad), length(0:rangeStep:total_range));
    loni(rad, :) = linspace(hydLoc(1, 2), lonout(rad), length(0:rangeStep:total_range));
    
    % Make bathymetry file (to be used in BELLHOP)
    disp(['Making bathymetry file for Radial ' num2str(sprintf('%03d', radials(rad))) '...'])
    tic
    [Range, bath] = makeBTY(intermedDir, ['Radial_' num2str(sprintf('%03d', radials(rad)))],latout(rad), lonout(rad), hydLoc(1, 1), hydLoc(1, 2)); % make bathymetry file
    bathTest(rad, :) = bath;
    toc
   
    % make sound speed profile the same depth as the bathymetry
    zssp = [1:1:max(bath)+1];

    ssp = NCSSP([1:length(zssp)], 2);

    % Make environment file (to be used in BELLHOP)
    disp(['Making environment file for Radial ', num2str(sprintf('%03d', radials(rad))),'...'])   % Status update
    makeEnv(intermedDir, ['Radial_' num2str(sprintf('%03d', radials(rad)))], zssp, ssp, SD, RD, length(r), r, 'C'); % make environment file
    
    % Run BELLHOP
    disp(['Running Bellhop for Radial ', num2str(sprintf('%03d', radials(rad))),'...']) % Status update
    tic
    bellhop(fullfile(intermedDir, ['Radial_' num2str(sprintf('%03d', radials(rad)))])); % run bellhop on env file
    toc
    clear Range bath
end
disp('Completed constructing all radials.')
toc
%% Copy files to final export directory
% Include a check that ensures the files in the export directory aren't screwed up...
% Since the process did take a while to run
allFiles = ls(fullfile(intermedDir,'*Radial*'));
for k = 1:length(allFiles)
    copyfile(fullfile(intermedDir,allFiles(k,:)),fullfile(fpath, 'Radials',Site,allFiles(k,:)));
    disp([allFiles(k,:), ' copied to GDrive export directory'])
end

%% Generate plots

% rd_all = zeros(1,length(radials)); %create empty array for radial depth to be used later with pDetSim
% sortedTLVec = zeros(1,length(radials)); %create empty array for transmission loss to be used later with pDetSim

% POLAR PLOTS
% join this to the loop above
for plotdepth = makeDepthPlots(1):makeDepthPlots(2):makeDepthPlots(3);
for rad = 1:length(radials)
    %iffn = fullfile(bellhopSaveDir,matFiles(rad,:));

    [ PlotTitle, PlotType, freqVec, freq0, atten, Pos, pressure ] = read_shd([intermedDir, '\', ['Radial_' num2str(sprintf('%03d', radials(rad))) '.shd']]);
    PLslice = squeeze(pressure(1, 1,:,:));
    PL = -20*log10(abs(PLslice));
    
    [x1,y1] = meshgrid(1:rangeStep:(rangeStep*size(PL,2)),1:depthStep:(depthStep*size(PL,1)));
    [xq1,yq1] = meshgrid(1:(rangeStep*size(PL,2)),1:(depthStep*size(PL,1)));
    zq = interp2(x1,y1, PL,xq1, yq1);
%     sortedTLVec(rad) = zq; %transmission loss vector to be used in pDetSim
    
    %save radial depth
    rd_inter = Pos.r.z;
%     rd_all(rad) = rd_inter; %depth array to be used in pDetSim
    
    PL800(rad, :) = zq(plotdepth, :); % PL800(mf, :) = zq(790, :); %SELECT DEPTH TO PLOT
    
    clear zq yq1 xq1 x1 y1 
    disp(['Working on Polar plot w/ Depth ' plotdepth ': Radial ' num2str(sprintf('%03d', radials(rad)))])
end

PL800(isinf(PL800)) = NaN;
PL800(PL800 > RL_threshold) = NaN; %PL800 > 125 == NaN; %AD - what is this line for
RL800 = SL - PL800;
RL800(RL800 < RL_threshold) = NaN; 

R = 1:1:length(zq(1,:));
figure(1000 + plotdepth); 
[Radiance, calbar] = polarPcolor(R, [radials 360], [RL800;NaN(1,length(zq(1,:)))], 'Colormap', jet, 'Nspokes', 7);
set(calbar,'location','EastOutside')
caxis([RL_threshold 200]); % Should remove hard coding of 200, which is the upper limit of the color bar
yticks(0:60:300)
set(get(calbar,'ylabel'),'String', ['\fontsize{10} Received Level [dB]']);
set(gcf, 'Position', [100 100 800 600])
title(['\fontsize{15}', Site, ' - ', num2str(plotdepth), ' m'],'Position',[0 -1.2])
saveas(Radiance,[fpath,'\Plots\',Site,'\',Site,'_',num2str(plotdepth),'_RadMap.png'])
disp(['Polar Radial Map saved: ', Site, ', ', num2str(plotdepth), ' m'])

end

% RADIAL PLOTS
for o = makeRadialPlots(1):makeRadialPlots(2):makeRadialPlots(3)

[ PlotTitle, PlotType, freqVec, freq0, atten, Pos, pressure ] = read_shd([bellhopSaveDir, ['\Radial_' num2str(o) '.shd']]);
PLslice = squeeze(pressure(1, 1,:,:));
PL = -20*log10(abs(PLslice));
    
[x1,y1] = meshgrid(1:rangeStep:(rangeStep*size(PL,2)),1:depthStep:(depthStep*size(PL,1)));
[xq1,yq1] = meshgrid(1:(rangeStep*size(PL,2)),1:(depthStep*size(PL,1)));
zq = interp2(x1,y1, PL,xq1, yq1);
    
figure(o+1)
RL_rad0 = SL - zq;
RL_rad0(RL_rad0 < RL_threshold) = NaN;
ye_olde_whale = pcolor(RL_rad0(:,:)); 
axis ij
set(ye_olde_whale, 'EdgeColor','none')
colormap(jet)
plotbty(['Radial_',num2str(o),'.bty'])
title([Site,' Radial', num2str(o)])
colorbar

end

test = load('NC_Radial_0.shd');
test = test.PL;

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

%% Save variables for pDetSim
freqSave = char(freqVec/1000);
save([fpath,'\DetSim_Workspace\',Site,'\',Site,'_bellhopDetRange.mat'],'rr','nrr','freqSave','hdepth');