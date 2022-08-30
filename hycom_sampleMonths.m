function hycom_sampleMonths(start_date, end_date, local_outpath, final_outpath)

% Function derived from script ext_hycom_gofs_3_1.m (developed by Ganesh
% Gopalakrishnan)
%
% Required format for dates: 'yyyy-mm-dd HH:MM:SS'
% dd should be 01, i.e. first day of the month.
% HH:MM:SS should be 00:00:00.
% Your local_outpath is a folder on your device.
% Your final_outpath can be the same folder or a folder on GDrive.
%
% hycom_sampleMonths.m is designed to sample HYCOM ocean state data from
% each month in a select time period. For each month, the first day of the
% month is first attempted. Both noon and midnight data must be collected.
% If this cannot be done, the script attempts to use the second day, then
% the third. If the third day has incomplete data, the month is excluded
% from the dataset.
% For a given run, the script will output a text file detailing months
% where the second day was attempted, months where the third day was
% attempted, and months that were excluded.
%
% Note that the script is currently configured for the Western Atlantic
% Ocean.

tic

opath = [local_outpath '\'];
msgbox(['HYCOM MOVED FROM GOMFS 3.0 (32 LEVLS) TO GOFS 3.1 (41 LEVELS)';...
    '                                                             ';...
    'HYCOM GOFS 3.0 extends only upto 2018-11-20                  ';...
    'NEW HYCOM is for every 3 hours!!!!!!                         ';...
    'GRID is changed for this experiment from GLBv0.08            ';...
    '                                                             ';...
    'Hindcast Data: Jul-01-2014 to Apr-30-2016                    ';...
    'https://tds.hycom.org/thredds/dodsC/GLBv0.08/expt_56.3       ';...
    '                                                             ';...
    'Hindcast Data: May-01-2016 to Jan-31-2017                    ';...
    'https://tds.hycom.org/thredds/dodsC/GLBv0.08/expt_57.2       ';...
    '                                                             ';...
    'Hindcast Data: Feb-01-2017 to May-31-2017                    ';...
    'https://tds.hycom.org/thredds/dodsC/GLBv0.08/expt_92.8       ';...
    '                                                             ';...
    'Hindcast Data: Jun-01-2017 to Sep-30-2017                    ';...
    'https://tds.hycom.org/thredds/dodsC/GLBv0.08/expt_57.7       ';...
    '                                                             ';...
    'Hindcast Data: Oct-01-2017 to Dec-31-2017                    ';...
    'https://tds.hycom.org/thredds/dodsC/GLBv0.08/expt_92.9       ';...
    '                                                             ';...
    'Hindcast Data: Jan-01-2018 to Feb-18-2020                    ';...
    'https://tds.hycom.org/thredds/dodsC/GLBv0.08/expt_93.0       ';...
    '                                                             ';...
    'Hindcast Data: Dec-04-2018 to Present *3-hourly*             ';...
    'https://tds.hycom.org/thredds/dodsC/GLBy0.08/expt_93.0       '], 'HYCOM - Info for user')

%% region 24-44N, and -63 - -82W (278-297E)
formatTime = 'yyyy-mm-dd HH:MM:SS';
monthnum = between(datetime(start_date),datetime(end_date), 'months'); %Added by AD to generate monthly values
monthnum = split(monthnum, 'months'); %Added by AD to generate monthly values

%% Create empty time lists for second and third iterations, for files that can be removed, and for excluded months
daysToDelete = double.empty(1,0);
excludedMonths = double.empty(0,1);
time00_2 = []; time12_2 = [];
time00_3 = []; time12_3 = [];

%% start diary
fileOut = [opath 'hycom_download.log'];
diary( [fileOut]);
disp('==========================');
disp(fileOut)

time00_1 = datenum(dateshift(datetime(start_date),'start','month',0:monthnum)); %Added by AD to generate monthly values
time12_1 = datenum(dateshift(datetime(start_date),'start','month',0:monthnum)) + 0.5;

for itr = 1:3  % Loop through iterations
    
    if itr == 1
        time_1 = sort([time00_1 time12_1]); time = time_1;
    elseif itr == 2
        time_2 = sort([time00_2 time12_2]); time = time_2;
    elseif itr == 3
        time_3 = sort([time00_3 time12_3]); time = time_3;
    end
    nt = length(time);
    
    %% we keep the starttime same, only counter is incremented
    % br = 1;
    % old xl: [3476:3714]
    for i = 1:nt % Loop through time points
        f1 = i;
        str_date = datestr(time(i),formatTime);
        
        % there is big jump between two solutions, so using most in recent/latest solution
        eddate = datenum(date);
        stdate = datenum(str_date,formatTime);
        
        if ((datenum(2014,7,1) >= stdate) || (stdate < datenum(2016,5,1)))
            OpenDAP_URL = 'http://tds.hycom.org/thredds/dodsC/GLBv0.08/expt_56.3';
            xl = [1226:1463];yl = [1800:2100];zl = [0:1:39];
            ext_hycom_gofs_93_0(opath,f1,str_date,zl,yl,xl,OpenDAP_URL);
            %%GAP
        elseif ((datenum(2016,5,1) >= stdate) || (stdate < datenum(2017,2,1)))
            OpenDAP_URL = 'http://tds.hycom.org/thredds/dodsC/GLBv0.08/expt_57.2';
            xl = [1226:1463];yl = [1800:2100];zl = [0:1:39];
            ext_hycom_gofs_93_0(opath,f1,str_date,zl,yl,xl,OpenDAP_URL);
            %%GAP
        elseif ((datenum(2017,2,1) >= stdate) || (stdate < datenum(2017,6,1)))
            OpenDAP_URL = 'http://tds.hycom.org/thredds/dodsC/GLBv0.08/expt_92.8';
            xl = [3476:3714];yl = [1800:2100];zl = [0:1:39];
            ext_hycom_gofs_93_0(opath,f1,str_date,zl,yl,xl,OpenDAP_URL);
            
        elseif ((datenum(2017,6,1) >= stdate) || (stdate < datenum(2017,10,1)))
            OpenDAP_URL = 'http://tds.hycom.org/thredds/dodsC/GLBv0.08/expt_57.7';
            xl = [1226:1463];yl = [1800:2100];zl = [0:1:39];
            ext_hycom_gofs_93_0(opath,f1,str_date,zl,yl,xl,OpenDAP_URL);
            %%GAP
        elseif ((datenum(2017,10,1) >= stdate) || (stdate < datenum(2018,1,1)))
            OpenDAP_URL = 'http://tds.hycom.org/thredds/dodsC/GLBv0.08/expt_92.9';
            xl = [3476:3714];yl = [1800:2100];zl = [0:1:39];
            ext_hycom_gofs_93_0(opath,f1,str_date,zl,yl,xl,OpenDAP_URL);
            
        elseif ((datenum(2018,1,1) >= stdate) || (stdate <= datenum(2019,1,1)))
            OpenDAP_URL = 'http://tds.hycom.org/thredds/dodsC/GLBv0.08/expt_93.0';
            xl = [3476:3714];yl = [1800:2100];zl = [0:1:39];
            ext_hycom_gofs_93_0(opath,f1,str_date,zl,yl,xl,OpenDAP_URL);
            
        elseif ((datenum(2019,1,1) >= stdate) || (stdate <= eddate))
            OpenDAP_URL = 'http://tds.hycom.org/thredds/dodsC/GLBy0.08/expt_93.0';
            xl = [3476:3714];yl = [2600:3100];zl = [0:1:39];
            ext_hycom_gofs_93_0(opath,f1,str_date,zl,yl,xl,OpenDAP_URL);
        end
                
        % If a file couldn't be downloaded, add serial number of the following
        % day to the list of dates for the next iteration
        expected_FileName = [num2str(sprintf('%04d', i)), '_', char(datetime(str_date, 'Format', 'yyyyMMdd')), 'T' char(datetime(str_date, 'Format', 'HHmmSS')) '.mat'];
        expected_FilePath = fullfile(opath, expected_FileName);
        
        if ~exist(expected_FilePath, 'file')
            str_dateStart = dateshift(datetime(str_date), 'start', 'day');
            if itr == 1
                disp('Complete data cannot be generated for this date. Will attempt to use second day of month.')
                time00_2 = [time00_2 datenum(str_dateStart)+1];
                time12_2 = [time12_2 datenum(str_dateStart)+1.5];
            elseif itr == 2
                disp('Complete data cannot be generated for this date. Will attempt to use third day of month.')                
                time00_3 = [time00_3 datenum(str_dateStart)+1];
                time12_3 = [time12_3 datenum(str_dateStart)+1.5];
            elseif itr == 3
                disp(['Complete data cannot be generated for this date. This month will not be included in downstream calculations.'])
                excludedMonths = [excludedMonths string(datetime(datenum(str_dateStart), 'ConvertFrom', 'datenum', 'Format', 'yyyy-MM'))];
            end
            daysToDelete = [daysToDelete string(datetime(datenum(str_dateStart), 'ConvertFrom', 'datenum', 'Format', 'yyyyMMdd'))]; % 'Label' this date for deletion
        end
        
%         % Manually mark 01/01/2019 for deletion and add 01/02/2019 to
%         % second iteration (because 01/01/2019 00:00:00 and 12:00:00 have different dimensions)
%         if strcmp(stdate, '2019-01-01 00:00:00')
%             time00_2 = [time00_2 datenum(str_dateStart)+1];
%             time12_2 = [time12_2 datenum(str_dateStart)+1.5];
%         end  %% Take this all out
        
        
    end % End loop through time points
  
    % Check if files of each day have the same dimensions -- if any do not,
    % add them to the next iteration
    
    
end % End loop through iterations

diary off;

% Wrap up by deleting partial data from unused days
filesList = ls(opath);
filesToDelete = filesList(contains(ls(opath), string(daysToDelete)),:);
disp('Deleting incomplete data...')
for d = 1:size(filesToDelete, 1)
    delete(fullfile(opath,strcat(filesToDelete(d,:))))
end

runtime = toc; %Get run time

%% Generate report of run for user -- This doesn't appear to be functioning correctly

txtFileName = ['HYCOM_sM_Report_' char(datestr(datetime('now'), 'yyyymmdd_HHMMSS')) '.txt'];
paramfile = fullfile(opath, txtFileName);
fileid = fopen(paramfile, 'w');
fclose(fileid);
fileid = fopen(paramfile, 'at');
fprintf(fileid, ['hycom_sampleMonths.m output - Report for User'...
    '\nCompleted on ' char(datestr(datetime('now'), 'yyyy-mm-dd HH:MM:SS'))...
    '\n\nRegion:\t24-44N, and -63 - -82W (278-297E)' ...
    '\n\nTime Period Covered:\t' char(datetime(datenum(start_date), 'ConvertFrom', 'datenum', 'Format', 'yyyy-MM-dd')) ' to ' char(datetime(datenum(end_date), 'ConvertFrom', 'datenum', 'Format', 'yyyy-MM-dd'))...
    '\n\nFor the following months, first-day data was missing or incomplete. The second day was attempted.\n' char(datetime(time00_2, 'ConvertFrom', 'datenum', 'Format', 'yyyy-MM'))...
    '\n\nFor the following months, second-day data was also missing or incomplete. The third day was attempted.\n' char(datetime(time00_3, 'ConvertFrom', 'datenum', 'Format', 'yyyy-MM'))...
    '\n\nFor the following months, third-day data was also missing or incomplete. These months have been excluded from the data.\n' char(excludedMonths)]);
fclose(fileid);
    
%% Rename files without numeric prefix

%% Move files to final directory, if it is different from local directory

if ~strcmp(local_outpath, final_outpath)
    %allFiles = ls(fullfile(opath,'*000*'));
    filesList_new = ls(fullfile(opath));
    for k = 1:length(filesList_new)
        movefile(fullfile(opath, filesList_new(k,:)),...
            fullfile(final_outpath, filesList_new(k,:)))
    end
end