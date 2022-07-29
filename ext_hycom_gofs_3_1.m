clear all
%close all
clc

opath = 'C:\Users\HARP\Documents\MATLAB\Propagation_Modelling\GDr_Intermediate\';

%% HYCOM moved from GOMFS 3.0 (32 levels) to GOFS 3.1(41 levels)
% HYCOM GOFS 3.0 extends only upto 2018-11-20
% NEW HYCOM is for every 3 hours!!!!!!
% GRID is changed for this experiment from GLBv0.08

% Hindcast Data: Jul-01-2014 to Apr-30-2016
% https://tds.hycom.org/thredds/dodsC/GLBv0.08/expt_56.3

% Hindcast Data: May-01-2016 to Jan-31-2017
% https://tds.hycom.org/thredds/dodsC/GLBv0.08/expt_57.2

% Hindcast Data: Feb-01-2017 to May-31-2017
% https://tds.hycom.org/thredds/dodsC/GLBv0.08/expt_92.8

% Hindcast Data: Jun-01-2017 to Sep-30-2017
% https://tds.hycom.org/thredds/dodsC/GLBv0.08/expt_57.7

% Hindcast Data: Oct-01-2017 to Dec-31-2017
% https://tds.hycom.org/thredds/dodsC/GLBv0.08/expt_92.9

% Hindcast Data: Jan-01-2018 to Feb-18-2020
% https://tds.hycom.org/thredds/dodsC/GLBv0.08/expt_93.0

% Hindcast Data: Dec-04-2018 to Present *3-hourly*
% https://tds.hycom.org/thredds/dodsC/GLBy0.08/expt_93.0

%% region 24-44N, and -63 - -82W (278-297E)
format = 'yyyy-mm-dd HH:MM:SS';
start_date = '2014-07-01 12:00:00';
end_date = '2022-07-01 12:00:00';
%date_inc = datenum(0,0,0,24,0,0);
monthnum = between(datetime(start_date),datetime(end_date), 'months'); %Added by AD to generate monthly values
monthnum = split(monthnum, 'months'); %Added by AD to generate monthly values

%% start diary
fileOut = ['H:\My Drive\PropagationModeling\HYCOM_data\' 'hycom_download.log' ];
diary( [fileOut]);
disp('==========================');
disp(fileOut)

%time = [datenum(start_date,format):date_inc:datenum(end_date,format)];
time = datenum(dateshift(datetime(start_date),'start','month',0:monthnum)); %Added by AD to generate monthly values
nt = length(time);
%% we keep the starttime same, only counter is incremented
br = 1;
% old xl: [3476:3714]
for i = 1:nt
    f1 = i;
    str_date = datestr(time(i),format);
    
    % there is big jump between two solutions, so using most in recent/latest solution
    eddate = datenum(date);
    stdate = datenum(str_date,format);
    
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
    
    
end

diary off;

allFiles = ls(fullfile(opath,'*000*'));
for k = 1:length(allFiles)
    movefile([fullfile(opath, allFiles(k,:))],...
        [fullfile('H:\My Drive\PropagationModeling\HYCOM_data', allFiles(k,:))])
end