% code to calculate detection range around HARP
% AD and NP
%
% Data needed to run:
% - Sound speed profiles

% This script will:
% Construct sound propagation radials around your site with your specified parameters
% Save a .txt file w/ your selected parameters in Export directory and plot directory
% Save .bty, .env, .shd, and .prt files to intermediate directory
% Move these outputs to the Export directory
% Generate radial and polar plots and save to Export directory

clearvars % clear variables
close all;clear all;clc; % clear all
%% 1. Define global vars
% These are being called in the loop but are not functions
global rangeStep
global lati
global loni
global rad
global radStep
global depthStep
%% 2. Params defined by user + Info for user
author = 'NP'; % Your name/initials here. This will be included in the .txt output.
userNote = ' HZ, Mid-Size'; % Include a note for yourself/others. This will be included in the .txt output.

% A. CONFIGURE PATHS - INPUT AND EXPORT
Site = 'HZ';
Region = 'WAT';
BathyRegion = 'WAT'; % If your site is outside of the Western Atlantic, change this to GlobalCoverage

%bellhopSaveDir = 'C:\Users\HARP\Documents\PropMod_Intermed'; %Aaron's Computer % Intermediate save directory on your local disk
bellhopSaveDir = 'I:\BellHopOutputs'; %Natalie's Computer % Intermediate save directory on your local disk
Gdrive = 'G';

