% code to calculate detection range around HARP
% WASD and NP
% WASD 2024/01/19 - Added changes made by JAH and WASD
% Built for MATLAB R2022b, or later.
% NOTE: May now require R2023b or later.
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
justenv = 'n'; % only env files - no bellhop

%% 1. Define global vars
% These are being called in the loop but are not functions
global rangeStep
global lati
global loni
global rad
global radStep
global depthStep
%% 2. Enter path to settings file and load settings
% Enter your settings in the PropaMod_Settings sheet. Then, enter the file path below.
% settingsPath = 'H:\PropaMod\PropaMod_Settings.xlsx'; % <- Aaron
settingsPath = 'H:\PropaMod\PropaMod_Settings_ConfigV2.xlsx'; % <- Aaron alternate
% settingsPath = 'I:\BellHopOutputs\PropaMod_Settings.xlsx'; % <- Natalie
readSettings
%% 3. Make new folders for this run's files
% This step prevents file overwriting, if you are running bellhopDetRange.m
% multiple times in parallel on the same computer (or across devices).

runDate = char(datetime('now', 'Format', 'yyMMdd'));
existingDirs = string(ls(saveDir)); % Check what folder names already exist in the final save directory
if ~strcmp(existingDirs, "")
    existingDirs(1:2) = []; % delete first two rows
end
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
hydLoc = [hlat, hlon, NaN]; % Leave depth empty for now
if strcmp(hzconfig, 'DepthFromSurf') % If vertical pos configuration is depth from surface, set hdepth = hz
    hdepth = hz;
    hydLoc(3) = hdepth; % Add to hydLoc
end

% Radial intervals and length
radStep = 360/numRadials;           % Angular resolution (i.e. angle between radials)
radials = 0:radStep:(360-radStep);  % radials in #-degree interval (# is in radStep)
dist = (total_range/1000);          % distance in km to farthest point in range
distDeg = km2deg(dist);             % radial length in degrees

