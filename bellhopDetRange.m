% code to calculate detection range around HARP
% Vanessa ZoBell June 9, 2022
% Edited by AD and NP
%
% Data needed to run:
% bathymetry data (sbc_bathymetry.txt)
% sound speed profiles
%
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
% These are being called in the loop but are not functions
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
% bellhopSaveDir = 'C:\Users\HARP\Documents\GitHub\PropagationModeling'; %Aaron's Computer
bellhopSaveDir = 'E:\BellHopOutputs'; %Natalie's Computer
Gdrive = 'I';
fpath = [Gdrive, ':\My Drive\PropagationModeling']; % Input directory
    % fpath must contain:   % bathymetry file: \Bathymetry\bathy.txt
                            % Site SSP data: \SSPs\SSP_WAT_[Site].xlsx
saveDir = [fpath, '\Radials\', Site]; % Export directory

% SPECIFY PARAMETERS FOR INPUT
SL = 220; % Source Level
SD = 800; % Source depth
hlat = 39.8326; % hydrophone lat
hlon = -69.9800; % hydrophone long
hdepth = 960; % hydrophone depth
freq = 12000; % frequency of source

% CONFIGURE OUTPUT RANGE AND RESOLUTION
total_range = 40000;    % Radial range around your site, in meters
rangeStep = 10;         % Range step size (m)
radStep = 5;            % Angular resolution (i.e. angle between radials)
depthStep = 10;         % Depth resolution
nrr = total_range/rangeStep; %total # of range step output to be saved for pDetSim

% CONFIGURE PLOT OUTPUT
generate_PolarPlots = 1; % 1 = Yes, generate polar plots;  0 = No, do not generate polar plots
generate_RadialPlots = 1;

RL_threshold = 125; % Threshold below which you want to ignore data; will be plotted as blank (white space)

% Polar Plots
makeDepthPlots = [150, 50, 800]; % [min depth, step size, max depth] - we should try deeper than 800...maybe 1200m?

% Radial Plots
numRadial_Plot = 4; % make it so the user only has to choose the number of radial plots they want
% vvvv move this to the radial plot section and don't hard code it
makeRadialPlots = [0,60,300]; % [first radial to plot, step size, last radial to plot] can you add some more notes about this one please?
%% Make new folder w/in bellhopSaveDir for this run's files
timestamp_currentrun = datestr(datetime('now'), 'yymmddHHMMSS');
intermedDir = [bellhopSaveDir, '\' timestamp_currentrun];
mkdir(intermedDir);
% This prevents file overwriting, if you are running bellhopDetRange.m multiple
% times in parallel on the same computer.
%% Save User-input params to a text file; move this after SSP and include SSP that was inputted into that run (file name and the actual SSP)
paramfile = fullfile(intermedDir, [timestamp_currentrun,'_Input_Parameters.txt']);
fileid = fopen(paramfile, 'at');
fprintf(fileid, ['User Input Parameters for Run ' timestamp_currentrun...
    '\n\nSite\t' Site '\nRegion\t' Region ...
    '\n\nHYDROPHONE PARAMETERS\nSL\t' num2str(SL) '\nSD\t' num2str(SD) '\nhlat\t' num2str(hlat) '\nhlon\t' num2str(hlon) '\nhdepth\t' num2str(hdepth)...
    '\n\nRANGE & RESOLUTION\nRange\t' num2str(total_range) '\nRange Step\t' num2str(rangeStep) '\nRad Step\t' num2str(radStep) '\nDepth Step\t' num2str(depthStep)...
    '\n\nPLOT GENERATION\nGenerate Plots\t' num2str(generate_plots) '\nRL Threshold\t' num2str(RL_threshold) '\nDepth Levels\t' num2str(makeDepthPlots) '\nRadial Plots\t' num2str(makeRadialPlots)]);
fclose(fileid);
%% Bathymetry 
disp('Loading bathymetry data...') % Read in bathymetry data
tic
Bath = load([fpath, '\Bathymetry\bathy.txt']);
lon = Bath(:,2);    % vector for longitude
lat = Bath(:,1);    % vector for latitude
z = Bath(:,3);      % vector for depth (depth down is negative)
z = -z;             % Make depth down positive
toc
%% Sound Speed Profiles
SSP_TABLE = readtable([fpath, '\SSPs\SSP_WAT_MissingDepthsFilled.xlsx']); % read the SSP file
NCSSPcoarse = [SSP_TABLE.Depth SSP_TABLE.(Site)]; % pull out the SSP for the specific site of interest 
idxNan = isnan(NCSSPcoarse(:, 2)); %identify any NANs
NCSSPcoarse(idxNan, :) = []; %remove NANs

vq = interp1(NCSSPcoarse(:, 1), NCSSPcoarse(:, 2), 1:1:NCSSPcoarse(end, 1)); % Fill in missing depths - every 1 m
NCSSP = [1:1:NCSSPcoarse(end, 1); vq]';
%% Hydrophone location and depth
% Center of source cell
hydLoc = [hlat, hlon, hdepth];

% Radial intervals and length
radials = 0:radStep:(360-radStep);  % radials in #-degree intervals (# is in radStep)
% ^ we should do this in a way where you can specify the number of radials
% you want and then it does this calculation for the range steps after that
dist = (total_range/1000);          % distance in km to farthest point in range
distDeg = km2deg(dist);             % radial length in degrees

% Source Depth
disp(['Source depth: ', num2str(SD), ' m'])
RD = 0:rangeStep:1000;              % Receiver depth (it's set to a 1000 here, but in the 'Build Radial' loop, RD goes to the maximum depth of the bathymetry
r = 0:rangeStep:total_range;        % range with steps
rr = r';                            % output to be saved for pDetSim
%% Build Radials
% Note: this loop will re-write the existing files in the folder if you do not
% create a subfolder using the above section of the code

disp('General setup complete. Beginning radial construction...')
tic
for rad = 1:length(radials)
    disp(['Constructing Radial ' num2str(sprintf('%03d', radials(rad))), ':'])
    
    % gives lat lon point total range (km) away in the direction of radials from source center
    [latout(rad), lonout(rad)] = reckon(hydLoc(1, 1), hydLoc(1, 2), distDeg, radials(rad),'degrees');
    
    % RANGE STEP, interpolating a line from the center point to the point
    % at edge of circle
    lati(rad, :) = linspace(hydLoc(1, 1), latout(rad), length(0:rangeStep:total_range));
    loni(rad, :) = linspace(hydLoc(1, 2), lonout(rad), length(0:rangeStep:total_range));
    
    % Make bathymetry file (to be used in BELLHOP)
    disp(['Making bathymetry file for Radial ' num2str(sprintf('%03d', radials(rad))) '...'])
    tic
    [Range, bath] = makeBTY(intermedDir, ['Radial_' num2str(sprintf('%03d', radials(rad)))],latout(rad), lonout(rad), hydLoc(1, 1), hydLoc(1, 2)); % make bathymetry file
    bathTest(rad, :) = bath; % this is only used to plot the bathymetry if needed 
    RD = 0:rangeStep:max(bath); % Re-creates the variable RD to go until the max depth of this specific radial
    toc
   
    % make sound speed profile the same depth as the bathymetry
    zssp = [1:1:max(bath)+1];
    ssp = NCSSP([1:length(zssp)], 2);

    % Make environment file (to be used in BELLHOP)
    disp(['Making environment file for Radial ', num2str(sprintf('%03d', radials(rad))),'...'])   % Status update
    makeEnv(intermedDir, ['Radial_' num2str(sprintf('%03d', radials(rad)))], freq, zssp, ssp, SD, RD, length(r), r, 'C'); % make environment file
    
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
saveDir_sub = [saveDir, '\' timestamp_currentrun];
mkdir(saveDir_sub);
for k = 1:length(allFiles)
    copyfile(fullfile(intermedDir,allFiles(k,:)),fullfile(saveDir_sub, allFiles(k,:)));
    disp([allFiles(k,:), ' copied to new subfolder in GDrive export directory'])
end
copyfile(paramfile,fullfile(saveDir_sub, [timestamp_currentrun,'_Input_Parameters.txt']))
%% Generate plots
if generate_plots == 1
    
fpath_plotSub = [fpath, '\Plots\' Site '\' timestamp_currentrun];
mkdir(fpath_plotSub);

% POLAR PLOTS
% join this to the loop above keep the if generate plot check
disp(['Now generating polar plots between depths ' num2str(makeDepthPlots(1)) 'm and ' ...
    num2str(makeDepthPlots(3)) 'm, with interval ' num2str(makeDepthPlots(2)) 'm'])
pause(1)
for plotdepth = makeDepthPlots(1):makeDepthPlots(2):makeDepthPlots(3);
for rad = 1:length(radials)
    [PlotTitle, PlotType, freqVec, freq0, atten, Pos, pressure] = read_shd([intermedDir, '\', ['Radial_' num2str(sprintf('%03d', radials(rad))) '.shd']]);
    PLslice = squeeze(pressure(1, 1,:,:));
    PL = -20*log10(abs(PLslice));
    
    [x1,y1] = meshgrid(1:rangeStep:(rangeStep*size(PL,2)),1:depthStep:(depthStep*size(PL,1)));
    [xq1,yq1] = meshgrid(1:(rangeStep*size(PL,2)),1:(depthStep*size(PL,1)));
    zq = interp2(x1,y1, PL,xq1, yq1);
    
    %save radial depth
    rd_inter = Pos.r.z;
    
    PL800(rad, :) = zq(plotdepth, :);
    
    clear zq yq1 xq1 x1 y1 
    disp(['Working on Polar plot w/ Depth ' num2str(plotdepth) ': Radial ' num2str(sprintf('%03d', radials(rad)))])
end

PL800(isinf(PL800)) = NaN;
PL800(PL800 > RL_threshold) = NaN; %PL800 > 125 == NaN; %AD - what is this line for
RL800 = SL - PL800;
RL800(RL800 < RL_threshold) = NaN; 

R = 1:1:length(RL800(1,:));
figure(1000 + plotdepth)
[Radiance, calbar] = polarPcolor(R, [radials 360], [RL800;NaN(1,length(RL800(1,:)))], 'Colormap', jet, 'Nspokes', 7);
set(calbar,'location','EastOutside')
caxis([RL_threshold 200]); % Should remove hard coding of 200, which is the upper limit of the color bar change variable to indicate that this is the max expected RL
yticks(0:60:300)
set(get(calbar,'ylabel'),'String', ['\fontsize{10} Received Level [dB]']);
set(gcf, 'Position', [100 100 800 600])
title(['\fontsize{15}', Site, ' - ', num2str(plotdepth), ' m'],'Position',[0 -1.2])
saveas(Radiance,[fpath_plotSub,'\',Site,'_',num2str(plotdepth),'_RadMap.png'])
disp(['Polar Radial Map saved: ', Site, ', ', num2str(plotdepth), ' m'])

end

% RADIAL PLOTS
for o = makeRadialPlots(1):makeRadialPlots(2):makeRadialPlots(3)
[PlotTitle, PlotType, freqVec, freq0, atten, Pos, pressure ] = read_shd([intermedDir, ['\Radial_' num2str(sprintf('%03d', radials(rad)) '.shd']]);
PLslice = squeeze(pressure(1, 1,:,:));
PL = -20*log10(abs(PLslice));
    
[x1,y1] = meshgrid(1:rangeStep:(rangeStep*size(PL,2)),1:depthStep:(depthStep*size(PL,1)));
[xq1,yq1] = meshgrid(1:(rangeStep*size(PL,2)),1:(depthStep*size(PL,1)));
zq = interp2(x1,y1, PL,xq1, yq1);
    
figure(2000+o)
RL_rad0 = SL - zq;
RL_rad0(RL_rad0 < RL_threshold) = NaN;
ye_olde_whale = pcolor(RL_rad0(:,:)); 
axis ij
set(ye_olde_whale, 'EdgeColor','none')
colormap(jet)
plotbty(['Radial_',num2str(o),'.bty'])
title([Site,' Radial', num2str(o)])
colorbar
saveas(ye_olde_whale,[fpath_plotSub,'\',Site,'_',num2str(o),'_RadMap.png'])
end
else
end
%% Save variables for pDetSim
freqSave = char(freqVec/1000);
save([fpath,'\DetSim_Workspace\',Site,'\',Site,'_bellhopDetRange.mat'],'rr','nrr','freqSave','hdepth');

% Whale? Yes