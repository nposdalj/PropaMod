% readSettings.m
% Read settings sheet into workspace.

% settings = readtable('H:\PropaMod\PropaMod_Settings.xlsx'); % Default
opts = detectImportOptions(settingsPath);
opts = setvartype(opts, 'ValueEdit', 'char');
settings = readtable(settingsPath,opts); % Default
[val, idx] = rmmissing(settings.ValueEdit); %Delete empty rows
settings(idx,:) = [];

author = settings.ValueEdit{2}; % Your name/initials. This will be included in the .txt output.
userNote = settings.ValueEdit{3}; % Include a note for yourself/others. This will be included in the .txt output.

% A. CONFIGURE PATHS - INPUT AND EXPORT
Site = settings.ValueEdit{4};
Region = settings.ValueEdit{5};
BathyRegion = settings.ValueEdit{6}; % If your site is outside of the Western Atlantic, change this to GlobalCoverage
%bellhopSaveDir = 'C:\Users\HARP\Documents\PropMod_Intermed'; %Aaron's Computer % Intermediate save directory on your local disk
bellhopSaveDir = settings.ValueEdit{7}; %Natalie's Computer % Intermediate save directory on your local disk
%bellhopSaveDir = 'H:\Baja_GI\PropaMod\PropMod_Intermed' % For Aaron Baja_GI

Gdrive = settings.ValueEdit{8};
fpath = settings.ValueEdit{9}; % Input directory for WAT
%fpath = [Gdrive, ':\Baja_GI\PropaMod']; % Input directory for Baja_GI
% fpath must contain:   - bathymetry file: \Bathymetry\bathy.txt
%                       - site SSP data: \SSPs\SSP_WAT_[Site].xlsx
%                       - sediment data*: \Sediment_Data\...
%                           Sediment data is optional, required only if modeling bottom using grain size. SEE WIKI FOR FOLDER CONFIGURATION.
saveDir = [settings.ValueEdit{10} '\' settings.ValueEdit{4}]; % Export directory % < This line should be unused now
GEBCODir = settings.ValueEdit{11}; %local GEBCO bathymetry netCDF file - Natalie
GEBCOFile = settings.ValueEdit{12}; % baqthymetry file in geotiff or netCDF format

% Note to self to have smth in plotSSP that exports the examined effort period
% and other relevant details so they can be exported in the info file here

% B. SPECIFY MODEL INPUT PARAMETERS: Hydrophone Location, Source Level, and Source Frequency.
hlat = str2double(settings.ValueEdit{13}); % hydrophone lat
hlon = str2double(settings.ValueEdit{14}); % hydrophone long
hdepth = str2double(settings.ValueEdit{15});   % hydrophone depth % <- inputted into DetSim_Workspace
SL = str2double(settings.ValueEdit{16});       % Source Level - 230 for Social Groups, 235 for Mid-Size and Males
freq = {str2double(settings.ValueEdit{17})};  % Frequencies of sources, in Hz. Enter up to 3 values.

% C. SSP TYPE: Indicate the type of SSP you want to use.
SSPtype = settings.ValueEdit{18}; % 'Mean' = Overall mean; 'Mmax' = Month w/ max SS; 'Mmin' = Month w/ min SS.

% D. SPECIFY MODELS
% D.a makeBTY model - interpolation type
BTYmodel = settings.ValueEdit{19}; % L: Linear interpolation of the surface
                % C: Curvlinear interpolation

%D.b makeENV model - method of interpolation used by Bellhop to calculate
%sound speed and its derivatives along the way
SSPint = settings.ValueEdit{20}; % S: cubic spline interpolation
                % C: C-linear interpolation
                % N: N2-linear interpolation
                % A: Analytic interpolation (requires adaptation of the
                % subroutine SSP and further model recompilation
                % Q: Quadratic approximation of the sound speed field
                % (requires the creation of a *.ssp file containing the
                % filed
                
SurfaceType = settings.ValueEdit{21}; 

BottomAtten = settings.ValueEdit{22};

VolAtten = settings.ValueEdit{23};

% D.c Sea Floor Model
botModel = settings.ValueEdit{24}; % 'A' = Model bottom as Acousto Elastic Half-Space; manually enter parameters. SEE D.i.
%               % 'G' = Model bottom using grain size. SEE D.ii.
%               % 'Y' = Model bottom as Acousto Elastic Half-Space; Calculate
%               %       parameters with grain size and Algorithm Y. SEE D.ii.

% D.i. If modeling bottom using Acousto Elastic Half-Space, modify the following properties
%      (required for makeEnv.m to run, if botModel = 'A'):
AEHS.compSpeed = str2double(settings.ValueEdit{25}); % 1470.00;   % Compressional speed % No longer used - Sound speed at seafloor at site is now used instead
% This is now determined within the radial loop, during the first radial, along with Source Depth (SD)
AEHS.shearSpeed = str2double(settings.ValueEdit{26}); %129.90; %150;  % 146.70;   % Shear speed
AEHS.density = str2double(settings.ValueEdit{27}); %1.7  %1.15;        % Density.
%   This value (1.7 g/cm^3) was chosen based on the average density of
%   marine sediments found by Tenzer and Gladkikh (2014).
AEHS.compAtten = str2double(settings.ValueEdit{28});    % Compressional attenuation
AEHS.shearAtten = str2double(settings.ValueEdit{29});   % Shear attenuation

% D.ii If modeling bottom using Acousto Elastic Half-Space, modify the following properties
%        (required for makeEnv.m to run if botModel = 'Y'
SedDep = str2double(settings.ValueEdit{30}); %sediment depth you expect for shear velocity calculations (3m = surficial sediment)

% D.ii. If modeling bottom using grain size, select which dataset to use:
sedDatType = settings.ValueEdit{31}; % 'B' = BST data; 'I' = IMLGS data.
forceLR = str2double(settings.ValueEdit{32}); % If using BST data, set 0 to use high-res data where possible; 1, use low-res always

% E. CONFIGURE MODEL OUTPUT: RANGE AND RESOLUTION
total_range = str2double(settings.ValueEdit{33});    % Radial range around your site, in meters
rangeStep = str2double(settings.ValueEdit{34});         % Range resolution
depthStep = str2double(settings.ValueEdit{35});         % Depth resolution
numRadials = str2double(settings.ValueEdit{36});        % Specify number of radials - They will be evenly spaced.
%   Keep in mind, 360/numRadials = Your angular resolution.
nrr = total_range/rangeStep; %total # of range step output to be saved for pDetSim

% F. CONFIGURE PLOT OUTPUT
generate_RadialPlots = str2double(settings.ValueEdit{37}); % Generate radial plots? 1 = Yes, 0 = No
generate_PolarPlots = str2double(settings.ValueEdit{38}); % Generate polar plots? 1 = Yes, 0 = No

RL_threshold = str2double(settings.ValueEdit{39}); % Threshold below which you want to ignore data; will be plotted as blank (white space)
RL_plotMax = str2double(settings.ValueEdit{40}); % Colorbar maximum for plots; indicates that this is the max expected RL

% Polar Plots
makePolarPlots = [str2double(settings.ValueEdit{41}), ...
    str2double(settings.ValueEdit{42}), ...
    str2double(settings.ValueEdit{43})]; % [min depth, step size, max depth] - we should try deeper than 800...maybe 1200m?
% Radial plots are automatically generated for every radial
