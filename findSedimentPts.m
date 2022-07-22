inputDir = 'H:\My Drive\PropagationModeling';

geosamples_export = readtable(fullfile(inputDir,'geosamples_export_USGSWH.csv'));

site_coords = readtable(fullfile(inputDir,'WAT_SiteLocs.xlsx'));

figure
plot(geosamples_export.LON, geosamples_export.LAT, '.b')
xlim([-85 -65]); ylim([25 45])
hold on
plot(site_coords.Lon, site_coords.Lat, '.r')
hold off

figure
plot(geosamples_export.LON, geosamples_export.LAT, '.','Color',[.9 .9 .9])
xlim([-85 -65]); ylim([25 45])
hold on
for Site = 1:9
selSite_geosamples = nan(height(geosamples_export),2);
for i=1:height(geosamples_export)
    if [distance([site_coords.Lat(Site),site_coords.Lon(Site)],[geosamples_export.LAT(i),geosamples_export.LON(i)])] < 40000
        selSite_geosamples(i,:) = [geosamples_export.LAT(i),geosamples_export.LON(i)];
        disp('A point near the site was chosen!')
    else
    end
end
% plot(site_coords.Lon, site_coords.Lat, '.r')
plot(selSite_geosamples(:,2),selSite_geosamples(:,1), '.b')
plot(site_coords.Lon(Site),site_coords.Lat(Site), '.r')
selSite_geosamples = rmmissing(selSite_geosamples);
length(selSite_geosamples)
end
hold off

height(geosamples_export)

c = [1,2;3,4];