fpath = [Gdrive, ':\My Drive\PropagationModeling']; % Input directory
% fpath must contain:   - bathymetry file: \Bathymetry\bathy.txt
%                       - site SSP data: \SSPs\SSP_WAT_[Site].xlsx
%                       - sediment data*: \Sediment_Data\...
%                           Sediment data is optional, required only if modeling bottom using grain size. SEE WIKI FOR FOLDER CONFIGURATION.
saveDir = [fpath, '\Radials\', Site]; % Export directory % < This line should be unused now
%GEBCODir = [Gdrive,':\My Drive\PropagationModeling_GDrive']; %GEBCO bathymetry netCDF file
GEBCODir = 'I:\BellHopOutputs'; %local GEBCO bathymetry netCDF file

% Note to self to have smth in plotSSP that exports the examined effort period
% and other relevant details so they can be exported in the info file here

% B. SPECIFY MODEL INPUT PARAMETERS: Hydrophone Location, Source Level, and Source Frequency.
hlat = 41.062; % hydrophone lat
hlon = -66.352; % hydrophone long
hdepth = 903;   % hydrophone depth % <- inputted into DetSim_Workspace
SL = 230;       % Source Level
freq = {10000};  % Frequencies of sources, in Hz. Enter up to 3 values.

% C. SSP TYPE: Indicate the type of SSP you want to use.
SSPtype = 'Mean'; % 'Mean' = Overall mean; 'Mmax' = Month w/ max SS; 'Mmin' = Month w/ min SS.

% D. SPECIFY SEA FLOOR MODEL
botModel = 'Y'; % 'A' = Model bottom as Acousto Elastic Half-Space; manually enter parameters. SEE D.i.
%               % 'G' = Model bottom using grain size. SEE D.ii.
%               % 'Y' = Model bottom as Acousto Elastic Half-Space; Calculate
%               %       parameters with grain size and Algorithm Y. SEE D.ii.

% D.i. If modeling bottom using Acousto Elastic Half-Space, modify the following properties
%      (required for makeEnv.m to run, if botModel = 'A'):
% AEHS.compSpeed = 1500; % 1470.00;   % Compressional speed % No longer used - Sound speed at seafloor at site is now used instead
% This is now determined within the radial loop, during the first radial, along with Source Depth (SD)
AEHS.shearSpeed = 150;  % 146.70;   % Shear speed
AEHS.density = 1.7;  %1.15;        % Density.
%   This value (1.7 g/cm^3) was chosen based on the average density of
%   marine sediments found by Tenzer and Gladkikh (2014).
AEHS.compAtten = 0.1;    %0.0015;    % Compressional attenuation
AEHS.shearAtten = 0.0000;   % Shear attenuation

% D.ii If modeling bottom using Acousto Elastic Half-Space, modify the following properties
%        (required for makeEnv.m to run if botModel = 'Y'
SedDep = 3; %sediment depth you expect for shear velocity calculations (3m = surficial sediment)

% D.ii. If modeling bottom using grain size, select which dataset to use:
sedDatType = 'B'; % 'B' = BST data; 'I' = IMLGS data.
forceLR = 1; % If using BST data, set 0 to use high-res data where possible; 1, use low-res always

% E. CONFIGURE MODEL OUTPUT: RANGE AND RESOLUTION
total_range = 40000;    % Radial range around your site, in meters
rangeStep = 10;         % Range resolution
depthStep = 10;         % Depth resolution
numRadials = 36;        % Specify number of radials - They will be evenly spaced.
%   Keep in mind, 360/numRadials = Your angular resolution.
nrr = total_range/rangeStep; %total # of range step output to be saved for pDetSim

% F. CONFIGURE PLOT OUTPUT
generate_RadialPlots = 0; % Generate radial plots? 1 = Yes, 0 = No
generate_PolarPlots = 0; % Generate polar plots? 1 = Yes, 0 = No

RL_threshold = 125; % Threshold below which you want to ignore data; will be plotted as blank (white space)
RL_plotMax = 200; % Colorbar maximum for plots; indicates that this is the max expected RL

% Polar Plots
makePolarPlots = [150, 50, 1200]; % [min depth, step size, max depth] - we should try deeper than 800...maybe 1200m?
% Radial plots are automatically generated for every radial

% G. SPECIAL CONDITION: Oops, the run did not finish all the radials!
%       This often occurs when this program causes the computer to run out of memory.
%       (1) First, RUN SECTIONS 8-10 MANUALLY to save your parameter file and the
%           DetSim_Workspace generated so far.
%       (2) Then, change resumeRun from 0 to 1 below and enter the radial to resume on.
resumeRun = 0;  % 1 = Resume run from a specified radial; 0 = Start new run from first radial.
resumeRad = 6; % This value is only used if resumeRun == 1.
%       For this "resumed" run, completely new run folders will be generated, as
%       well as a new DetSim_Workspace. You will need to combine the two
%       DetSim_Workspaces manually before running pDetSim_constructWS.
%% 3. Make new folders for this run's files
% This step prevents file overwriting, if you are running bellhopDetRange.m
% multiple times in parallel on the same computer (or across devices).

runDate = char(datetime('now', 'Format', 'yyMMdd'));
existingDirs = string(ls(saveDir)); % Check what folder names already exist in the final save directory
existingDirs(1:2) = []; % delete first two rows
existingDirs = existingDirs(contains(existingDirs, runDate), :); % Only consider folder names with today's date
% Code refers to saveDir instead of bellhopSaveDir to check for folders
% other users may have generated today.

dailyFolderNum = double('a');
if ~isempty(existingDirs)
    for k = 1:height(existingDirs)
        if contains(existingDirs(k),char(dailyFolderNum)) == 1
            dailyFolderNum = dailyFolderNum + 1;
            % Starting from "a", go through characters until first one that isn't in a folder name from today is reached
        end
    end
end
if dailyFolderNum == 123    % This is the double value of {, which comes after z (double value 122)
    disp('Max daily limit of 26 runs has been reached. To make a new one, delete a run from today from the GDrive save directory.')
    beep
    return
else % If there is still room for more run folders for today, make new directories.
    newFolderName = [runDate char(dailyFolderNum)];

    midDir = [bellhopSaveDir, '\', Site, '\', newFolderName];
    mkdir(midDir)
    midDirF1 = [midDir '\' num2str(freq{1}/1000) 'kHz']; mkdir(midDirF1); % Local subdirectory for 1st freq

    saveDir_sub = [saveDir '\', newFolderName];          % Final save directory [GDrive]
    mkdir(saveDir_sub);
    saveDir_subF1 = [saveDir_sub '\' num2str(freq{1}/1000) 'kHz']; mkdir(saveDir_subF1); % Save subdirectory for 1st freq

    plotDir = [fpath, '\Plots\' Site '\' newFolderName]; % Plot save directory [GDrive]
    mkdir(plotDir);
    plotDirF1 = [plotDir '\' num2str(freq{1}/1000) 'kHz']; mkdir(plotDirF1); % Plot subdirectory for 1st freq

    if length(freq) >= 2    % Create subdirectories for second frequency, if applicable.
        midDirF2 = [midDir '\' num2str(freq{2}/1000) 'kHz']; mkdir(midDirF2); % Local subdirectory for 2nd freq
        saveDir_subF2 = [saveDir_sub '\' num2str(freq{2}/1000) 'kHz']; mkdir(saveDir_subF2); % Save subdirectory for 2nd freq
        plotDirF2 = [plotDir '\' num2str(freq{2}/1000) 'kHz']; mkdir(plotDirF2); % Plot subdirectory for 2nd freq
    end
    if length(freq) >= 3    % Create subdirectories for third frequency, if applicable.
        midDirF3 = [midDir '\' num2str(freq{3}/1000) 'kHz']; mkdir(midDirF3); % Local subdirectory for 3rd freq
        saveDir_subF3 = [saveDir_sub '\' num2str(freq{3}/1000) 'kHz']; mkdir(saveDir_subF3); % Save subdirectory for 3rd freq
        plotDirF3 = [plotDir '\' num2str(freq{3}/1000) 'kHz']; mkdir(plotDirF3); % Plot subdirectory for 3rd freq
    end
end
%% 4. Sound Speed Profiles
SSPfolder = ls(fullfile(fpath,'SSPs',Region,Site));          % Get list of files in SSP folder
SSPfolderIdx = find(contains(string(SSPfolder),SSPtype) & ~contains(string(SSPfolder), "$"));
% Index of desired SSP file based on user input. MODIFIED TO IGNORE TEMPORARY FILES.
SSPfile = strtrim(SSPfolder(SSPfolderIdx,:));                % Get that SSP file
SSP = readtable(fullfile(fpath,'SSPs',Region,Site,SSPfile)); % read the SSP file
SSParray = table2array(SSP);  % Convert to array

if strcmp(SSPtype, 'Mmax') || strcmp(SSPtype, 'Mmin') % Get month being examined to report in the output info file, if applicable
    SSPmoReporting = num2str(SSPfile(12:13));
elseif strcmp(SSPtype, 'Mean')
    SSPmoReporting = 'Not applicable'; % If using mean SSP, then report "Not applicable"
end
%% 5. Hydrophone location and depth
% Center of source cell
hydLoc = [hlat, hlon, hdepth];

% Radial intervals and length
radStep = 360/numRadials;           % Angular resolution (i.e. angle between radials)
radials = 0:radStep:(360-radStep);  % radials in #-degree interval (# is in radStep)
dist = (total_range/1000);          % distance in km to farthest point in range
distDeg = km2deg(dist);             % radial length in degrees

% Reciever Depth
RD = 0:rangeStep:1000;              % Receiver depth (it's set to a 1000 here, but in the 'Build Radial' loop, RD goes to the maximum depth of the bathymetry
r = 0:rangeStep:total_range;        % range with steps                         

% Source Depth is set it to be the depth at hlat and hlon, - 10 m.
% This simulates a hydrophone sitting 10 m off of the bottom.
% This calculation is made after the bathymetry is generated by makeBTY (within the big loop).
% It is only calculated once, during the generation of the first radial.

%5a. Load GEBCO data once
distDec = dist*0.08; %convert distance from km to degrees
hlat_range = [hlat+distDec hlat-distDec];
hlon_range = [hlon+distDec hlon-distDec];
AllVariables = loadBTY(distDec,hlat_range,hlon_range,GEBCODir);
%% 6G. Retrieve sediment data (if needed) and pack bottom parameters
if botModel == 'G' || botModel == 'Y' % For bottom models requiring grain size...
    sedPath = [fpath '\Sediment_Data']; % Path where sediment data are located
    if sedDatType == 'I' % If using IMLGS data...
        imlgs2hfeva_WAT(sedPath) % Run imlgs2hfeva_WAT on the IMLGS data first to translate it to HFEVA types
        % I wonder if this part should be removed... it only ever needs to be run once
    end
    radGrainSize = getGrainSize(sedDatType, sedPath, hydLoc, distDeg, total_range, radials, plotDir, rangeStep, forceLR);
end
%% 6. Build Radials
% Note: this loop will re-write the existing files in the folder if you do not
% create a subfolder using the above section of the code (Section 3)

botDepthSort = []; %create empty array for bottom depth sorted by radials for pDetSim
disp('General setup complete. Beginning radial construction...')

if resumeRun == 1 % Choose start radial based on whether user requested to resume a run or not
    startRad = resumeRad;
else
    startRad = 1;
end

bathyTimes = nan(rad, 1); % List of durations of bathymetry file section
blhopTimes = nan(rad, 1); % List of durations of bellhop section
for rad = startRad:length(radials)
    disp(['Constructing Radial ' num2str(sprintf('%03d', radials(rad))), ':'])

    %% 6.1 Create radial line
    % gives lat lon point total range (km) away in the direction of radials from source center
    [latout(rad), lonout(rad)] = reckon(hydLoc(1, 1), hydLoc(1, 2), distDeg, radials(rad),'degrees');

    % RANGE STEP, interpolating a line from the center point to the point
    % at edge of circle
    lati(rad, :) = linspace(hydLoc(1, 1), latout(rad), length(0:rangeStep:total_range));
    loni(rad, :) = linspace(hydLoc(1, 2), lonout(rad), length(0:rangeStep:total_range));

    %% 6.2 Make bathymetry file (to be used in BELLHOP)
    disp(['Making bathymetry file for Radial ' num2str(sprintf('%03d', radials(rad))) '...'])

    tBegin = tic;
    radialiChar = num2str(sprintf('%03d', radials(rad))); % Radial number formatted for file names
    [~, bath] = makeBTY(midDir, ['R' radialiChar],hydLoc(1, 1), hydLoc(1, 2),AllVariables); % make bathymetry file in intermed dir Freq 1
    %[~, bath] = makeBTY_old(midDir, ['R' radialiChar],latout(rad), lonout(rad), hydLoc(1, 1), hydLoc(1, 2),GEBCODir); % make bathymetry file in intermed dir Freq 1
    % The line above causes memory to climb, but ultimately it seems to go back down.
    % Within the frequency loop, this .bty file is copied to the intermed
    % frequency subdirectories and to the save directories

    %bathTest(rad, :) = bath; % this is only used to plot the bathymetry if needed

    % DECIDE SD AND AEHS.COMPSPEED FOR ALL RADIALS (This is done during the first radial)
    if rad == 1 % If this is currently running the first radial...
        SiteDepth = bath(1); % set the first value in the bathymetry as the depth of the site.
        SD = SiteDepth - 10; % Set Source Depth (SD) as 10 m above the sea floor.

        Seafloor_SoundSpeed = SSP.SS(find(SSP.Depth == round(SiteDepth))); % Find soundspeed at seafloor depth of site
        AEHS.compSpeed = Seafloor_SoundSpeed; % Set this as the compressional speed for the seafloor AEHS.
    end

    RD = 0:rangeStep:max(bath); % Re-creates the variable RD to go until the max depth of this specific radial
    bathyTimes(rad) = toc(tBegin);

    botDepthSort(rad,:) = bath'; %save bottom depth sorted by radial for pDetSim

    % make sound speed profile the same depth as the bathymetry
    zssp = 1:1:max(bath)+1;
    ssp = SSParray(1:length(zssp), 2);

    %% Begin peak frequency loop (6.2 continues into here)

    for freqi = 1:length(freq)
        if freqi == 1 % Select directories for current sub-iteration
            intermedDirFi = midDirF1; saveDir_subFi = saveDir_subF1; plotDirFi = plotDirF1;
        elseif freqi == 2
            intermedDirFi = midDirF2; saveDir_subFi = saveDir_subF2; plotDirFi = plotDirF2;
        elseif freqi == 3
            intermedDirFi = midDirF3; saveDir_subFi = saveDir_subF1; plotDirFi = plotDirF3;
        end

        freqiChar = num2str(sprintf('%03d', freq{freqi}/1000)); % Frequency formatted for file names
        filePrefix = ['R' radialiChar '_' freqiChar 'kHz'];

        copyfile(fullfile(midDir,['R' radialiChar '.bty']),...
            fullfile(intermedDirFi, [filePrefix '.bty'])); % copy bty from intermed dir to intermed subdir
        copyfile(fullfile(intermedDirFi, [filePrefix '.bty']),...
            fullfile(saveDir_subFi, [filePrefix '.bty']));    % copy bty to final save dir

        %% 6.3 Make environment file (to be used in BELLHOP)
        disp(['Making environment file for ' filePrefix '...'])
        % Prepare and pack bottom parameters (AEHS params or grain sizes) for makeEnv input
        if botModel == 'A'     % A - Use manually-entered AEHS parameters
            botParms = AEHS;
        elseif botModel == 'G' % G - Use grain size
            botParms = radGrainSize(rad);
        elseif botModel == 'Y' % Y - Generate AEHS parameters from grain size based on Algorithm Y
            [AEHS.compSpeed, AEHS.compAtten, AEHS.shearSpeed, AEHS.density] = hamilton_aehs(radGrainSize(rad),SedDep);
            % Calculate compressional speed, shear speed, sediment density, compressional attenuation, and shear attenuation
            botParms = AEHS;
        end
        % Make environment file
        makeEnv(intermedDirFi, filePrefix, freq{freqi}, zssp, ssp, SD, RD, length(r), r, 'C', botModel, botParms); % make environment file
        copyfile(fullfile(intermedDirFi,[filePrefix '.env']),...
            fullfile(saveDir_subFi, [filePrefix '.env'])); % copy env to final save dir

        %% 6.4 Run BELLHOP - Make shade and print files
        disp(['Running Bellhop for ' filePrefix '...']) % Status update
        tBegin = tic;
        bellhop(fullfile(intermedDirFi, filePrefix)); % run bellhop on env file
        blhopTimes(rad) = toc(tBegin);
        copyfile(fullfile(intermedDirFi,[filePrefix '.shd']),...
            fullfile(saveDir_subFi, [filePrefix '.shd'])); % copy shd to final save dir
        copyfile(fullfile(intermedDirFi,[filePrefix '.prt']),...
            fullfile(saveDir_subFi, [filePrefix '.prt'])); % copy prt to final save dir

        %% 6.5 Generate radial plots
        if generate_RadialPlots == 1
            [PlotTitle, PlotType, freqVec, freq0, atten, Pos, pressure ] = read_shd([intermedDirFi, ['\' filePrefix '.shd']]);
            PLslice = squeeze(pressure(1, 1,:,:));
            PL = -20*log10(abs(PLslice));

            [x1,y1] = meshgrid(1:rangeStep:(rangeStep*size(PL,2)),1:depthStep:(depthStep*size(PL,1)));
            [xq1,yq1] = meshgrid(1:(rangeStep*size(PL,2)),1:(depthStep*size(PL,1))); % this bumps memory up a bit...
            zq = interp2(x1,y1, PL,xq1, yq1);

            disp('Creating radial plot and saving...')
            % figure(2000+radials(rad))
            figure('visible', 'off')
            RL_radiii = SL - zq; % bumps memory up a bit
            RL_radiii(RL_radiii < RL_threshold) = NaN;
            ptVisibility = ones(size(RL_radiii));
            ptVisibility(isnan(RL_radiii)) = 0;
            radplotiii = imagesc(RL_radiii(:,:), 'AlphaData', ptVisibility); % RL_radiii is recieved level for the given radial
            % Using imagesc instead but still hiding RLs that are too low:
            % got help from https://www.mathworks.com/matlabcentral/answers/81938-set-nan-as-another-color-than-default-using-imagesc
            % radplotiii = pcolor(RL_radiii(:,:)); % RL_radiii is recieved level for the given radial % Uhhhh this line basically causes memory to max out
            % axis ij
            % set(radplotiii, 'EdgeColor','none') % eases memory a decent amount
            colormap(jet)
            plotbty([intermedDirFi, '\' filePrefix, '.bty']) % doesn't hurt memory at all
            title([Site,' Radial', radialiChar, ', Freq ' freqiChar ' kHz'])
            colorbar
            saveas(radplotiii,[plotDirFi,'\',Site,'_',filePrefix,'_RLRadialMap.png'])

            clear RL_radiii radplotiii x1 y1 xq1 yq1 zq pressure PL PLslice ptVisibility
        end
    end
    clear Range bath
end % End loop through radials
disp('Completed constructing radials.')
%% Steps 7-9 - Loop through frequencies
for freqi = 1:length(freq)
    if freqi == 1 % Select directories for current sub-iteration
        intermedDirFi = midDirF1; saveDir_subFi = saveDir_subF1; plotDirFi = plotDirF1;
    elseif freqi == 2
        intermedDirFi = midDirF2; saveDir_subFi = saveDir_subF2; plotDirFi = plotDirF2;
    elseif freqi == 3
        intermedDirFi = midDirF3; saveDir_subFi = saveDir_subF1; plotDirFi = plotDirF3;
    end

    freqiChar = num2str(sprintf('%03d', freq{freqi}/1000)); % Frequency formatted for file names

    %% 7. Save User-input params to a text file; move this after SSP and include SSP that was inputted into that run (file name and the actual SSP)

    hdepth = SD; % ADDED BY AD
    txtFileName = [newFolderName '_' freqiChar 'kHz_Input_Parameters.txt'];
    paramfile = fullfile(intermedDirFi, txtFileName);
    fileid = fopen(paramfile, 'w');
    fclose(fileid);
    fileid = fopen(paramfile, 'at');
    fprintf(fileid, ['User Input Parameters for Run ' newFolderName ', Freq ' freqiChar ' kHz'...
        '\n\nCreated by\t' author '\nDateTime\t' datestr(datetime('now'), 'yyyymmdd HHMMSS') '\nUser Note' userNote...
        '\n\nSite\t' Site '\nRegion\t' Region ...
        '\n\nSSP INPUT\nFile Name\t' SSPfile, '\nSSP Type\t' SSPtype '\nMonth\t' SSPmoReporting...
        '\n\nHYDROPHONE PARAMETERS\nSL\t' num2str(SL) '\nSD\t' num2str(SD) '\nhlat\t' num2str(hlat) '\nhlon\t' num2str(hlon) '\nhdepth\t' num2str(hdepth) '\nFrequency\t' num2str(freq{freqi})...
        '\n\nACOUSTO ELASTIC HALF-SPACE\nCompressional Speed\t' num2str(AEHS.compSpeed) '\nShear Speed\t' num2str(AEHS.shearSpeed) '\nDensity\t' num2str(AEHS.density) '\nCompressional Attenuation\t' num2str(AEHS.compAtten)...
        '\n\nRANGE & RESOLUTION\nRange\t' num2str(total_range) '\nRange Step\t' num2str(rangeStep) '\nNumber of Radials\t' num2str(numRadials) '\nRad Step\t' num2str(radStep) '\nDepth Step\t' num2str(depthStep)...
        '\n\nPLOT GENERATION\nGenerate Polar Plots\t' num2str(generate_PolarPlots) '\nGenerate Radial Plots\t' num2str(generate_RadialPlots)...
        '\nRL Threshold\t' num2str(RL_threshold) '\nRL Plot Maximum\t' num2str(RL_plotMax) '\nDepth Levels\t' num2str(makePolarPlots)... % '\nRadial Plots\t' num2str(makeRadialPlots)...
        '\n\n\nSSP\nDepth\tSound Speed']);
    SSP_Reporting = (table2array(SSP)).';
    fprintf(fileid, '\n%4.0f\t%4.11f', SSP_Reporting);
    fclose(fileid);

    copyfile(paramfile,fullfile(saveDir_subFi, txtFileName)) % Copy to saveDir_sub
    copyfile(paramfile,fullfile(plotDirFi, txtFileName)); % Copy to plotDir
    %% 8. Generate Polar Plots
    if generate_PolarPlots == 1

        disp(['Now generating polar plots for Freq ' num2str(freq{freqi}) ' kHz, between depths ' num2str(makePolarPlots(1))...
            'm and ' num2str(makePolarPlots(3)) 'm, with interval ' num2str(makePolarPlots(2)) 'm'])
        pause(1)

        for plotdepth = makePolarPlots(1):makePolarPlots(2):makePolarPlots(3)
            for rad = 1:length(radials)

                radialiChar = num2str(sprintf('%03d', radials(rad))); % Radial number formatted for file names
                filePrefix = ['R' radialiChar '_' freqiChar 'kHz']; % Current file prefix

                [PlotTitle, PlotType, freqVec, freq0, atten, Pos, pressure] = read_shd([intermedDirFi, '\', [filePrefix '.shd']]);
                PLslice = squeeze(pressure(1, 1,:,:));
                PL = -20*log10(abs(PLslice));

                [x1,y1] = meshgrid(1:rangeStep:(rangeStep*size(PL,2)),1:depthStep:(depthStep*size(PL,1)));
                [xq1,yq1] = meshgrid(1:(rangeStep*size(PL,2)),1:(depthStep*size(PL,1)));
                zq = interp2(x1,y1, PL,xq1, yq1);

                %save radial depth
                rd_inter = Pos.r.z;

                PLiii(rad, :) = zq(plotdepth, :); % Save PL along depth iii meters, the depth that is currently being plotted

                clear zq yq1 xq1 x1 y1
                disp(['Working on Polar plot w/ Depth ' num2str(plotdepth) ': Radial ' radialiChar])
            end

            PLiii(isinf(PLiii)) = NaN;
            PLiii(PLiii > RL_threshold) = NaN; %PLxxx > 125 == NaN; %AD - what is this line for
            RLiii = SL - PLiii;
            RLiii(RLiii < RL_threshold) = NaN;

            R = 1:1:length(RLiii(1,:));
            figure('visible', 'off') % figure(1000 + plotdepth)
            [Radiance, calbar] = polarPcolor(R, [radials 360], [RLiii;NaN(1,length(RLiii(1,:)))], 'Colormap', jet, 'Nspokes', 7);
            set(calbar,'location','EastOutside')
            clim([RL_threshold RL_plotMax]);
            yticks(0:60:300)
            set(get(calbar,'ylabel'),'String', '\fontsize{10} Received Level [dB]');
            set(gcf, 'Position', [100 100 800 600])
            title(['\fontsize{15}', Site, ' - ', num2str(plotdepth), ' m, ' num2str(freq{freqi}) ' kHz'],'Position',[0 -1.2])
            saveas(Radiance,[plotDirFi,'\',Site,'_',num2str(plotdepth),'m_' num2str(freqiChar) 'kHz_RLPolarMap.png'])
            disp(['Polar Radial Map saved: ', Site, ', ', num2str(plotdepth), ' m, ' num2str(freq{freqi}) ' kHz'])

        end
    end

    %% 9. Save variables for pDetSim
    freqSave = char(num2str(freq{freqi}/1000));
    rr = r'; % output to be saved for pDetSim
    save([fpath,'\DetSim_Workspace\',Site,'\',Site,'_',newFolderName,'_' freqiChar 'kHz_bellhopDetRange.mat'],'rr','nrr','freqSave','hdepth','radials','botDepthSort');

end
