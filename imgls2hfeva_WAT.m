function imgls2hfeva_WAT(sedPath)
% Translates downloaded IMLGS sediment data to make it compatible with
% HFEVA sediment types.
% How IMLGS sediment types and HFEVA types match up is not clear-cut. The
% decisions on how to translate IMLGS types to HFEVA types were made by
% AD using a few different resources.
%
% This function is called by bellhop_PropMod.m before running getGrainSize.m

%% Configure paths and load IMLGS data

IMLGS_datPath = [sedPath '\IMLGS_Data\IMLGS_SPATIAL_QUERY_RESULTS\IMLGS_SPATIAL_QUERY_RESULTS.csv'];
saveDir = [sedPath '\IMLGS_Data']; % Directory to save output

IMLGS_table = readtable(IMLGS_datPath); % Original IMLGS table

%% Adapt this table to produce IMLGS_HFEVA_WAT table.

IMLGS_HFEVA_WAT = IMLGS_table;

HFEVA_code = array2table(nan(height(IMLGS_HFEVA_WAT), 1)); % Create new column for HFEVA codes.
HFEVA_code.Properties.VariableNames = {'HFEVA_code'};
IMLGS_HFEVA_WAT = [IMLGS_HFEVA_WAT HFEVA_code]; % Add this column to the table.

%% Translate sediment types.
% When they are included at all, sediment names are included in Column 45
% of the IMLGS table, TEXT1. So we just need to decide which HFEVA code
% each IMLGS sediment type matches to and make assignments according to
% TEXT1.

% Match the two following IMLGS types to HFEVA Code 3, Cobble or gravel or pebble.
IMLGS_HFEVA_WAT.HFEVA_code(strcmp(IMLGS_HFEVA_WAT.TEXT1, 'nodules')) = 3; % Nodules
IMLGS_HFEVA_WAT.HFEVA_code(strcmp(IMLGS_HFEVA_WAT.TEXT1, 'gravel')) = 3;  % Gravel

% Match IMLGS Sandy gravel to HFEVA Code 4, Sandy gravel.
IMLGS_HFEVA_WAT.HFEVA_code(strcmp(IMLGS_HFEVA_WAT.TEXT1, 'sandy gravel')) = 4; % Sandy gravel

% Match IMLGS Gravelly sand to HFEVA Code 7, Coarse sand or gravelly sand.
IMLGS_HFEVA_WAT.HFEVA_code(strcmp(IMLGS_HFEVA_WAT.TEXT1, 'gravelly sand')) = 7; % Gravelly sand

% Match IMLGS Muddy gravel to HFEVA Code 10, Muddy gravel.
IMLGS_HFEVA_WAT.HFEVA_code(strcmp(IMLGS_HFEVA_WAT.TEXT1, 'muddy gravel')) = 10; % Muddy gravel

% Match IMLGS Sand to HFEVA Code 9, Medium sand or sand.
IMLGS_HFEVA_WAT.HFEVA_code(strcmp(IMLGS_HFEVA_WAT.TEXT1, 'sand')) = 9; % Sand

% Match IMLGS Muddy sand to HFEVA Code 12, Muddy sand.
IMLGS_HFEVA_WAT.HFEVA_code(strcmp(IMLGS_HFEVA_WAT.TEXT1, 'muddy sand')) = 12; % Muddy sand

% Match IMLGS Gravelly mud to HFEVA Code 16, Gravelly mud or sandy silt.
IMLGS_HFEVA_WAT.HFEVA_code(strcmp(IMLGS_HFEVA_WAT.TEXT1, 'gravelly mud')) = 16; % Gravelly mud

% Match IMLGS Sandy mud or ooze to HFEVA Code 20, Sandy clay.
IMLGS_HFEVA_WAT.HFEVA_code(strcmp(IMLGS_HFEVA_WAT.TEXT1, 'sandy mud or ooze')) = 20; % Sandy mud or ooze

% Match IMLGS Mud or ooze to HFEVA Code 23, Clay.
IMLGS_HFEVA_WAT.HFEVA_code(strcmp(IMLGS_HFEVA_WAT.TEXT1, 'mud or ooze')) = 23; % Mud or ooze

% Finally, match the following nine IMLGS types to HFEVA Code 2, Rock.
% (Some of these might match Rough Rock or Cobble/gravel/pebble better; more investigation is needed.)
IMLGS_HFEVA_WAT.HFEVA_code(strcmp(IMLGS_HFEVA_WAT.TEXT1, 'crusts')) = 2; % Crusts
IMLGS_HFEVA_WAT.HFEVA_code(strcmp(IMLGS_HFEVA_WAT.TEXT1, 'slabs')) = 2; % Slabs
IMLGS_HFEVA_WAT.HFEVA_code(strcmp(IMLGS_HFEVA_WAT.TEXT1, 'plutonic igneous rock')) = 2; % Plutonic igneous rock
IMLGS_HFEVA_WAT.HFEVA_code(strcmp(IMLGS_HFEVA_WAT.TEXT1, 'volcanic igneous rock')) = 2; % Volcanic igneous rock
IMLGS_HFEVA_WAT.HFEVA_code(strcmp(IMLGS_HFEVA_WAT.TEXT1, 'metamorphic rock')) = 2; % Metamorphic rock
IMLGS_HFEVA_WAT.HFEVA_code(strcmp(IMLGS_HFEVA_WAT.TEXT1, 'erratic rock')) = 2; % Erratic rock
IMLGS_HFEVA_WAT.HFEVA_code(strcmp(IMLGS_HFEVA_WAT.TEXT1, 'authigenic limestone')) = 2; % Authigenic limestone
IMLGS_HFEVA_WAT.HFEVA_code(strcmp(IMLGS_HFEVA_WAT.TEXT1, 'allogenic limestone')) = 2; % Allogenic limestone
IMLGS_HFEVA_WAT.HFEVA_code(strcmp(IMLGS_HFEVA_WAT.TEXT1, 'terrigenous clastic sedimentary rock')) = 2; % Terrigenous clastic sedimentary rock

%% For clarity, remove everything from the table except the necessary columns: Lat, lon, IMLGS type, HFEVA code
IMLGS_HFEVA_WAT_detailed = IMLGS_HFEVA_WAT; % Save the original complete table as IMLGS_HFEVA_WAT_detailed
IMLGS_HFEVA_WAT = IMLGS_HFEVA_WAT(:, ["LAT", "LON", "TEXT1", "HFEVA_code"]);
    % Rewrite IMLGS_HFEVA_WAT with only the necessary variables
IMLGS_HFEVA_WAT.Properties.VariableNames(3) = "Sediment_Name"; % Rename TEXT1 -> SedimentName, for clarity

% Additionally, remove rows that don't contain any sediment data.
IMLGS_HFEVA_WAT(isnan(IMLGS_HFEVA_WAT.HFEVA_code), :) = [];

%% Save IMLGS_HFEVA_WAT and IMLGS_HFEVA_WAT_detailed to a file
save([saveDir, '\IMLGS_HFEVA_WAT.mat'], 'IMLGS_HFEVA_WAT', 'IMLGS_HFEVA_WAT_detailed')

%% Attribution
% Script and translation method developed by AD, 2023
%
% Grain sizes:
% Resources for translation method: