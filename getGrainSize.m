function radGrainSize = getGrainSize(sedDatType, sedDatPath, hydLoc, distDeg, total_range, radials, plotDir, rangeStep);
% Built in R2022b
% Get grain sizes of local sediment
% Steps:
%   1. Load grid of sediment types (codes corresponding with Table 3 in McDonald 2016).
%   2. Translate to grain sizes (from Table 2 of APL-UW Report Oct 1994 *fix citations)
%   3. Based on distance from site, assign a weight to each sediment point using
%      w = (-0.75/R)x + 1, where R is total range and x is distance from sediment pt to center.
%   4. Assign sediment types to each radials, using an additional weighting procedure similar to the above.
%   5. Plot grain size data points and radials (color-coded with grain size assignments) on a map.

% Defaults for development/troubleshooting:
% sedDatType = 'B';
% sedDatPath = 'G:/My Drive/PropagationModeling/Sediment_Data';
% hydLoc = [33.6675, -76.00, 941]; % Params for our site WAT_GS  % [39.8326, -69.98, 958]; % Params for site WAT_NC
% distDeg = 0.359728642367492;
% total_range = 40000;
% radials = 1:36;
% plotDir = 'C:/output_Folder'
% rangeStep = 10;
% To test function, enter the following line in Command Window:
% getGrainSize('B', 'G:/My Drive/PropagationModeling/Sediment_Data', [33.6675,-76.00,941], 0.359728642367492, 40000, 1:36)

%% 1. Configure sediment data

