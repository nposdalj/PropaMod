% code to calculate detection range around HARP
% WASD and NP
% WASD 2024/01/19 - Added changes made by JAH and WASD

% Built for MATLAB R2022b, or later.
% NOTE: May now require R2023b or later.
% This script will:
% - Construct sound propagation radials around your site with your specified parameters
% - Save a .txt file w/ your selected parameters in Export directory and plot directory
% - Save .bty, .env, .shd, and .prt files to intermediate directory
% - Move these outputs to the Export directory
% - Generate radial and polar plots and save to Export directory
% Please create a sound speed profile before executing this program.
clearvars; close all;clc;

%% 1. USER: Enter path to settings file
% Enter your settings in the PropaMod_Settings sheet. Then, enter the file path below.
settingsPath = 'H:\PropaMod\PropaMod_Settings_Baja.xlsx'; % <- WASD
% settingsPath = 'I:\BellHopOutputs\PropaMod_Settings.xlsx'; % <- NP

%% 2. Load settings
readSettings

%% 3. Make new folders for this run's files
% Define run ID (format: YYMMDDx where x is letter of alphabet)
Date = char(datetime('now', 'Format', 'yyMMdd')); % Today's date
runDirs = string(ls(saveDir)); % Check what folder names already exist in the final save directory
runDirs(strcmp(runDirs, ".      ") | strcmp(runDirs, "..     ")) = []; % Delete rows that actually aren't folders
runDirs = runDirs(contains(runDirs, Date), :); % Only folders from today
runDirs = char(runDirs); % Convert to char array
if ~isempty(runDirs)
    dirTagInUse = double(runDirs(:, end)); % Directory tags already in use
else
    dirTagInUse = 0; % If no directory tags being used yet, just set this as 0
end
dirTagsAll = double('a'):double('{'); % All directory tag options (a-z)
dirTag = min(setdiff(dirTagsAll, dirTagInUse)); % Get first available directory tag in alphabet
if isempty(dirTag) % Throw error if no directory tags available
    error('Max daily limit of 26 runs has been reached. To make a new one, delete a run from today from the GDrive save directory.')
end
runID = [Date char(dirTag)]; disp(num2str(runID));

