% plotSSP
% Plot Sound Speed Profile for region of choice.
% Configured for use with HYCOM's files
% Latitudes and longitudes are configured for Western Atlantic (WAT). To
% change this, make edits in ext_hycom_gofs_3_1.m.

% AD: HYCOM data provides data points for every 1/12 degree. I believe 
% that is at most every ~9.25 km. This MIGHT allow us to see significant
% differences in sound speed across a 20-km range, but given such a low
% resolution, I think those differences will be somewhat imprecise.

%ADD SOMETHING HERE ABOUT WHAT IT DOES AT THE END WITH MIN/MAX SSPs

clearvars
close all
    
%% Parameters defined by user
% Before running, make sure desired data has been downloaded from HYCOM
% using ext_hycom_gofs_3_1.m.

% Search and export directories
regionabrev = 'WAT';
GDrive = 'H';
FilePath = [GDrive ':\My Drive\PropagationModeling\HYCOM_data'];
fileNames_all = ls(fullfile(FilePath, '*0*')); % File name to match. No need to modify this line.
saveDirectory = [GDrive ':\My Drive\PropagationModeling\SSPs'];

% Add site data below: siteabrev, lat, long
siteabrev = ['NC';       'BC';       'GS';       'BP';       'BS';      'WC';       'OC';       'HZ';       'JX'];
siteID    = [2;          3;          4;          5;          6;         7;          8;          9;          10];    % Make this list start at 2, and be the same length as siteabrev
Latitude  = [39.8326;    39.1912;    33.6675;    32.1061;    30.5833;   38.3738;    40.2550;    41.0618;    30.1523]; %jax avg is for D_13, 14, 15 only
Longitude = [-69.9800;   -72.2300;   -76;        -77.0900;   -77.3900;  -73.37;     -67.99;     -66.35;     -79.77];
% HydDepth  = [950;        950;        950;        950;        950;       950;        950;        950;        950];

% Effort Period
MonthStart = '201507';  % First month of study period (yyyymm)
MonthEnd = '201906';    % Last month of study period (yyyymm)

plotInProcess = 1; % Monitor plotted SSPs as they are generated? 1=Y, 0=N. Program will run slower.

%% Overarching loop runs through all timepoints requested
fileNames = fileNames_all(find(contains(fileNames_all,MonthStart)):find(contains(fileNames_all,MonthEnd)),:); % Only use months corresponding to study period

for k = 1:length(fileNames(:,1))
fileName = fileNames(k,:);

