clearvars
close all

region = 'WAT';

GDrive = 'G';
inputDir = [GDrive,':\My Drive\PropagationModeling'];

geosamples_export = readtable(fullfile(inputDir,'IMLGS_SPATIAL_QUERY_RESULTS','IMLGS_SPATIAL_QUERY_RESULTS.csv'));

site_coords = readtable(fullfile(inputDir,'WAT_SiteLocs.xlsx'));
siteList = char(site_coords.Site);

figure
plot(geosamples_export.LON, geosamples_export.LAT, '.b')
hold on
plot(site_coords.Lon, site_coords.Lat, '.r')
plot(site_coords.Lon, site_coords.Lat, 'or')
hold off

% figure
% plot(geosamples_export.LON, geosamples_export.LAT, '.','Color',[.9 .9 .9])
% xlim([-85 -65]); ylim([25 45])
% hold on
% clear site_sediments
% for Site = 1:9
% selSite_geosamples = nan(height(geosamples_export),2);
% for i=1:height(geosamples_export);
%     if [distance([site_coords.Lat(Site),site_coords.Lon(Site)],[geosamples_export.LAT(i),geosamples_export.LON(i)])] < 40000
%         selSite_geosamples(i,:) = [geosamples_export.LAT(i),geosamples_export.LON(i)];
%     else
%     end
% end
% % plot(site_coords.Lon, site_coords.Lat, '.r')
% plot(selSite_geosamples(:,2),selSite_geosamples(:,1), '.b')
% plot(site_coords.Lon(Site),site_coords.Lat(Site), '.r')
% selSite_geosamples = rmmissing(selSite_geosamples);%site_coords
% 
% ptIndices = nan(0,1); %nan(size(selSite_geosamples, 1),1);
% for point = 1:size(selSite_geosamples, 1) %find the geosamples_export indices of the points close to the site
%     pti = find(geosamples_export.LAT == selSite_geosamples(point,1) & ...
%         geosamples_export.LON == selSite_geosamples(point,2));
%     ptIndices = [ptIndices; pti]; %Attached pti to the end of ptIndices instead of preallocating, which would be a problem;
%                                   %This is because some point coords are associated with more than one index, and more 
%                                   %than one sediment type.
%                                   % check that this works...
% end
% site_sediments.(siteList(Site,:)) = array2table([ptIndices, nan(length(ptIndices),1)]);
% site_sediments.(siteList(Site,:)).Properties.VariableNames = {'Index' 'Sediment'};
% site_sediments.(siteList(Site,:)).Sediment = geosamples_export.TEXT1(ptIndices); % Get the sediment types at these points
% 
% %site_sediments.(siteList(Site,:)) = rmmissing(site_sediments.(siteList(Site,:)));
% disp(['Site completed: ' siteList(Site,:)])
% end
% hold off

% Make a secondary process that examines the point coordinates of the
% indices that actually have sediment data and finds the one with the least
% distance from the site, and assigns that sediment type to the site.

% Investigate the nearest points one by one, in order of closeness, until a
% point with sediment data is found.

% First make a version of geosamples_export with only lat, lon, and sediment type,
% then remove all rows w/o sediment type.
% The points in this version will have different indices than
% geosamples_export.
geosamples_sediment = [geosamples_export.LAT, geosamples_export.LON, nan(length(geosamples_export.LAT),1)];
geosamples_sediment = array2table(geosamples_sediment);
geosamples_sediment.Properties.VariableNames = {'LAT' 'LON' 'SEDIMENT'};
geosamples_sediment.SEDIMENT = geosamples_export.TEXT1;
geosamples_sediment = rmmissing(geosamples_sediment);

siteSedimentsClosest = [site_coords.Site cellstr(repmat('NONE', length(site_coords.Site),1))];
for Site = 1:length(site_coords.Site)
    distances = distance([site_coords.Lat(Site) site_coords.Lon(Site)], [geosamples_sediment.LAT geosamples_sediment.LON])
    [closest_distance closest_index] = min(distances);
    siteSedimentsClosest(Site,2) = geosamples_sediment.SEDIMENT(closest_index);
end
siteSedimentsClosest = array2table(siteSedimentsClosest);
siteSedimentsClosest.Properties.VariableNames = {'Site' 'Sediment'}

%%

figure
plot(geosamples_sediment.LON, geosamples_sediment.LAT, '.','Color',[.9 .9 .9])
xlim([-85 -65]); ylim([25 45])
hold on
clear SedDat
for Site = 1:9
selSite_geosamples = nan(height(geosamples_sediment),3);
for i=1:height(geosamples_sediment);
    if [distance([site_coords.Lat(Site),site_coords.Lon(Site)],[geosamples_sediment.LAT(i),geosamples_sediment.LON(i)])] < 40000
        selSite_geosamples(i,:) = [i, geosamples_sediment.LAT(i),geosamples_sediment.LON(i)]; % Assigns points within 40km of the site to this subset
    else
    end
