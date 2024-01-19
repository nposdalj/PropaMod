% Developed for R2021b

clearvars
close all

%% Params defined by user

region = 'WAT';
GDrive = 'G';
inputDir = [GDrive,':\My Drive\PropagationModeling'];

geosamples_export = readtable(fullfile(inputDir,'IMLGS_SPATIAL_QUERY_RESULTS','IMLGS_SPATIAL_QUERY_RESULTS.csv'));

site_coords = readtable(fullfile(inputDir,'WAT_SiteLocs.xlsx'));
sites = char(site_coords.Site);

plotLons = [-85 -65];
plotLats = [25 45];

%% Plot all available data points with site coordinates overlaid in red

figure(1)
plot(geosamples_export.LON, geosamples_export.LAT, '.b') % Plot all data points in BLUE
hold on
plot(site_coords.Lon, site_coords.Lat, '.r')             % Plot all sites in RED
plot(site_coords.Lon, site_coords.Lat, 'or')
hold off

%% Generate geosamples_sediment - All the sample points that actually have sediment data (from column: TEXT1)

geosamples_sediment = [geosamples_export.LAT, geosamples_export.LON, nan(length(geosamples_export.LAT),1)]; % Array: Lat, Lon, empty column for sediment type
geosamples_sediment = array2table(geosamples_sediment); % Convert to table
geosamples_sediment.Properties.VariableNames = {'LAT' 'LON' 'SEDIMENT'}; % Assign col names
geosamples_sediment.SEDIMENT = geosamples_export.TEXT1; % Drop sediment types into SEDIMENT column
geosamples_sediment = rmmissing(geosamples_sediment); % Exclude points with no sediment type listed

%% For each site, find the sediment type at the nearest sample point with sediment data

siteSedimentsClosest = [site_coords.Site cellstr(repmat('NONE', length(site_coords.Site),1))]; % Array: Site Name, empty column for nearest sediment
for Site = 1:length(site_coords.Site) % Loop through sites
    distances = distance([site_coords.Lat(Site) site_coords.Lon(Site)], [geosamples_sediment.LAT geosamples_sediment.LON]); % Calculate distance between site coords and all sediment point coords
    [closest_distance, closest_index] = min(distances); % Find distance and index of the nearest point with sediment data
    siteSedimentsClosest(Site,2) = geosamples_sediment.SEDIMENT(closest_index); % Drop nearest sediment type into siteSedimentsClosest
end
siteSedimentsClosest = array2table(siteSedimentsClosest); % Convert to table
siteSedimentsClosest.Properties.VariableNames = {'Site' 'Sediment'};

%% Generate subsets of points that are near each site

for Site = 1:9 % Cycle through sites
    selSite_geosamples = nan(height(geosamples_sediment),3); % Generate selSite_geosamples, an empty list same length as geosamples_sediment.
    %   Sediment points that are close enough to the site (within 40 km) will be dropped here.
    for i=1:height(geosamples_sediment) % Cycle through sediment points
        if [distance([site_coords.Lat(Site),site_coords.Lon(Site)],[geosamples_sediment.LAT(i),geosamples_sediment.LON(i)])] < 40000 % Is this sediment point within 40 km of the site?
            selSite_geosamples(i,:) = [i, geosamples_sediment.LAT(i),geosamples_sediment.LON(i)]; % If yes, assign it to this subset
        else % Otherwise, do nothing
        end
    end
    selSite_geosamples = rmmissing(selSite_geosamples); % Remove rows for points that are further away than 40 km;
    
    site_IndicesAndLocation = array2table(selSite_geosamples); % Convert list of nearby sediment points to table "site_IndicesAndLocation"
    site_Sediments = array2table(geosamples_sediment.SEDIMENT(selSite_geosamples(:,1))); % Make table: Simple list of sediments near site, without lat/lon
    SedDat.(sites(Site,:)) = [site_IndicesAndLocation site_Sediments];   % <- Drop into structure SedDat: Where site-specific sediment data are saved
    SedDat.(sites(Site,:)).Properties.VariableNames = {'Index' 'LAT' 'LON' 'SEDIMENT'}; % Name columns
    
    disp(['Sediment analysis completed for Site: ' sites(Site,:)]) % Status update for user
end

%% Plot points that are nearby each site (within 40 km)

figure(2)
plot(geosamples_sediment.LON, geosamples_sediment.LAT, '.','Color',[.9 .9 .9]) % Plot all points that have sediment data -- in gray
xlim(plotLons); ylim(plotLats) % Specify plot max/min lats and lons
hold on

for Site = 1:9
    plot(SedDat.(sites(Site,:)).LON, SedDat.(sites(Site,:)).LAT, '.b') % Plot sediment points near this site on map, in BLUE
    plot(site_coords.Lon(Site),site_coords.Lat(Site), '.r') % Plot the site on the map, in RED
end

hold off

%% Calculate proportion of each sediment at each site
% Make a table with all sediment types in geosamples_sediment on the
% horizontal axis, all sites on the vertical, and what percentage each
% sediment makes up at each site

sedNames = unique(geosamples_sediment.SEDIMENT); % Get all unique sediment types in geosamples_sediment
sedArray_c = nan(length(site_coords.Site),length(sedNames)); % COUNT: Empty array, width = # sediments, height = # sites
sedArray_p = nan(length(site_coords.Site),length(sedNames)); % PROPORTION: Empty array, width = # sediments, height = # sites

for Site = 1:length(site_coords.Site) % Cycle through sites and fill in array with amount/fraction each sediment takes up at each site
    for Sediment = 1:length(sedNames) % Cycle through sediment types
        sedArray_c(Site,Sediment) = sum(strcmp(SedDat.(sites(Site,:)).SEDIMENT, sedNames(Sediment))); % Add count of this sediment to respective site column in sedArray_c
        sedArray_p(Site,Sediment) = 100*sum(strcmp(SedDat.(sites(Site,:)).SEDIMENT, sedNames(Sediment)))...
            /length(SedDat.(sites(Site,:)).SEDIMENT); % Add proportion of this sediment to respective site column in sedArray_p
    end
end

sedTable = array2table(sedArray_p); % Handy table of sediment percentages (but array will be used for plotting)
sedNames_tabTitles = strrep(sedNames,' ','_'); % Cell array of table column names (sediment types)
sedTable.Properties.VariableNames = sedNames_tabTitles;

%% Plot proportion of each sediment at each site

siteList_cat = categorical(cellstr(sites)); % Define a categorical array version of siteList (learn more abt this!)
sedimentBars = figure(3); % Bar plot of sediment proportions at each site
set(gcf,'Position',[100,100,1000,600])
colormap(sedimentBars,colorcube) % Set colormap
sedbars = bar(sedArray_p, 'stacked'); % Make bar plot using sedArray_p data
set(gca,'xticklabel',sites)
sedimentLegend = legend(sedNames);
set(sedimentLegend,'Location','eastoutside')
ylabel('Percent'); title(['Sediment Representation at ' region ' Sites']);
ylim([0 110])
for i=1:length(sites)
    text(i, 105, ['n=' num2str(sum(sedArray_c(i,:).'))], 'HorizontalAlignment','center')
end