if sedDatType == 'B' % For using BST data
    %% Option B: Use BST Data

    % Set path to BST HDF5 database containing sediment data
    BSTpath = [sedDatPath, '/BST_Data/Sediments2.0_QAV_Analysis/Sediments/Version2.0/databases/hfevav2.h5'];
    % User must download the BST data, place it in the sediment data folder and make sure the above path is valid

    [maxLats(2), ~] = reckon(hydLoc(1), hydLoc(2), distDeg, 0, 'degrees');
    [~, maxLons(2)] = reckon(hydLoc(1), hydLoc(2), distDeg, 90, 'degrees');
    [maxLats(1), ~] = reckon(hydLoc(1), hydLoc(2), distDeg, 180, 'degrees');
    [~, maxLons(1)] = reckon(hydLoc(1), hydLoc(2), distDeg, 270, 'degrees');

    BSTtileLats = floor(maxLats(1)):floor(maxLats(2));
    BSTtileLons = floor(maxLons(1)):floor(maxLons(2));

    % Check available data resolution in this region
    useHighRes = 1; % Start by assuming high-resolution (6-second, or 600 per degree) data is available.
    for j = 1:length(BSTtileLats) % Go through each tile. If even one does not have high-res available, will use low-res for all tiles.
        for i = 1:length(BSTtileLons)
            try % Assume tile is high-resolution and experimentally attempt to get its size % Make sure this is working or it will ALWAYS return error
                size(h5read(BSTpath, ['/0.10000/G/UNCLASSIFIED/' num2str(BSTtileLats(j)) '_' num2str(BSTtileLons(i))]));
            catch % If this returns an error, high-resolution data isn't available for this tile.
                useHighRes = 0; % So, use low-res data (5-minute, or 12 per degree) instead.
            end
        end
    end

    % % An alternate way to do the above data resolution check: The BST documentation lists which specific zones have
    % % high-res data. Could just compare the required tiles to download with that information and see if the tiles
    % % are inside the high-res zones or not.
    % % Check available data resolution: See if the region required fits
    % % inside a zone where BST has high-resolution data available.
    % useHighRes = 0; % Use low-res data by default
    % HRdat = readtable('H:\PropaMod\BST_HighResRegions.xlsx'); % Load list of high res regions from... somewhere idk where
    % for reg = 1:height(HRdat)
    %     if HRdat.Lat_min(reg) <= maxLats(1) && HRdat.Lat_max(reg) >= maxLats(2) && ...
    %             HRdat.Lon_min(reg) <= maxLons(1) && HRdat.Lon_max(reg) >= maxLons(2)
    %         useHighRes = 1; % If region required fits inside any high-res zone, enable high-resolution formatting.
    %     end
    % end

    % useHighRes = 0; % Uncomment this line to force low-res if needed
    if useHighRes == 1 % If high-res is indeed available for all tiles
        disp('High-resolution (6-second) sediment data is available and will be used at this site.') % Let user know
        datasetName = '/0.10000/G/UNCLASSIFIED/'; % high-res datasets
        tileSize = 600;
    elseif useHighRes == 0 % If only low-res data available for any tile
        disp('High-resolution (6-second) sediment data is not sufficiently available at this site. Low-resolution (5-minute) data will be used.') % Let user know
        datasetName = '/5.00000/G/UNCLASSIFIED/'; % low-res datasets
        tileSize = 12;
    end

    % Make lat and lon grids for sediment
    sedLatGrid = flip(repmat((floor(maxLats(1)):(1/tileSize):(ceil(maxLats(2))-(1/tileSize))).', 1, tileSize*length(BSTtileLons)),1);
    sedLonGrid = repmat(floor(maxLons(1)):(1/tileSize):ceil(maxLons(2))-(1/tileSize), tileSize*length(BSTtileLats), 1);

    % Make empty sediment grid
    sedCodeGrid = nan(flip(size(sedLatGrid)));

    % Load tiles one at a time and place data in empty grid. Orientation
    % will be incorrect at first, but will be fixed subsequently.
    for j = 1:length(BSTtileLats) % For all lats
        for i = 1:length(BSTtileLons) % For all lons
            tile = h5read(BSTpath, [datasetName num2str(BSTtileLats(j)) '_' num2str(BSTtileLons(i))]);
            gridLats = 1+tileSize*(j-1):tileSize*j;
            gridLons = 1+tileSize*(i-1):tileSize*i;
            sedCodeGrid(gridLons, gridLats) = tile(1:tileSize, 1:tileSize); % sedCodeGrid(gridLons, gridLats) = tile(2:end, 1:tileSize);
        end
    end
    sedCodeGrid = flip(sedCodeGrid.', 1); % Transpose and flip latitude to get correct orientation.
    % Notes on orientation of sedCodeGrid:
    %   Orientation is designed to align with a map if the grid is plotted using the "image" function. The first
    %   dimension of the grid is organized by DECREASING latitude (latitude intuitively decreases traveling DOWN
    %   the grid). The second dimension is organized by INCREASING longitude (longitude intuitively increases
    %    traveling RIGHT across the grid).
    % This alignment was developed by comparing the outline of land at Site GS with a map of the location on
    % Google Earth.

    % Convert grids to lists, and them to make a unified table, NearSed.
    NearSed = array2table([sedLatGrid(:), sedLonGrid(:), sedCodeGrid(:)]);
    NearSed.Properties.VariableNames = {'LAT', 'LON', 'HFEVA_code'};

elseif sedDatType == 'I' % for using IMLGS data
    %% Option G: Use IMLGS data
    % IMLGS requires a sediment translation...
    % although Colleen McDonald's thesis may provide some clues!!! (For instance,
    % chart near end matches ooze with 23, the code for clay)

    % Run imlgs2hfeva_WAT.m on downloaded sediment data first
    % Note to self to write instructions on wiki for proper path configuration
    load(fullfile(sedDatPath, 'IMLGS_Data/IMLGS_HFEVA_WAT.mat'), 'IMLGS_HFEVA_WAT', 'IMLGS_HFEVA_WAT_detailed')

    search_range = 3*total_range; % Look for all points within a radius of 3X total_range
    idx_Near = distance([hydLoc(1),hydLoc(2)],[IMLGS_HFEVA_WAT.LAT,IMLGS_HFEVA_WAT.LON]) < search_range;
    %   Get index of sediment points that are close enough to site to be used to model bottom.

    % If no points can be found within the search_range, find the closest
    % sediment point to the site instead. This point will be used as the
    % closest sediment point for any point along ALL radials.
    if sum(idx_Near) == 0
        [~, idx_Nearest] = min(distance([hydLoc(1),hydLoc(2)],[IMLGS_HFEVA_WAT.LAT,IMLGS_HFEVA_WAT.LON]));
        idx_Near(idx_Nearest) = 1; % Force idx_Near to recognize this point
    end
    
    % Make NearSed, the list of the sediment points within search_range (or
    % the single closest point, if none within search_range)
    NearSed = IMLGS_HFEVA_WAT(idx_Near, :);
    NearSed.Sediment_Name = []; % Remove Sediment_Name variable

    % Suggested change: Just have NearSed include all the points in IMLGS_HFEVA_WAT. Even if the closest point to the
    % site is 3X total_range away from the site, it's not necessarily the closest sediment point to ALL points along
    % all the radials. Making this change would get rid of that concern.

end

%% 2. Replace sediment type codes with corresponding grain size (phi units)

% Add a fourth column to NearSed: Grain size.
NearSed = [NearSed array2table(nan(height(NearSed), 1), 'VariableNames', {'Grain_Size'})];

hfevaCode = [1:23, 888, 999];
grainSize = [NaN, NaN, NaN, -1:0.5:8, 9, NaN, NaN]; % Define what grain sizes correspond to each HFEVA code...
for sedType = 1:25                                  % and assign grain sizes to each sediment point accordingly.
    NearSed.Grain_Size(NearSed.HFEVA_code == hfevaCode(sedType)) = grainSize(sedType);
end

%% 3. Assign weights to each sediment point based on proximity to the site.
%     When determining the sediment type for each radial, we want to
%     prioritize sediment points that are closer to the site. This section
%     assigns a weight of 1 to points that are exactly at the site, and
%     0.25 to points that are exactly radial-length (total_range) from the
%     site. Weight decreases linearly w/ increased distance from the site.

% Add three more columns to NearSed: Dist_deg, Dist_km, and Weight.
NearSed = [NearSed array2table(nan(height(NearSed), 3), 'VariableNames', {'Dist_deg' 'Dist_km', 'Weight'})];
% Begin by calculating the distance of each point from the site.
NearSed.Dist_deg = sqrt((hydLoc(2) - NearSed.LON).^2 + (hydLoc(1) - NearSed.LAT).^2); % Distance in degrees.
NearSed.Dist_km = deg2km(NearSed.Dist_deg);                                       % Distance in km.
% Next, calculate the weight of each point based on the distance from the site in km.
NearSed.Weight = 1 + -0.75*NearSed.Dist_km / (total_range/1000);

%% 4. Go radial by radial and assign a sediment type

radGrainSize = nan(size(radials)); % The final product: empty array to hold the grain size assigned to each radial.
for rad = 1:length(radials) % For each radial...
    % Get coordinates of points along radial line.
    [latout(rad), lonout(rad)] = reckon(hydLoc(1, 1), hydLoc(1, 2), distDeg, radials(rad),'degrees');
    RADi = array2table([linspace(hydLoc(1, 1), latout(rad), length(0:rangeStep:total_range)).', ...
        linspace(hydLoc(1, 2), lonout(rad), length(0:rangeStep:total_range)).']); % Table of coordinates of points along radial line
    RADi.Properties.VariableNames = {'LAT', 'LON'};

    % Add four more columns: For the distance away, grain size, and weight
    % of the nearest sediment point to each point along the radial line.
    % Also, a column for Adjusted Weight, the weight of the sediment point
    % adjusted for its distance away from the given point on the radial
    % (whereas the raw weight is just based on its distance from the site).
    RADi = [RADi array2table(nan(height(RADi), 4), 'VariableNames', {'Dist_km' 'Grain_Size', 'Weight', 'Adj_Wt'})];

    % For each point along the radial line, determine the grain size,
    % weight, and distance of the sediment point located nearest to it.
    for k = 1:height(RADi)
        [RADi.Dist_km(k), sedIdx] = min(distance([RADi.LAT(k), RADi.LON(k)], [NearSed.LAT, NearSed.LON]) / 1000); % Get distance to nearest sediment point in km
        RADi.Grain_Size(k) = NearSed.Grain_Size(sedIdx); % Using that sediment point's index, get its grain size...
        RADi.Weight(k) = NearSed.Weight(sedIdx); % ... and its weight.
    end
    % Additionally, calculate the adjusted weight. The adjustment is made 
    % using the same linear 1->.25 scale as the calculation of the raw weight.
    RADi.Adj_Wt = RADi.Weight - (0.75*RADi.Dist_km / (total_range/1000)); % Total range is again used to determine how fast weight changes, even though this is in a different context.

    % Now, find the unique grain sizes in RADi.
    uniqueGrainSize = unique(RADi.Grain_Size);

    % Total the adjusted weights for each unique grain size to get its score.
    grainSizeScore = nan(length(uniqueGrainSize), 1); % Create a table for the scores
    for i = 1:length(uniqueGrainSize)
        grainSizeScore(i) = sum(RADi.Adj_Wt(RADi.Grain_Size == uniqueGrainSize(i)));
    end

    % Finally, find the grain size with the maximum score and assign it as the grain size for this radial.
    [~, maxGrainSize_idx] = max(grainSizeScore); % Idx of grain size w/ max score
    radGrainSize(rad) = uniqueGrainSize(maxGrainSize_idx); % The grain size with the max score

    clear RADi
end

%% 5. Plot map of grain size and propagation model radials.

figure('Name', 'Map of Grain Size Points and Radials', 'NumberTitle', 'off')

% 5A. Plot grain size. Choose point style depending on data type.
%     NOTE: NaN grain size (Rough Rock, Rock, Cobble or Gravel or Pebble, No Data, and Land) are not plotted.
if sedDatType == 'B' && useHighRes == 0 % If using BST data and using low res data...
    geoscatter(NearSed.LAT, NearSed.LON, 80, NearSed.Grain_Size, 'square', 'filled') % plot grain size with large boxes (to cover gray space).
elseif sedDatType == 'B' && useHighRes == 1 % If using BST and using high res data...
        geoscatter(NearSed.LAT, NearSed.LON, 1, NearSed.Grain_Size) % plot grain size with small points.
elseif sedDatType == 'I'  % If using IMLGS data...
    geoscatter(NearSed.LAT, NearSed.LON, 40, NearSed.Grain_Size, 'o', 'filled') % plot grain size with circles.
end
geobasemap grayland % Make land gray and ocean white, easier to see things this way.
caxis([-1.25 9.25])
colormap(turbo(21)) % Set colormap so that each possible grain size has a color (plus a color for 8.5 φ, the only unused grain size).
grainSizeKey = colorbar; % Add grain size colorbar
grainSizeKey.Label.String = 'Grain Size (φ)';
hold on

% 5B. Plot radial lines and site coordinates
colorScheme = turbo(21); % Get color scheme from (5A) so radial lines can be color-coded by grain size
colorScheme = [colorScheme (-1:0.5:9).']; % Add a fourth column with corresponding grain size
for rad = 1:length(radials) % Plot radial lines
    [latout(rad), lonout(rad)] = reckon(hydLoc(1, 1), hydLoc(1, 2), distDeg, radials(rad),'degrees');
    geoplot([hydLoc(1), latout(rad)], [hydLoc(2), lonout(rad)], 'Color', colorScheme(colorScheme(:, 4) == radGrainSize(rad), 1:3))
end
geoscatter(hydLoc(1), hydLoc(2), 'ok') % Plot site coordinates
geoscatter(hydLoc(1), hydLoc(2), '.k')
hold off % Done with map.

% 5C. Save plot to the plot directory in Google Drive.
saveas(gca, [plotDir, '\SiteMap_SedimentAndRadials'], 'png')