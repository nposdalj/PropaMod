% plotSSP
% Plot Sound Speed Profile for region of choice.
% Configured for use with HYCOM's files
% Latitudes and longitudes are configured for Western Atlantic (WAT). To
% change this, make edits in ext_hycom_gofs_3_1.m.

% AD: HYCOM data provides data points for every 1/12 degree. I believe 
% that is at most every ~9.25 km. This MIGHT allow us to see significant
% differences in sound speed across a 20-km range, but given such a low
% resolution, I think those differences will be somewhat imprecise.

clearvars
close all
    
%% Parameters defined by user
% Before running, make sure desired data has been downloaded from HYCOM
% using ext_hycom_gofs_3_1.m.
Site = 'NC';
regionabrev = 'WAT';

GDrive = 'H'; FilePath = [GDrive ':\My Drive\PropagationModeling\HYCOM_data'];
fileNames_all = ls(fullfile(FilePath, '*0*')); % File name to match.
saveDirectory = [GDrive ':\My Drive\PropagationModeling\SSPs'];

% Add site data below: siteabrev, lat, long
siteabrev = ['NC';       'BC';       'GS';       'BP';       'BS';      'WC';       'OC';       'HZ';       'JX'];
Latitude  = [39.8326;    39.1912;    33.6675;    32.1061;    30.5833;   38.3738;    40.2550;    41.0618;    30.1523]; %jax avg is for D_13, 14, 15 only
Longitude = [-69.9800;   -72.2300;   -76;        -77.0900;   -77.3900;  -73.37;     -67.99;     -66.35;     -79.77];
HydDepth  = [950;        950;        950;        950;        950;       950;        950;        950;        950];

MonthStart = '201507';  % First month of study period (yyyymm)
MonthEnd = '201906';    % Last month of study period (yyyymm)
fileNames = fileNames_all(find(contains(fileNames_all,MonthStart)):find(contains(fileNames_all,MonthEnd)),:);

%% Overarching loop runs through all timepoints requested
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
for i=1:length(siteabrev)
    numdepths = nan(1,length(depthlist));
    
    for j=1:length(depthlist) %interpolate sound speed grid at each depth to infer sound speed values at site coordinates
        %numdepths(j) = interp2(D.Longitude,flip(D.Latitude),cdat_sel(:,:,j),siteCoords(i,2),siteCoords(i,1).');
        numdepths(j) = interp2(D.Longitude,flip(D.Latitude),cdat(:,:,j),siteCoords(i,2),siteCoords(i,1).');

    end
%     figure(200+i)
%     plot(numdepths, -depthlist,'-o')
%     xlabel('Sound Speed (m/s)'); ylabel('Depth (m)')
%     %title(['SSP at ', char(siteabrev(i)),' | ', num2str(siteCoords(i,1)),char(176), 'N, ', num2str(siteCoords(i,2)),char(176), 'E'])
%     title(['SSP at ', char(siteabrev(i)),' | ', timestamp])
%     set(gcf,'Position',[(155*i - 150) 100 300 600])
%     %saveas(gcf,[saveDirectory,'\',char(plotDate),'_',char(siteabrev(i)),'_SSP'],'png');
    
    SSP_table(:,i+1) = numdepths;
end


ALL_SSParray(:,:,(12*(str2num(fileNames(k,6:9))-str2num(fileNames(1,6:9)))+str2num(fileNames(k,10:11))-str2num(fileNames(1,10:11))+1)) = SSP_table; % Array version of ALL_SSP - used for actual data assembly below

SSP_table = array2table(SSP_table);
SSP_table.Properties.VariableNames = {'Depth' char(siteabrev(1,:)) char(siteabrev(2,:)) char(siteabrev(3,:)) char(siteabrev(4,:)) char(siteabrev(5,:)) char(siteabrev(6,:)) char(siteabrev(7,:)) char(siteabrev(8,:)) char(siteabrev(9,:))};
%writetable(SSP_table,[saveDirectory,'\', 'SSP_', regionabrev, '_', fileName(strfind(fileName,'_')+1:end), '.xlsx'])

ALL_SSP.(['M',fileNames(k,6:11)]) = SSP_table; % All the data from all time points and all sites is stored in ALL_SSP
disp([fileName, ' - Extracted SSPs and added to ALL_SSP as M' fileNames(k,6:11)])

end


M01.mean = nanmean(ALL_SSParray(:,:,[12*(YearNums-1)+7]),3);   M01.std = nanstd(ALL_SSParray(:,:,[12*(YearNums-1)+7]),0,3);
M02.mean = nanmean(ALL_SSParray(:,:,[12*(YearNums-1)+8]),3);   M02.std = nanstd(ALL_SSParray(:,:,[12*(YearNums-1)+8]),0,3);
M03.mean = nanmean(ALL_SSParray(:,:,[12*(YearNums-1)+9]),3);   M03.std = nanstd(ALL_SSParray(:,:,[12*(YearNums-1)+9]),0,3);
M04.mean = nanmean(ALL_SSParray(:,:,[12*(YearNums-1)+10]),3);  M04.std = nanstd(ALL_SSParray(:,:,[12*(YearNums-1)+10]),0,3);
M05.mean = nanmean(ALL_SSParray(:,:,[12*(YearNums-1)+11]),3);  M05.std = nanstd(ALL_SSParray(:,:,[12*(YearNums-1)+11]),0,3);
M06.mean = nanmean(ALL_SSParray(:,:,[12*(YearNums-1)+12]),3);  M06.std = nanstd(ALL_SSParray(:,:,[12*(YearNums-1)+12]),0,3);
M07.mean = nanmean(ALL_SSParray(:,:,[12*(YearNums-1)+1]),3);   M07.std = nanstd(ALL_SSParray(:,:,[12*(YearNums-1)+1]),0,3);
M08.mean = nanmean(ALL_SSParray(:,:,[12*(YearNums-1)+2]),3);   M08.std = nanstd(ALL_SSParray(:,:,[12*(YearNums-1)+2]),0,3);
M09.mean = nanmean(ALL_SSParray(:,:,[12*(YearNums-1)+3]),3);   M09.std = nanstd(ALL_SSParray(:,:,[12*(YearNums-1)+3]),0,3);
M10.mean = nanmean(ALL_SSParray(:,:,[12*(YearNums-1)+4]),3);   M10.std = nanstd(ALL_SSParray(:,:,[12*(YearNums-1)+4]),0,3);
M11.mean = nanmean(ALL_SSParray(:,:,[12*(YearNums-1)+5]),3);   M11.std = nanstd(ALL_SSParray(:,:,[12*(YearNums-1)+5]),0,3);
M12.mean = nanmean(ALL_SSParray(:,:,[12*(YearNums-1)+6]),3);   M12.std = nanstd(ALL_SSParray(:,:,[12*(YearNums-1)+6]),0,3);

SSPM_export = [[depthlist].',inpaint_nans(M04.mean(:,2))];
SSPM = array2table(SSPM01_NC);
SSPM01_NC.Properties.VariableNames = {'Depth' 'SS'};
writetable(SSPM01_NC, [saveDirectory,'\', 'NC_SSPM04.xlsx'])

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