% Reciever Depth
RD = 0:depthStep:1000;              % Receiver depth (it's set to a 1000 here, but in the 'Build Radial' loop, RD goes to the maximum depth of the bathymetry
r = 0:rangeStep:total_range;        % range with steps

%5a. Load GEBCO data once
distDec = dist*0.08; %convert distance from km to degrees
hlat_range = [hlat+distDec hlat-distDec];
hlon_range = [hlon+distDec hlon-distDec];
AllVariables = loadBTYJAH(distDec,hlat_range,hlon_range,GEBCODir,GEBCOFile);

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

bathyTimes = nan(rad, 1); % List of durations of bathymetry file section
blhopTimes = nan(rad, 1); % List of durations of bellhop section
for rad = 1:length(radials)
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
    [~, bath] = makeBTY(midDir, ['R_' radialiChar],hydLoc(1, 1), hydLoc(1, 2),AllVariables,BTYmodel); % make bathymetry file in intermed dir Freq 1
    figure
    plotbty(fullfile(midDir, ['R_' radialiChar, '.bty']));
    hold on;
    if isnan(bath)
        disp('Bad Bathy')
        return
    end
    % During first radial: If hydrophone vertical pos is set as elevation from sea floor, calculate it now based on bathymetry
    if rad == 1 % If on Radial 1
        SiteDepth = bath(1); % Set first value in bathymetry as depth of site
        AEHS.SiteDepth = SiteDepth;
        if strcmp(hzconfig, 'ElevFromBot')
            hdepth = SiteDepth - hz;
            SD = hdepth;
        end
    end

    RD = 0:depthStep:floor(max(bath)); % Re-creates the variable RD to go until the max depth of this specific radial -  JAH change to depthStep
    bathyTimes(rad) = toc(tBegin);

    botDepthSort(rad,:) = bath'; %save bottom depth sorted by radial for pDetSim

    % make sound speed profile the same depth as the bathymetry
%     zssp = 1:floor(max(bath))+100; % JAH hard code every m
    zssp = SSParray(1:5:end,1);
    ssp = SSParray(1:5:end,2);
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
        filePrefix = ['R_' radialiChar '_' freqiChar 'kHz'];

        copyfile(fullfile(midDir,['R_' radialiChar '.bty']),...
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
        makeEnv(intermedDirFi, filePrefix, freq{freqi}, zssp, ssp, SD, RD, length(r), r, SSPint, SurfaceType, BottomAtten, VolAtten, botModel, botParms); % make environment file
        copyfile(fullfile(intermedDirFi,[filePrefix '.env']),...
            fullfile(saveDir_subFi, [filePrefix '.env'])); % copy env to final save dir
        %% 6.4 Run BELLHOP - Make shade and print files
        if strcmp(justenv,'n')
            disp(['Running Bellhop for ' filePrefix '...']) % Status update
            tBegin = tic;
            bellhop_wasd(fullfile(intermedDirFi, filePrefix), 'jah'); % run bellhop on env file. Use jah's version of bellhop.
            blhopTimes(rad) = toc(tBegin);
            copyfile(fullfile(intermedDirFi,[filePrefix '.shd']),...
                fullfile(saveDir_subFi, [filePrefix '.shd'])); % copy shd to final save dir
            copyfile(fullfile(intermedDirFi,[filePrefix '.prt']),...
                fullfile(saveDir_subFi, [filePrefix '.prt'])); % copy prt to final save dir
%             [PlotTitle, PlotType, freqVec, freq0, atten, Pos, pressure ] = read_shd([intermedDirFi, ['\' filePrefix '.shd']]);

            %             %% 6.5 Generate radial plots
            %             if generate_RadialPlots == 1
            %                 [PlotTitle, PlotType, freqVec, freq0, atten, Pos, pressure ] = read_shd([intermedDirFi, ['\' filePrefix '.shd']]);
            %                 PLslice = squeeze(pressure(1, 1,:,:));
            %                 PL = -20*log10(abs(PLslice));
            %
            %                 [x1,y1] = meshgrid(1:rangeStep:(rangeStep*size(PL,2)),1:depthStep:(depthStep*size(PL,1)));
            %                 [xq1,yq1] = meshgrid(1:(rangeStep*size(PL,2)),1:(depthStep*size(PL,1))); % this bumps memory up a bit...
            %                 zq = interp2(x1,y1, PL,xq1, yq1);
            %
            %                 disp('Creating radial plot and saving...')
            %                 % figure(2000+radials(rad))
            %                 figure('visible', 'off')
            %                 RL_radiii = SL - zq; % bumps memory up a bit
            %                 RL_radiii(RL_radiii < RL_threshold) = NaN;
            %                 ptVisibility = ones(size(RL_radiii));
            %                 ptVisibility(isnan(RL_radiii)) = 0;
            %                 radplotiii = imagesc(RL_radiii(:,:), 'AlphaData', ptVisibility); % RL_radiii is recieved level for the given radial
            %                 % Using imagesc instead but still hiding RLs that are too low:
            %                 % got help from https://www.mathworks.com/matlabcentral/answers/81938-set-nan-as-another-color-than-default-using-imagesc
            %                 % radplotiii = pcolor(RL_radiii(:,:)); % RL_radiii is recieved level for the given radial % Uhhhh this line basically causes memory to max out
            %                 % axis ij
            %                 % set(radplotiii, 'EdgeColor','none') % eases memory a decent amount
            %                 colormap(jet)
            %                 plotbty([intermedDirFi, '\' filePrefix, '.bty']) % doesn't hurt memory at all
            %                 title([Site,' Radial', radialiChar, ', Freq ' freqiChar ' kHz'])
            %                 colorbar
            %                 saveas(radplotiii,[plotDirFi,'\',Site,'_',filePrefix,'_RLRadialMap.png'])
            %
            %                 clear RL_radiii radplotiii x1 y1 xq1 yq1 zq pressure PL PLslice ptVisibility
            %                 close all
            %             end
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
    print_params

    %% 8. Generate Polar Plots
    %     if generate_PolarPlots == 1
    %
    %         disp(['Now generating polar plots for Freq ' num2str(freq{freqi}) ' kHz, between depths ' num2str(makePolarPlots(1))...
    %             'm and ' num2str(makePolarPlots(3)) 'm, with interval ' num2str(makePolarPlots(2)) 'm'])
    %         pause(1)
    %
    %         for plotdepth = makePolarPlots(1):makePolarPlots(2):makePolarPlots(3)
    %             for rad = 1:length(radials)
    %
    %                 radialiChar = num2str(sprintf('%03d', radials(rad))); % Radial number formatted for file names
    %                 filePrefix = ['R_' radialiChar '_' freqiChar 'kHz']; % Current file prefix
    %
    %                 [PlotTitle, PlotType, freqVec, freq0, atten, Pos, pressure] = read_shd([intermedDirFi, '\', [filePrefix '.shd']]);
    %                 PLslice = squeeze(pressure(1, 1,:,:));
    %                 PL = -20*log10(abs(PLslice));
    %
    %                 [x1,y1] = meshgrid(1:rangeStep:(rangeStep*size(PL,2)),1:depthStep:(depthStep*size(PL,1)));
    %                 [xq1,yq1] = meshgrid(1:(rangeStep*size(PL,2)),1:(depthStep*size(PL,1)));
    %                 zq = interp2(x1,y1, PL,xq1, yq1);
    %
    %                 %save radial depth
    %                 rd_inter = Pos.r.z;
    %
    %                 PLiii(rad, :) = zq(plotdepth, :); % Save PL along depth iii meters, the depth that is currently being plotted
    %
    %                 clear zq yq1 xq1 x1 y1
    %                 disp(['Working on Polar plot w/ Depth ' num2str(plotdepth) ': Radial ' radialiChar])
    %             end
    %
    %             PLiii(isinf(PLiii)) = NaN;
    %             PLiii(PLiii > RL_threshold) = NaN; %PLxxx > 125 == NaN; %AD - what is this line for
    %             RLiii = SL - PLiii;
    %             RLiii(RLiii < RL_threshold) = NaN;
    %
    %             R = 1:1:length(RLiii(1,:));
    %             figure('visible', 'off') % figure(1000 + plotdepth)
    %             [Radiance, calbar] = polarPcolor(R, [radials 360], [RLiii;NaN(1,length(RLiii(1,:)))], 'Colormap', jet, 'Nspokes', 7);
    %             set(calbar,'location','EastOutside')
    %             caxis([RL_threshold RL_plotMax]);
    %             yticks(0:60:300)
    %             set(get(calbar,'ylabel'),'String', '\fontsize{10} Received Level [dB]');
    %             set(gcf, 'Position', [100 100 800 600])
    %             title(['\fontsize{15}', Site, ' - ', num2str(plotdepth), ' m, ' num2str(freq{freqi}) ' kHz'],'Position',[0 -1.2])
    %             saveas(Radiance,[plotDirFi,'\',Site,'_',num2str(plotdepth),'m_' num2str(freqiChar) 'kHz_RLPolarMap.png'])
    %             disp(['Polar Radial Map saved: ', Site, ', ', num2str(plotdepth), ' m, ' num2str(freq{freqi}) ' kHz'])
    %
    %         end
    %     end
    %% 9. Save variables for pDetSim
    freqSave = char(num2str(freq{freqi}/1000));
    rr = r'; % output to be saved for pDetSim
    targetDirectory = [fpath,'\DetSim_Workspace\',Site];
    if exist(targetDirectory,'dir') == 0
        mkdir(targetDirectory);
    end
    save([fpath,'\DetSim_Workspace\',Site,'\',Site,'_',newFolderName,'_' freqiChar 'kHz_bellhopDetRange.mat'],'rr','nrr','freqSave','hdepth','radials','botDepthSort');
end

%% Loop through .shd files and extract depth and transmission loss
matOut = ESME_TL_3D(saveDir_subFi, 'Bellhop', 'JAH');
savePath = [saveDir_subFi, '\', 'freq_TL.mat'];
save(savePath,'-mat')
%     detfn = ['.*','.shd']; %.shd file names
%     fileList = cellstr(ls(fullfile(saveDir_subFi))); %all file names in folder
%     fileMatchIdx = find(~cellfun(@isempty,regexp(fileList,detfn))>0); % Find the file name that matches the filePrefix
%     concatFiles = fileList(fileMatchIdx); %find actual file names
%
%     rd_all = num2cell(zeros(1,length(concatFiles))); %create empty array for radial depth to be used later with pDetSim
%     sortedTLVec = num2cell(zeros(1,length(concatFiles))); %create empty array for transmission loss to be used later with pDetSim
%
%     for idsk = 1 : length(concatFiles)
%         % Load file
%         fprintf('Loading %d/%d file %s\n',idsk,length(concatFiles),fullfile(saveDir_subFi,concatFiles{idsk}))
%         D = fullfile(saveDir_subFi,concatFiles{idsk});
%         %     [PlotTitle, PlotType, freqVec, freq0, atten, Pos, pressure] = read_shd(D);
%         [ ~, ~, ~, ~, ~, ~, rd, ~, pressure, ~, ~ ] = ReadShadeBin(D, 'Bellhop');
%
%         %create transmisson loss model
%         PL = -20*log10(abs(pressure));
% %         PL(:,1) = PL(:,2);
%         sortedTLVec(idsk) = {PL};
%         %save radial depth
%         rd_all(idsk) = {rd}; %depth array to be used in pDetSim
%     end
%     thisAngle = radials; %change radial variable to match pdetSim code
%     sd = SD;
%     %% Save and export workspace for pDetSim_v3Pm.m
%     fnmatOut = fullfile(saveDir_subFi,[Site,'_',freqiChar,'kHz_3DTL.mat']);
%     save(fnmatOut,'rr','nrr','rd_all','sortedTLVec','hdepth','thisAngle','botDepthSort','freqSave','sd','-v7.3')% Kait format


% end