%% Load data
load([FilePath,'\', fileName]);

temp_frame = D.temperature;
sal_frame = D.salinity;
temp_frame = flip(permute(temp_frame, [2 1 3]),1); % To make maps work, swaps lat/long and flips lat
sal_frame = flip(permute(sal_frame, [2 1 3]),1);
depth_frame = zeros(length(D.Latitude), length(D.Longitude), length(D.Depth)); % Generates a 3D depth frame to match with sal and temp
for i=1:301
    for j=1:length(D.Longitude)
        depth_frame(i,j,1:length(D.Depth)) = D.Depth;
    end
end

cdat = nan(length(D.Latitude),length(D.Longitude),length(D.Depth)); % Generates an empty frame to input sound speeds
for i=1:(length(D.Latitude)*length(D.Longitude)*length(D.Depth)) % Only adds sound speed values ABOVE the seafloor
    if temp_frame(i) ~= 0 & sal_frame(i) ~= 0
        cdat(i) = salt_water_c(temp_frame(i),(-depth_frame(i)),sal_frame(i)); % Sound Speed data
    end
end

%% Generate SSPs

depthlist = abs(transpose(D.Depth)); % List of depth values to assign to the y's
LongitudeE = Longitude + 360;
siteCoords = [Latitude, LongitudeE];

%MAKE FIGURES, and GENERATE TABLE OF SITE SSP VALUES
SSP_table = [depthlist.'];

plottimept = figure(200);
plottimept_sup = uipanel('Parent',plottimept);
timestamp = [fileName(6:9), '/', fileName(10:11), '/', fileName(12:13), ' ',...
    fileName(15:16), ':', fileName(17:18), ':', fileName(19:20)];
plottimept_sup.Title = ['Site SSPs | ' timestamp];
set(gcf,'Position',[50 100 1400 600])

for i=1:length(siteabrev)
    numdepths = nan(1,length(depthlist));
    
    for j=1:length(depthlist) %interpolate sound speed grid at each depth to infer sound speed values at site coordinates
        %numdepths(j) = interp2(D.Longitude,flip(D.Latitude),cdat_sel(:,:,j),siteCoords(i,2),siteCoords(i,1).');
        numdepths(j) = interp2(D.Longitude,flip(D.Latitude),cdat(:,:,j),siteCoords(i,2),siteCoords(i,1).');
    end
    subplot(1,length(siteabrev),i, 'Parent',plottimept_sup)
    plot(numdepths, -depthlist,'-.')
    ylim([-1100 0])
    %title(['SSP at ', char(siteabrev(i)),' | ', num2str(siteCoords(i,1)),char(176), 'N, ', num2str(siteCoords(i,2)),char(176), 'E'])
    title(char(siteabrev(i,:)))
    if i == 1
        ylabel('Depth (m)')
    else
        set(gca,'YTickLabel',[])
    end
    if i == 5
        xlabel('Sound Speed (m/s)')
    end
    %sgtitle(['Site SSPs | ' timestamp])
    %saveas(gcf,[saveDirectory,'\',char(plotDate),'_',char(siteabrev(i)),'_SSP'],'png');
    SSP_table(:,i+1) = numdepths;
end
if plotInProcess == 1
    drawnow
end

ALL_SSParray(:,:,(12*(str2num(fileNames(k,6:9))-str2num(fileNames(1,6:9)))+str2num(fileNames(k,10:11))-str2num(fileNames(1,10:11))+1)) = SSP_table;
    % Array version of ALL_SSP - used for actual data assembly below

SSP_table = array2table(SSP_table);
SSP_table.Properties.VariableNames = {'Depth' char(siteabrev(1,:)) char(siteabrev(2,:)) char(siteabrev(3,:)) char(siteabrev(4,:))...
    char(siteabrev(5,:)) char(siteabrev(6,:)) char(siteabrev(7,:)) char(siteabrev(8,:)) char(siteabrev(9,:))};
%writetable(SSP_table,[saveDirectory,'\', 'SSP_', regionabrev, '_', fileName(strfind(fileName,'_')+1:end), '.xlsx'])

ALL_SSP.(['M',fileNames(k,6:11)]) = SSP_table; % All the data from all time points and all sites is stored in ALL_SSP
disp([fileName, ' - Extracted SSPs and added to ALL_SSP as M' fileNames(k,6:11)])

end

YearNums = 1:(length(ALL_SSParray(1,1,:))/12);
MoMeans.M01 = nanmean(ALL_SSParray(:,:,[12*(YearNums-1)+7]),3);   M01.std = nanstd(ALL_SSParray(:,:,[12*(YearNums-1)+7]),0,3);
MoMeans.M02 = nanmean(ALL_SSParray(:,:,[12*(YearNums-1)+8]),3);   M02.std = nanstd(ALL_SSParray(:,:,[12*(YearNums-1)+8]),0,3);
MoMeans.M03 = nanmean(ALL_SSParray(:,:,[12*(YearNums-1)+9]),3);   M03.std = nanstd(ALL_SSParray(:,:,[12*(YearNums-1)+9]),0,3);
MoMeans.M04 = nanmean(ALL_SSParray(:,:,[12*(YearNums-1)+10]),3);  M04.std = nanstd(ALL_SSParray(:,:,[12*(YearNums-1)+10]),0,3);
MoMeans.M05 = nanmean(ALL_SSParray(:,:,[12*(YearNums-1)+11]),3);  M05.std = nanstd(ALL_SSParray(:,:,[12*(YearNums-1)+11]),0,3);
MoMeans.M06 = nanmean(ALL_SSParray(:,:,[12*(YearNums-1)+12]),3);  M06.std = nanstd(ALL_SSParray(:,:,[12*(YearNums-1)+12]),0,3);
MoMeans.M07 = nanmean(ALL_SSParray(:,:,[12*(YearNums-1)+1]),3);   M07.std = nanstd(ALL_SSParray(:,:,[12*(YearNums-1)+1]),0,3);
MoMeans.M08 = nanmean(ALL_SSParray(:,:,[12*(YearNums-1)+2]),3);   M08.std = nanstd(ALL_SSParray(:,:,[12*(YearNums-1)+2]),0,3);
MoMeans.M09 = nanmean(ALL_SSParray(:,:,[12*(YearNums-1)+3]),3);   M09.std = nanstd(ALL_SSParray(:,:,[12*(YearNums-1)+3]),0,3);
MoMeans.M10 = nanmean(ALL_SSParray(:,:,[12*(YearNums-1)+4]),3);   M10.std = nanstd(ALL_SSParray(:,:,[12*(YearNums-1)+4]),0,3);
MoMeans.M11 = nanmean(ALL_SSParray(:,:,[12*(YearNums-1)+5]),3);   M11.std = nanstd(ALL_SSParray(:,:,[12*(YearNums-1)+5]),0,3);
MoMeans.M12 = nanmean(ALL_SSParray(:,:,[12*(YearNums-1)+6]),3);   M12.std = nanstd(ALL_SSParray(:,:,[12*(YearNums-1)+6]),0,3);

% NOTE: Before applying inpaint_nans, must
    % Expand SSPM to entire depth
    % Use interp to figure out values in between known values

% configure user input: Tell user to take run an output of this script
% through R and get the min and max mo's, then come back and input them
% here
%% Export Data for each site

for b = 1:length(siteabrev)
    Site = siteabrev(b,:);
    siteIDi = siteID(contains(siteabrev,Site));

TotMean = mean(cat(3, MoMeans.M01, MoMeans.M02,MoMeans.M03,MoMeans.M04,MoMeans.M05,MoMeans.M06,...
    MoMeans.M07,MoMeans.M08,MoMeans.M09,MoMeans.M10,MoMeans.M11,MoMeans.M12), 3); % Average all 12 calendar months
    % Averages the 12 month averages instead of averaging all the
    % individual months, since some of the 12 months are less represented
TotStd = std(cat(3, MoMeans.M01, MoMeans.M02,MoMeans.M03,MoMeans.M04,MoMeans.M05,MoMeans.M06,...
    MoMeans.M07,MoMeans.M08,MoMeans.M09,MoMeans.M10,MoMeans.M11,MoMeans.M12), 0, 3); % SD of the 12 calendar months

TotMeanfd = [(0:5000).' nan(1,5001).']; % Make an array for the full depth
TotMeanfd((depthlist+1),2) = TotMean(:,siteIDi); % Bring in site-specific data
firstNan = find(isnan(TotMean(:,2)),1); % Prevent interp1 from taking in NaNs as input values
TotMeanfd(:,2) = interp1((depthlist(1:(firstNan-1))+1).', TotMeanfd((depthlist(1:(firstNan-1)).'+1),2),1:length(TotMeanfd),'linear', 'extrap');

SSPT = [(0:5000).',inpaint_nans(TotMeanfd(:,2))];
SSPT = array2table(SSPT);
SSPT.Properties.VariableNames = {'Depth' 'SS'};
writetable(SSPT, [saveDirectory,'\', Site, '_SSP_Mean','.xlsx']) % Save overall average SSP
disp(['Average annual SSP saved for ' Site])

plot(SSPT.SS,-SSPT.Depth)

end

%% Have this script calculate the min and max months within this script and produce the SSPs to save accordingly
minMo = 4;
maxMo = 8;

MeanSSP_minMo = MoMeans.(['M',num2str(sprintf('%02d', minMo))]); % Average sound speed profiles of the month with lowest sound speeds

MoMeanfd = [(0:5000).' nan(1,5001).']; % Make an array for the full depth
MoMeanfd((depthlist+1),2) = MeanSSP_minMo(:,siteIDi); % Drop the site-specific data into this array
firstNan = find(isnan(MeanSSP_minMo(:,2)),1); % Prevent interp1 from taking in NaNs as input values
MoMeanfd(:,2) = interp1((depthlist(1:(firstNan-1))+1).', MoMeanfd((depthlist(1:(firstNan-1)).'+1),2),1:length(MoMeanfd),'linear', 'extrap');
    % Interpolate to get missing depths in between and extrapolate to get deeper depths

SSPM = [(0:5000).',inpaint_nans(MoMeanfd(:,2))];
SSPM = array2table(SSPM);
SSPM.Properties.VariableNames = {'Depth' 'SS'};
writetable(SSPM, [saveDirectory,'\', Site, '_SSPM',num2str(sprintf('%02d', minMo)),'.xlsx']) % Save minimum month average SSP

%%
%HZ
% 41.0618; -66.35 (293.6500)
% nearby lats: 227: 41.0400 and 228: 41.0800
% nearby longs: 195: 293.6000 and 196: 293.6800
% long is 238 in length, lat is 301 in length
squeeze(D.temperature(195,227,:)) % goes down to 500
squeeze(D.temperature(195,228,:)) % goes down to 350
squeeze(D.temperature(196,227,:)) % goes down to 1000
squeeze(D.temperature(196,228,:)) % goes down to 800

depthlist(40-9)

squeeze(cdat_sel(200,64,:))