% Create general intermediate, final, and plot directories
midDir = [localDir, '\', Site, '\', runID]; mkdir(midDir);    % Intermediate save directory [local]
endDir = [saveDir '\', runID]; mkdir(endDir);   % Final save directory [GDrive]
plotDir = [fpath, '\Plots\' Site '\' runID]; mkdir(plotDir);    % Plot save directory [GDrive]
% Pre-allocate names, then create frequency-specific intermediate, final, and plot sub-directories
midDirF = cell(length(freq), 1); endDirF = cell(length(freq), 1); plotDirF = cell(length(freq), 1);
for freqi = 1:length(freq)
    fnameFreq = [num2str(freq{1}/1000) 'kHz']; % i'th freq formatted for sub-directory names
    midDirF{freqi} = fullfile(midDir, fnameFreq); mkdir(midDirF{freqi}); % Intermediate sub-directory for i'th freq
    endDirF{freqi} = fullfile(endDir, fnameFreq); mkdir(endDirF{freqi}); % Final sub-directory for i'th freq
    plotDirF{freqi} = fullfile(plotDir, fnameFreq); mkdir(plotDirF{freqi}); % Plot sub-directory for i'th freq
end

%% 4. Sound Speed Profiles
SSPdir = ls(fullfile(fpath,'SSPs',Region,Site));          % Get list of files in SSP folder
SSPdirIdx = find(contains(string(SSPdir),SSPtype) & ~contains(string(SSPdir), "$"));
% Index of desired SSP file based on user input. MODIFIED TO IGNORE TEMPORARY FILES.
SSPfile = strtrim(SSPdir(SSPdirIdx,:));                % Get SSP file
SSP = table2array(readtable(fullfile(fpath,'SSPs',Region,Site,SSPfile))); % read SSP as array

if strcmp(SSPtype, 'Mmax') || strcmp(SSPtype, 'Mmin') % Get month being examined to report in the output info file, if applicable
    SSPmoReporting = num2str(SSPfile(12:13));
elseif strcmp(SSPtype, 'Mean')
    SSPmoReporting = 'Not applicable'; % If using mean SSP, then report "Not applicable"
end

%% 5. Hydrophone location and depth & Load GEBCO data
% Center of source cell
hydLoc = [hlat, hlon, NaN]; % Leave depth empty for now
if strcmp(hzconfig, 'DepthFromSurf') % If vertical pos configuration is depth from surface, set hdepth = hz
    hdepth = hz;
    hydLoc(3) = hdepth; % Add to hydLoc
    SD = hdepth; % Set SD as this
end
% Radial intervals and length
thetaStep = 360/numRadials;           % Angular resolution (i.e. angle between radials)
radials = 0:thetaStep:(360-thetaStep);  % radials in #-degree interval (# is in radStep)
dist = (Range/1000);          % distance in km to farthest point in range
distDeg = km2deg(dist);             % radial length in degrees
% Reciever Depth
RD = 0:zStep:1000;  % Receiver depth (it's set to a 1000 here, but in the 'Build Radial' loop, RD goes to the maximum depth of the bathymetry
r = 0:rStep:Range;  % range with steps
% Load GEBCO data
distDec = dist*0.08; % convert distance from km to degrees
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
    radGrainSize = getGrainSize(sedDatType, sedPath, hydLoc, distDeg, Range, radials, plotDir, rStep, forceLR);
end
%% 6. Build Radials
% NOTE: Existing files in folder will be overwritten if you do not create subfolder using Section 3
disp('General setup complete. Beginning radial construction...')

% Preallocated variables
botDepthSort = nan(length(radials), length(0:rStep:Range)); % bottom depth sorted by radials for pDetSim
latout = nan(1, length(radials));
lonout = nan(1, length(radials));
lati = nan(length(radials), length(0:rStep:Range));
loni = nan(length(radials), length(0:rStep:Range));

for rad = 1:length(radials)
    disp(['Constructing Radial ' num2str(sprintf('%03d', round(radials(rad)))), ':'])

    %% 6.1 Create radial line
    % gives lat-lon point total range (km) away in the direction of radials from source center
    [latout(rad), lonout(rad)] = reckon(hydLoc(1, 1), hydLoc(1, 2), distDeg, radials(rad),'degrees');

    % RANGE STEP - interpolate line from center to point at edge of circle
    lati(rad, :) = linspace(hydLoc(1, 1), latout(rad), length(0:rStep:Range));
    loni(rad, :) = linspace(hydLoc(1, 2), lonout(rad), length(0:rStep:Range));

    %% 6.2 Make bathymetry file (to be used in BELLHOP)
    disp(['Making bathymetry file for Radial ' num2str(sprintf('%03d', round(radials(rad)))) '...'])

    radiChar = num2str(sprintf('%03d', round(radials(rad)))); % Radial number formatted for file names
    [~, bath] = makeBTY(midDir, ['R_' radiChar],hydLoc(1, 1), hydLoc(1, 2),AllVariables,BTYmodel, lati, loni, rad); % make bathymetry file in intermed dir Freq 1
    if isnan(bath)
        error('Bad Bathymetry')
    end
    if rad == 1 % During first radial, if hydrophone z pos set as elev from sea floor, calculate it based on bathymetry
        SiteDepth = bath(1); % Set first value in bathymetry as depth of site
        AEHS.SiteDepth = SiteDepth;
        if strcmp(hzconfig, 'ElevFromBot')
            hdepth = SiteDepth - hz;
            SD = hdepth;
        end
    end

    RD = 0:zStep:floor(max(bath)); % Re-creates the variable RD to go until the max depth of this specific radial -  JAH change to zStep
    botDepthSort(rad,:) = bath'; %save bottom depth sorted by radial for pDetSim

    % make sound speed profile the same depth as the bathymetry
%     zssp = 1:floor(max(bath))+100; % JAH hard code every m
    zssp = SSP(1:5:end,1);
    ssp = SSP(1:5:end,2);

    %% Begin peak frequency loop (6.2 continues into here)
    for freqi = 1:length(freq)
        midDirFi = midDirF{freqi}; endDirFi = endDirF{freqi}; plotDirFi = plotDirF{freqi}; % sub-directories for iteration
        freqiChar = num2str(sprintf('%0.5g', freq{freqi}/1000)); % Frequency formatted for file names
        fPrefix = ['R_' radiChar '_' freqiChar 'kHz'];
        copyfile(fullfile(midDir,['R_' radiChar '.bty']), fullfile(midDirFi, [fPrefix '.bty'])); % copy bty to sub-directory
        copyfile(fullfile(midDirFi, [fPrefix '.bty']), fullfile(endDirFi, [fPrefix '.bty']));    % copy bty to final directory
        %% 6.3 Make environment file (to be used in BELLHOP)
        disp(['Making environment file for ' fPrefix '...'])
        % Prepare and pack bottom parameters (AEHS params or grain sizes) for makeEnv input
        if botModel == 'A'     % A - Use manually-entered AEHS parameters
            botParms = AEHS;
        elseif botModel == 'G' % G - Use grain size
            botParms = radGrainSize(rad);
        elseif botModel == 'Y' % Y - Generate AEHS parameters from grain size based on Algorithm Y
            % Calculate compressional speed, shear speed, sediment density, compressional attenuation, and shear attenuation
            [AEHS.compSpeed, AEHS.compAtten, AEHS.shearSpeed, AEHS.density] = hamilton_aehs(radGrainSize(rad),SedDep);
            botParms = AEHS;
        end
        % Make environment file
        makeEnv(midDirFi, fPrefix, freq{freqi}, zssp, ssp, SD, RD, length(r), r, SSPint, SurfaceType, BottomAtten, VolAtten, botModel, botParms);
        copyfile(fullfile(midDirFi,[fPrefix '.env']), fullfile(endDirFi, [fPrefix '.env'])); % copy env to final directory
        %% 6.4 Run BELLHOP - Make shade and print files
        disp(['Running Bellhop for ' fPrefix '...']) % Status update
        bellhop_wasd(fullfile(midDirFi, fPrefix), bellhopVersion); % run bellhop on env file. Version: 'jah' or 'cxx'
        copyfile(fullfile(midDirFi,[fPrefix '.shd']), fullfile(endDirFi, [fPrefix '.shd'])); % copy shd to final dir
        copyfile(fullfile(midDirFi,[fPrefix '.prt']), fullfile(endDirFi, [fPrefix '.prt'])); % copy prt to final dir
            [PlotTitle, PlotType, freqVec, freq0, atten, Pos, pressure ] = read_shd([midDirFi, ['\' fPrefix '.shd']]);

                        %% 6.5 Generate radial plots
                        if generate_RadialPlots == 1
                            [PlotTitle, PlotType, freqVec, freq0, atten, Pos, pressure ] = read_shd([midDirFi, ['\' fPrefix '.shd']]);
                            PLslice = squeeze(pressure(1, 1,:,:));
                            PL = -20*log10(abs(PLslice));

                            [x1,y1] = meshgrid(1:rStep:(rStep*size(PL,2)),1:zStep:(zStep*size(PL,1)));
                            [xq1,yq1] = meshgrid(1:(rStep*size(PL,2)),1:(zStep*size(PL,1))); % this bumps memory up a bit...
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
                            saveas(radplotiii,[plotDirFi,'\',Site,'_',fPrefix,'_RLRadialMap.png'])

                            clear RL_radiii radplotiii x1 y1 xq1 yq1 zq pressure PL PLslice ptVisibility
                            close all
                        end
    end
    clear bath
end % End loop through radials
disp('Completed constructing radials.')
%% Steps 7-9 - Loop through frequencies
for freqi = 1:length(freq)
    midDirFi = midDirF{freqi}; endDirFi = endDirF{freqi}; plotDirFi = plotDirF{freqi}; % sub-directories for iteration
    freqiChar = num2str(sprintf('%0.5g', freq{freqi}/1000)); % Frequency formatted for file names
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
    %                 radialiChar = num2str(sprintf('%03d', round(radials(rad)))); % Radial number formatted for file names
    %                 filePrefix = ['R_' radialiChar '_' freqiChar 'kHz']; % Current file prefix
    %
    %                 [PlotTitle, PlotType, freqVec, freq0, atten, Pos, pressure] = read_shd([midDirFi, '\', [fPrefix '.shd']]);
    %                 PLslice = squeeze(pressure(1, 1,:,:));
    %                 PL = -20*log10(abs(PLslice));
    %
    %                 [x1,y1] = meshgrid(1:rStep:(rStep*size(PL,2)),1:zStep:(zStep*size(PL,1)));
    %                 [xq1,yq1] = meshgrid(1:(rStep*size(PL,2)),1:(zStep*size(PL,1)));
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
    save([fpath,'\DetSim_Workspace\',Site,'\',Site,'_',runID,'_' freqiChar 'kHz_bellhopDetRange.mat'],'rr','nrr','freqSave','hdepth','radials','botDepthSort');
end

%% Loop through .shd files and extract depth and transmission loss
matOut = ESME_TL_3D(endDirFi, 'Bellhop', 'JAH');
savePath = [endDirFi, '\', 'freq_TL.mat'];
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