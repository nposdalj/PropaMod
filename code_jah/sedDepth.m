ncdisp('G:\My Drive\PropagationModeling_GDrive\GlobSed\GlobSed_package3\GlobSed-v3.nc')

hydLoc = [41.0618  -66.3500];

z  = ncread('G:\My Drive\PropagationModeling_GDrive\GlobSed\GlobSed_package3\GlobSed-v3.nc','z');
lat = ncread('G:\My Drive\PropagationModeling_GDrive\GlobSed\GlobSed_package3\GlobSed-v3.nc','lat');
lon = ncread('G:\My Drive\PropagationModeling_GDrive\GlobSed\GlobSed_package3\GlobSed-v3.nc','lon');

if hydLoc(1) > 0
    [val1,idx1]=min(abs(lat-hydLoc(1)));
    minVal1=lat(idx1);
else
    [val1,idx1]=min(abs(lat+hydLoc(1)));
    minVal1=-lat(idx1);
    idx1=find(lat==minVal1);
end
if hydLoc(2) > 0
    [val2,idx2]=min(abs(lon-hydLoc(2)));
    minVal2=lon(idx2);
else
    [val2,idx2]=min(abs(lon+hydLoc(2)));
    minVal2=-lon(idx2);
    idx2=find(lon==minVal2);
end