end
% plot(site_coords.Lon, site_coords.Lat, '.r')
plot(selSite_geosamples(:,3),selSite_geosamples(:,2), '.b')
plot(site_coords.Lon(Site),site_coords.Lat(Site), '.r')
selSite_geosamples = rmmissing(selSite_geosamples); %Remove points that are beyond 40 km

site_IndicesAndLocation = array2table(selSite_geosamples);
site_Sediments = array2table(geosamples_sediment.SEDIMENT(selSite_geosamples(:,1)));
SedDat.(siteList(Site,:)) = [site_IndicesAndLocation site_Sediments];
SedDat.(siteList(Site,:)).Properties.VariableNames = {'Index' 'LAT' 'LON' 'SEDIMENT'};

% site_sediments.(siteList(Site,:)) = array2table([ptIndices, nan(length(ptIndices),1)]);
% site_sediments.(siteList(Site,:)).Properties.VariableNames = {'Index' 'Sediment'};
% site_sediments.(siteList(Site,:)).Sediment = geosamples_sediment.SEDIMENT(ptIndices); % Get the sediment types at these points

%site_sediments.(siteList(Site,:)) = rmmissing(site_sediments.(siteList(Site,:)));

% Type = unique(SedDat.(siteList(Site,:)).SEDIMENT); % This was cool but I'm commenting it out cuz sedTable and sedArray make it obsolete
% TypeCount = nan(length(Type),1);
% siteSedProportions = [array2table(Type) array2table(TypeCount)];
% for type = 1:length(Type)
%     siteSedProportions.TypeCount(type) = sum(strcmp(SedDat.(siteList(Site,:)).SEDIMENT, Type(type)));
% end
% TypeCounts.(siteList(Site,:)) = siteSedProportions;

disp(['Site completed: ' siteList(Site,:)])
end
hold off
% 
% for Site = 1:length(site_coords.Site)
% figure
% pie(TypeCounts.(siteList(Site,:)).TypeCount,TypeCounts.(siteList(Site,:)).Type)
% title(siteList(Site,:))
% end
% 
% sedimentPie = figure(1);
% set(gcf,'Position',[100,50,1200,700]) % note to self, learn dif btwn gcf and gca
% colormap(sedimentPie,hot)
% for Site = 1:length(site_coords.Site)
% subplot(3,3,Site)
% pie(TypeCounts.(siteList(Site,:)).TypeCount)
% title(siteList(Site,:))
% sedNames = unique(TypeCounts.(siteList(Site,:)).Type);
% sedimentLegend = legend(sedNames);
% end

% Make a table with all sediment types in geosamples_sediment on the
% horizontal axis, all sites on the vertical, and what percentage each
% sediment makes up at each site
% Makes two versions: One for direct counts, one for percentages

sedNames = unique(geosamples_sediment.SEDIMENT); % Get all sediment types in geosamples_sediment
sedArray = nan(length(site_coords.Site),length(sedNames)); % Empty array, width = # sediments, height = # sites
sedArray_p = nan(length(site_coords.Site),length(sedNames)); % Empty array, width = # sediments, height = # sites
for Site = 1:length(site_coords.Site) % Fill in array with fraction each sediment at each site
    for Sediment = 1:length(sedNames)
        sedArray(Site,Sediment) = sum(strcmp(SedDat.(siteList(Site,:)).SEDIMENT, sedNames(Sediment)));
        sedArray_p(Site,Sediment) = 100*sum(strcmp(SedDat.(siteList(Site,:)).SEDIMENT, sedNames(Sediment)))...
            /length(SedDat.(siteList(Site,:)).SEDIMENT);
    end
end

sedTable = array2table(sedArray); % This makes table for examining data, but array will be used for plotting
sedTable_p = array2table(sedArray_p); % This makes table for examining data, but array will be used for plotting


sedNames_tabTitles = strrep(sedNames,' ','_');
sedTable = array2table(sedArray_p); % This makes table for examining data, but array will be used for plotting
sedTable_p.Properties.VariableNames = sedNames_tabTitles;

siteList_cat = categorical(cellstr(siteList)); % Define a categorical array version of siteList (learn more abt this!)
sedimentBars = figure(3);
set(gcf,'Position',[100,100,1000,600])
colormap(sedimentBars,colorcube)
sedbars = bar(sedArray_p, 'stacked');
set(gca,'xticklabel',siteList)
sedimentLegend = legend(sedNames);
set(sedimentLegend,'Location','eastoutside')
ylabel('Percent'); title(['Sediment Representation at ' region ' Sites']);
ylim([0 110])
for i=1:length(siteList)
    text(i, 105, ['n=' num2str(sum(sedArray(i,:).'))], 'HorizontalAlignment','center')
end

% examine_tab = [geosamples_export.SAMPLE, geosamples_export.TEXT1];
% 
% sedMap = figure(4);
% colorcube_cols = colorcube;
% gscatter(geosamples_export.LON, geosamples_export.LAT, geosamples_export.TEXT1, colorcube_cols)
