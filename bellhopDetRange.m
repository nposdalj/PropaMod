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

%% Define global vars
global rangeStep
global lat
global lon
global z
global lati
global loni
global rad
global radStep

%% Params defined by user + Info for user

% CONFIGURE INPUT AND EXPORT
Site = 'NC';
Region = 'WAT';
%outDir = [fpath, '\Radials\', SITE]; % EDIT - Set up Google Drive folder - for loading in items and saving
bellhopSaveDir = 'C:\Users\HARP\Documents\GitHub\PropagationModeling';
Gdrive = 'I';
fpath = [Gdrive, ':\My Drive\PropagationModeling']; % Input directory
    % fpath must contain:
        % bathymetry file: \Bathymetry\bathy.txt
        % Site SSP data: \SSPs\SSP_WAT_[Site].xlsx
fpath_Radials = [fpath, '\Radials\', Site]; %UNUSED
fpath_Plots = [fpath, '\Plots\', Site];     %UNUSED
saveDir = [fpath, '\Radials\', Site]; % Export directory
%intermedDir = 'C:\Users\HARP\Documents\PropMod_Radials_Intermediate'; % Intermediate save directory on your local disk
intermedDir = 'C:\Users\nposd\Desktop\PropagationModelingIntermediate'; %For Natalie's computer
% This script will:
        % Construct sound propagation radials around your site with your
        % specified range, depth, and angle resolutions
        % Save .bty, .env, .shd, and .prt files to intermediate directory
        % Move these outputs to the Export directory
        % Generate radial and polar plots and save to Export directory

% CONFIGURE DATA TO GENERATE
total_range = 20000; % Radial range around your site, in meters
rangeStep = 10; % Range resolution
radStep = 5; % Angular resolution (i.e. angle between radials)

% CONFIGURE PLOT OUTPUT
total_range = 20000; % Desired radial range, in meters
rangeStep = 10; % Range step size, in meters
nrr = total_range/rangeStep; %total # of range step output to be saved for pDetSim
%% Bathymetry 
disp('Loading bathymetry data...') % Reading in bathymetry data
tic
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
SSP_WAT = readtable([fpath, '\SSPs\SSP_WAT_MissingDepthsFilled.xlsx']);
NCSSPcoarse = [SSP_WAT.Depth SSP_WAT.NC];
idxNan = isnan(NCSSPcoarse(:, 2));
NCSSPcoarse(idxNan, :) = [];

vq = interp1(NCSSPcoarse(:, 1), NCSSPcoarse(:, 2), 1:1:NCSSPcoarse(end, 1)); % Fill in missing depths - every 1 m
NCSSP = [1:1:NCSSPcoarse(end, 1); vq]';

%% Hydrophone location and depth
hlat = 39.8326;     %AD: I'll configure this to call an .xlsx file with all the site coords and depths
hlon = -69.9800;
hdepth = 960;

% Center of source cell
hydLoc = [hlat, hlon, hdepth];

% Radial intervals and length
radials = 0:radStep:(360-radStep);                                       % radials in 10 degree intervals
dist = 20;                                               % distance in km to farthest point you want
distDeg = km2deg(dist);                                  % radial length in degrees

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
rr = r'; %output to be saved for pDetSim

%% Build Radials

disp('General setup complete. Beginning radial construction...')
tic
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
    [Range, bath] = makeBTY(intermedDir, ['Radial_' num2str(radials(rad))],latout(rad), lonout(rad), hydLoc(1, 1), hydLoc(1, 2)); % make bathymetry file
    bathTest(rad, :) = bath;
    toc
   
    % make sound speed profile the same depth as the bathymetry
    zssp = [1:1:max(bath)+1];
    
    ssp = NCSSP([1:length(zssp)], 2);
    %ssp = [NCSSP(:,2); NaN(length(zssp)-length(NCSSP),1)];%ssp = NCSSP([1:length(zssp), 2); %AD - I changed this as a workaround
    % make environment file to be used in bellhop
    disp(['Making environment file for Radial ', num2str(radials(rad)),'...'])   % Status update
    makeEnv(intermedDir, ['Radial_' num2str(radials(rad))], zssp, ssp, SD, RD, length(r), r, 'C'); % make environment file
    % running bellhop
    disp(['Running Bellhop for Radial ', num2str(radials(rad)),'...']) % Status update
    tic
    %bellhop(fullfile('C:\Users\HARP\Documents\GitHub\PropagationModeling', ['Radial_' num2str(radials(rad))])); % run bellhop on env file

    bellhop(fullfile(intermedDir, ['Radial_' num2str(radials(rad))])); % run bellhop on env file
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
toc
%% Generate new files with 3 digits and move (copy) to save directory

%matFiles = ls(fullfile(bellhopSaveDir,'*Radial*.shd'));
allFiles = ls(fullfile(bellhopSaveDir,'*Radial*'));
for k = 1:length(allFiles)
    oldFileName = allFiles(k,:);
    firsthalf = oldFileName(1:strfind(oldFileName,'_'));
    if allFiles(k,13) == ' '
        secondhalf = oldFileName(strfind(oldFileName,'.')-1:end);
        newFileName = strcat(firsthalf, '00', secondhalf);
    elseif allFiles(k,14) == ' '
        secondhalf = oldFileName(strfind(oldFileName,'.')-2:end);
        newFileName = strcat(firsthalf, '0', secondhalf);
    else
        newFileName = oldFileName;
    end
    copyfile(fullfile(bellhopSaveDir,oldFileName),fullfile(fpath, 'Radials',Site,newFileName));
    disp([oldFileName, ' copied to save directory as ', newFileName])
end
%matFiles = ls(fullfile(fpath, 'Radials', SITE, '*Radial*.shd'));
allFiles = ls(fullfile(fpath, 'Radials', Site, '*Radial*.shd'));

%shellcmd = ['move Radial_' num2str(f(findex)) 'Hz_' num
%% Generate plots
makeDepthPlots = [150, 50, 800]; % USER: edit with [min depth, step size, max depth]

% rd_all = zeros(1,length(radials)); %create empty array for radial depth to be used later with pDetSim
% sortedTLVec = zeros(1,length(radials)); %create empty array for transmission loss to be used later with pDetSim

% join this to the loop above
for plotdepth = makeDepthPlots(1):makeDepthPlots(2):makeDepthPlots(3);
for rad = 1:length(radials)
    %iffn = fullfile(bellhopSaveDir,matFiles(rad,:));

    [ PlotTitle, PlotType, freqVec, freq0, atten, Pos, pressure ] = read_shd([bellhopSaveDir, ['\Radial_' num2str(radials(rad)) '.shd']]);
    PLslice = squeeze(pressure(1, 1,:,:));
    PL = -20*log10(abs(PLslice));
    
    [x1,y1] = meshgrid(1:10:(10*size(PL,2)),1:10:(10*size(PL,1))); %10 in 1:10:(10*size(PL,2)) varies with resolution; note to self to remove hard-coding
    % [x1,y1] = meshgrid(1:100:(100*size(PL,2)),1:10:(10*size(PL,1)));
    [xq1,yq1] = meshgrid(1:(10*size(PL,2)),1:(10*size(PL,1))); %10 in 1:(10*size(PL,2)) varies with resolution; note to self to remove hard-coding
    % [xq1,yq1] = meshgrid(1:(100*size(PL,2)),1:(10*size(PL,1)));
    zq = interp2(x1,y1, PL,xq1, yq1);
%     sortedTLVec(rad) = zq; %transmission loss vector to be used in pDetSim
    
    %save radial depth
    rd_inter = Pos.r.z;
%     rd_all(rad) = rd_inter; %depth array to be used in pDetSim
    
    PL800(rad, :) = zq(plotdepth, :); % PL800(mf, :) = zq(790, :); %SELECT DEPTH TO PLOT
    
    clear zq yq1 xq1 x1 y1 
    disp(['\Radial_' num2str(radials(rad)) '.shd'])
end

PL800(isinf(PL800)) = NaN;
%PL800(isinf(PL800)) = NaN;
PL800(PL800 > 125) = NaN; %PL800 > 125 == NaN; %AD - what is this line for
RL800 = 220 - PL800;
RL800(RL800 < 125) = NaN; 

R = 1:1:20010;
figure(10000 + plotdepth); 
[Radiance, calbar] = polarPcolor(R, [radials 360], [RL800;NaN(1,20010)], 'Colormap', jet, 'Nspokes', 7);
set(calbar,'location','EastOutside')
caxis([125 155]);
yticks(0:60:300)
%colormap('jet')
%t=colorbar('Limits', [125 155]);
%test=flipud(colormap('jet'));
%colormap(test);
set(get(calbar,'ylabel'),'String', ['\fontsize{10} Received Level [dB]']);
set(gcf, 'Position', [100 100 800 600])
title(['\fontsize{15}', Site, ' - ', num2str(plotdepth), ' m'],'Position',[0 -1.2])
saveas(Radiance,[fpath,'\Plots\',Site,'\',Site,'_',num2str(plotdepth),'_RadMap.png'])
disp(['Radial Map saved: ', Site, ', ', num2str(plotdepth), ' m'])

end

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

presur = squeeze(pressure(1,1,:,:));
plot(presur)

plot(pressure(1, 1, :, :))
figure
plotshd('Radial_260.shd')
plotbty 'Radial_260.bty'

plotshd('Radial_0.shd')
plotbty 'Radial_0.bty'

for o=0:10:350
    figure((o+1))
    plotshd(['Radial_',num2str(o),'.shd'])
    plotbty(['Radial_',num2str(o),'.bty'])
    saveas(gcf,[fpath_Plots,'\',Site,'_Radial_',num2str(o)],'png')
end

figure(5)
radiant = 120;
plotshd(['Radial_', num2str(radiant), '.shd'])
ylim([0 2500])
plotbty(['Radial_', num2str(radiant), '.bty'])
hold on
plot(0:2000:20000, 790, 'or')
hold off

RL_rad0_bty = nan(1010,20010);
RL_rad0_bty(zq==inf) = inf;
bruh = pcolor(RL_rad0_bty);
set(bruh, 'EdgeColor','none')
axis ij
colormap(gray(1))

%rough code - works for plotting radials!
for o = 0:60:300

[ PlotTitle, PlotType, freqVec, freq0, atten, Pos, pressure ] = read_shd([bellhopSaveDir, ['\Radial_' num2str(o) '.shd']]);
PLslice = squeeze(pressure(1, 1,:,:));
PL = -20*log10(abs(PLslice));
    
[x1,y1] = meshgrid(1:10:(10*size(PL,2)),1:10:(10*size(PL,1))); %10 in 1:10:(10*size(PL,2)) varies with resolution; note to self to remove hard-coding
[xq1,yq1] = meshgrid(1:(10*size(PL,2)),1:(10*size(PL,1))); %10 in 1:(10*size(PL,2)) varies with resolution; note to self to remove hard-coding
zq = interp2(x1,y1, PL,xq1, yq1);
    
figure(o+1)
RL_rad0 = 220 - zq;
RL_rad0(RL_rad0 < 125) = NaN;
distress = pcolor(RL_rad0(:,:)); 
axis ij
set(distress, 'EdgeColor','none')
colormap(jet)
plotbty(['Radial_',num2str(o),'.bty'])
title([Site,' Radial', num2str(o)])
colorbar

end
%% Save variables for pDetSim
freqSave = char(freqVec/1000);
save([[fpath,'\',site,'\',site,'_bellhopDetRange.mat'],'rr','nrr','freqSave','hdepth');