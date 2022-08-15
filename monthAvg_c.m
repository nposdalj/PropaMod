clearvars
close all

% monthAvg_c.m
% Converts HYCOM data from LMB's app into monthly average arrays

% The HYCOM files take up quite a bit of storage -- to conserve storage,
% delete the HYCOM .nc4 files after you have processed your data and
% checked the output is acceptable.

%% Parameters defined by user
author = 'AD';

Region = 'WAT';

inDir = 'C:\Users\HARP\Documents\test_appoutput2';
saveDir = '';

%% Get dataset parameters

LonVec = ncread(fullfile(inDir, 'HYCOM_water_temp_0m_20150701_20160930.nc4'), 'lon');
LatVec = ncread(fullfile(inDir, 'HYCOM_water_temp_0m_20150701_20160930.nc4'), 'lat');
RegionCoords = [num2str(LonVec(1)) char(176) 'E - ' num2str(LonVec(end)) char(176) 'E, '...
    num2str(LatVec(1)) char(176) 'N - ' num2str(LatVec(end)) char(176) 'N']; % why is there a .04 wth

%% Script body

depthlist = [0,2,4,6,8,10,12,15,20,25,30,35,40,45,50,60,70,80,90,100,...
    125,150,200,250,300,350,400,500,600,700,800,900,1000,...
    1250,1500,2000,2500,3000,4000,5000];

% Need to compress every-3-hour values in salvar1507_1609 into daily
% averages -- I think there won't be enough memory without this
% Update: Might not even be enough memory for that, so go ahead and compress to
% MONTHLY averages instead
% Note to self -- along with checking monthly variation in sound speed
% for sites, it might be good to check day-night fluctuations too... esp at
% the depths we are interested in.

% Start by making large array for all data for sound speed
inDir_files_all = ls(inDir);
inDir_files = inDir_files_all(contains(inDir_files_all, 'HYCOM'), :);
startYear = str2double(cellstr(inDir_files(1,21:24)));
startMonth = str2double(cellstr(inDir_files(1,25:26)));
endYear = str2double(cellstr(inDir_files(end,30:33)));
endMonth = str2double(cellstr(inDir_files(end,34:35)));
monthNum = 12*(endYear - startYear) + endMonth - startMonth + 1;

dims = size(ncread(fullfile(inDir, 'HYCOM_water_temp_0m_20150701_20160930.nc4'), 'water_temp'));
longNum = dims(1); latNum = dims(2); depthNum = 40;

data_c = nan(longNum, latNum, depthNum, monthNum);


for d = 1:40 % Cycle through depth layers
    for t = 1:6 % Cycle through time periods
        for v = 1:2 % Cycle through variables: Salinity and Water Temperature
            
            % 4 dimensions: Long x Lat x Depth x Time
            data_dtvII = ncread(fullfile(inDir, 'HYCOM_water_temp_0m_20150701_20160930.nc4'), 'water_temp');
            data_dtvI = squeeze(data_dtvII); % New dimensions: Lon x Lat x Time
            clear data_dtvII
            
            % Along Time dimension, at each lat and long, take monthly averages
            % (each is the average of between 28*8 and 31*8 time points) and drop in a new
            % array that is pre-sized for the number of months in the time period
            data_dtvI_hours = ncread(fullfile(inDir, ['HYCOM_water_temp_' num2str(depthlist(d)) 'm_20150701_20160930.nc4']), 'time');
            data_dtvI_posix = (data_dtvI_hours)*3600+(30*365*24*3600)+(7*24*3600); clear data_dtvI_hours
            
            data_dtvI_ymdat = datetime(data_dtvI_posix,'ConvertFrom', 'posixtime','Format', 'yyMM');
            data_dtvI_ym = str2double(cellstr(datestr(data_dtvI_ymdat, 'yymm')));
            data_dtvI_ymu = unique(str2double(cellstr(datestr(data_dtvI_ymdat, 'yymm'))));
            clear data_dtvI_posix data_dtvI_ymdat data_dtvI_ym
            
            data_dtv = nan(size(data_dtvI, 1), size(data_dtvI, 2), length(data_dtvI_ymu)); % Empty array into which monthly Lon x Lat arrays will be dropped
            
            for month = 1:length(data_dtvI_ymu)
                timePts = find(data_dtvI_ym==data_dtvI_ymu(month)); % Find all time positions in this month
                data_dtvI_mX = data_dtvI(:,:,timePts(1):timePts(end)); % Make subset of data_vdtI for this month
                data_dtv_mX = mean(data_dtvI_mX, 3); % Average across Time dimension
                data_dtv(:,:,month) = data_dtv_mX; % Drop month array into the all-months array
                clear timePts data_dtvI_mX data_dtv_mX
            end
            disp('Generated monthly average data: Time period 1, Depth Level 1, Variable water_temp')
            clear data_dtvI
            
            if v == 1 % (Salinity)
                data_dtS = data_dtv;
            elseif v == 2 % (Water Temp)
                data_dtT = data_dtv;
            end
            clear data_dtv
        end
        
        
        % Combine salinity and water_temp into sound speed
        data_dt = salt_water_c(data_dtT, depthlist(d), data_dtS);
        clear data_dtS data_dtT
        
        % Find tMonths, the month numbers in data_salinity or
        % data_watertemp where this data should be placed
        t_firstYear = str2double(cellstr(inDir_files(t,21:24)));
        t_firstMonth = str2double(cellstr(inDir_files(t,25:26)));
        tMonth1 = t_firstYear - startYear + t_firstMonth - startMonth + 1;
        tMonths = tMonth1:(tMonth1 + length(data_dtvI_ymu) - 1);
        clear data_dtvI_ymu
        
        
        % Drop data in data_c
        data_c(:,:,d,tMonths) = data_dt;
            % NOTE - will probably have to reshape (so as to reverse-squeeze) data_dt first to bring back depth dimension
        disp(['Placed data in data_c: Depth = ' num2str(depthlist(d)) 'm, Experiment [timePeriod].'])
        
    end
end

save([saveDir, '\' Region '_HYCOMc_' num2str(startYear) num2str(sprintf('%02d', startMonth)) '_'...
    num2str(endYear) num2str(sprintf('%02d', endMonth-1))],'data_c', 'xlsx')

% HYCOM EXPERIMENT PERIODS:
% 2014/07 - 2016/09
% 2016/10 - 2017/01
% 2017/02 - 2017/05
% 2017/06 - 2017/09
% 2017/10 - 2017/12
% 2018/01 - Present (? at least through 2019/07)

% btw figure out if can download all 8 hours on last day in each time
% period rather than just the 1st... unless next one includes it. (I
% checked, and, no, it doesn't. Could maybe ask Lauren abt this)
