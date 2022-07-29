function [] = ext_hycom_gofs_93_0(opath,frame,str_date,z,y,x,OpenDAP_URL)

D = struct('Date', [], 'Depth', [],'Latitude', [], 'Longitude', [],'ssh',[],'u',[],'v',[],'temperature',[],'salinity',[]);

t = num2str(frame);
p = blanks(4 - length(t));p(:) = '0';
frame = [num2str(p) t];
disp (frame)

prec='double';
format = 'yyyy-mm-dd HH:MM:SS';

xmin = x(1);
xmax = x(end);
ymin = y(1);
ymax = y(end);
zmin = z(1);
zmax = z(end);

deltax = xmax - xmin + 1 ;
deltay = ymax - ymin + 1 ;
deltaz = zmax - zmin + 1 ;
Z = zmax+1;
stdate = datenum(str_date,format);

ncid = netcdf.open(OpenDAP_URL,'NOWRITE');
[numdims, numvars, numglobalatts, unlimdimID] = netcdf.inq(ncid);

for varid =1:numvars
    varlist(varid) = {netcdf.inqVar(ncid,varid-1)};
end

%%  First get the hycom date and time
param = 'time';
ind=find(ismember(varlist,param));
Temp_Date = netcdf.getVar(ncid,ind-1,prec);
% time_origin: units: hours since 2000-01-01 00:00:00
% mlab origin: jan 00, 0000
time_origin = datenum(2000,1,1,0,0,0);
Temp_Date = datenum(Temp_Date./24) + time_origin;
time0 = find((Temp_Date==stdate));

if any(time0)
    hycom_time = Temp_Date(Temp_Date==stdate);
    dind = datestr(hycom_time,30);
    D.Date = hycom_time;
else
    disp(['missing date :' datestr(stdate)]);
    return
end

% to make array indicies correct for
% multidimensional arrays that start
% at 0 for opendap
time1 = time0-1;
% will need to update for an array
tmin = time1(1);
tmax = time1(end);
deltat = tmax - tmin + 1 ;

param = 'depth';
ind = find(ismember(varlist,param));
Temp_Depth = netcdf.getVar(ncid,ind-1,prec);
hycom_depth = -1*Temp_Depth;
D.Depth = hycom_depth;

param = 'lat';
ind=find(ismember(varlist,param));
hycom_lat = netcdf.getVar(ncid,ind-1,[ymin],[deltay],prec);
D.Latitude = hycom_lat;

param = 'lon';
ind=find(ismember(varlist,param));
Temp_Lon = netcdf.getVar(ncid,ind-1,[xmin],[deltax],prec);
hycom_lon = Temp_Lon;
if hycom_lon < 0; hycom_lon = hycom_lon + 360; end
D.Longitude = hycom_lon;
D.Longitude = permute(D.Longitude,[2,1]);

%% SSH
params = {'surf_el'};
plab = {'ssh'};
np = length(params);
scale = [0.001];
offset = [0];
missvalue = -30000;
bad = 0;

for ip = 1:np
    param = params{ip};
    lab = plab{ip};
    ind=find(ismember(varlist,param));
    
    tmp = netcdf.getVar(ncid,ind-1,[xmin,ymin,tmin],[deltax,deltay,deltat],prec);
    tmp(tmp == missvalue) = nan;
    tmp = tmp.*scale(ip) + offset(ip);
    tmp(isnan(tmp))= bad;
    
    eval(['D.' lab ' = tmp;']);
    clear tmp param
end

clear tmp scale offset missvalue bad 
netcdf.close(ncid);

%% TS
ncid = netcdf.open(OpenDAP_URL,'NOWRITE');
[numdims, numvars, numglobalatts, unlimdimID] = netcdf.inq(ncid);

for varid =1:numvars
    varlist(varid) = {netcdf.inqVar(ncid,varid-1)};
end

params = {'water_temp', 'salinity'};
plab = {'temperature','salinity'};
np = length(params);
scale = [0.001, 0.001];
offset = [20, 20];
missvalue = -30000;
bad = 0;

for ip = 1:np
    param = params{ip};
    lab = plab{ip};
    ind=find(ismember(varlist,param));
    
    tmp = netcdf.getVar(ncid,ind-1,[xmin,ymin,zmin,tmin],[deltax,deltay,deltaz,deltat],prec);
    tmp(tmp == missvalue) = nan;
    tmp = tmp.*scale(ip) + offset(ip);
    tmp(isnan(tmp))= bad;
    
    eval(['D.' lab ' = tmp;']);
    clear tmp param
end
clear tmp scale offset missvalue bad 
netcdf.close(ncid);

%% UV
ncid = netcdf.open(OpenDAP_URL,'NOWRITE');
[numdims, numvars, numglobalatts, unlimdimID] = netcdf.inq(ncid);

for varid =1:numvars
    varlist(varid) = {netcdf.inqVar(ncid,varid-1)};
end

params = {'water_u', 'water_v'};
plab = {'u','v'};
np = length(params);
scale = [ 0.001, 0.001];
offset = [0, 0];
missvalue = -30000;
bad = 0;

for ip = 1:np
    param = params{ip};
    lab = plab{ip};
    ind=find(ismember(varlist,param));
    
    tmp = netcdf.getVar(ncid,ind-1,[xmin,ymin,zmin,tmin],[deltax,deltay,deltaz,deltat],prec);
    tmp(tmp == missvalue) = nan;
    tmp = tmp.*scale(ip) + offset(ip);
    tmp(isnan(tmp))= bad;
    
    eval(['D.' lab ' = tmp;']);
    clear tmp param
end
clear tmp scale offset missvalue bad tmin tmax deltat time1 time0
netcdf.close(ncid);

show = 1;
if show
    figure(1)
    tmp = D.ssh;
    subplot(2,3,1);imagesc(D.Longitude,D.Latitude,tmp');colorbar
    set(gca,'YDir','Normal');title('SSH');
    tmp = D.temperature;tmp = squeeze(tmp(:,:,1));
    subplot(2,3,2);imagesc(D.Longitude,D.Latitude,tmp');colorbar
    set(gca,'YDir','Normal');title('Temperature');
    tmp = D.salinity;tmp = squeeze(tmp(:,:,1));
    subplot(2,3,3);imagesc(D.Longitude,D.Latitude,tmp');colorbar;caxis([28 max(max(tmp))]);
    set(gca,'YDir','Normal');title('Salinity');
    tmp = D.u;tmp = squeeze(tmp(:,:,1));
    subplot(2,3,4);imagesc(D.Longitude,D.Latitude,tmp');colorbar
    set(gca,'YDir','Normal');title('U-Velocity');
    tmp = D.v;tmp = squeeze(tmp(:,:,1));
    subplot(2,3,5);imagesc(D.Longitude,D.Latitude,tmp');colorbar
    set(gca,'YDir','Normal');title('V-Velocity');
    clear tmp
end
%pause
%% saving orginal HYCOM  fields into mat file
varList = 'D';
savename = [opath frame '_' dind '.mat'];
eval(['save ',savename,' ',varList]);


