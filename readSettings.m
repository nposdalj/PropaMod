% readSettings.m
% Read settings sheet into workspace.

% settings = readtable('H:\PropaMod\PropaMod_Settings.xlsx'); % Default
settings = readtable(settingsPath); % Default

author = settings.Value_EDIT_{2}; % Your name/initials. This will be included in the .txt output.
userNote = settings.Value_EDIT_{3}; % Include a note for yourself/others. This will be included in the .txt output.

% A. CONFIGURE PATHS - INPUT AND EXPORT
Site = settings.Value_EDIT_{6};
Region = settings.Value_EDIT_{7};
BathyRegion = settings.Value_EDIT_{8}; % If your site is outside of the Western Atlantic, change this to GlobalCoverage

%bellhopSaveDir = 'C:\Users\HARP\Documents\PropMod_Intermed'; %Aaron's Computer % Intermediate save directory on your local disk
bellhopSaveDir = settings.Value_EDIT_{9}; %Natalie's Computer % Intermediate save directory on your local disk
%bellhopSaveDir = 'H:\Baja_GI\PropaMod\PropMod_Intermed' % For Aaron Baja_GI

Gdrive = settings.Value_EDIT_{10};
fpath = settings.Value_EDIT_{11}; % Input directory for WAT
%fpath = [Gdrive, ':\Baja_GI\PropaMod']; % Input directory for Baja_GI
% fpath must contain:   - bathymetry file: \Bathymetry\bathy.txt
%                       - site SSP data: \SSPs\SSP_WAT_[Site].xlsx
%                       - sediment data*: \Sediment_Data\...
%                           Sediment data is optional, required only if modeling bottom using grain size. SEE WIKI FOR FOLDER CONFIGURATION.
saveDir = settings.Value_EDIT_{12}; % Export directory % < This line should be unused now
%GEBCODir = [Gdrive,':\My Drive\PropagationModeling_GDrive']; %GEBCO bathymetry netCDF file
GEBCODir = settings.Value_EDIT_{13}; %local GEBCO bathymetry netCDF file - Natalie
%GEBCODir = 'C:\Users\HARP\Documents\PropMod_Intermed'; %local GEBCO bathymetry netCDF file - Aaron WAT
%GEBCODir = 'H:\Baja_GI\PropaMod\PropMod_Intermed'; %local GEBCO bathymetry netCDF file - Aaron GI

% Note to self to have smth in plotSSP that exports the examined effort period
% and other relevant details so they can be exported in the info file here

% B. SPECIFY MODEL INPUT PARAMETERS: Hydrophone Location, Source Level, and Source Frequency.
hlat = settings.Value_EDIT_{16}; % hydrophone lat
hlon = settings.Value_EDIT_{17}; % hydrophone long
hdepth = settings.Value_EDIT_{18};   % hydrophone depth % <- inputted into DetSim_Workspace
SL = settings.Value_EDIT_{19};       % Source Level - 230 for Social Groups, 235 for Mid-Size and Males
freq = settings.Value_EDIT_{20};  % Frequencies of sources, in Hz. Enter up to 3 values.

% C. SSP TYPE: Indicate the type of SSP you want to use.
SSPtype = settings.Value_EDIT_{23}; % 'Mean' = Overall mean; 'Mmax' = Month w/ max SS; 'Mmin' = Month w/ min SS.

% D. SPECIFY MODELS
% D.a makeBTY model - interpolation type
BTYmodel = settings.Value_EDIT_{26}; % L: Linear interpolation of the surface
                % C: Curvlinear interpolation

%D.b makeENV model - method of interpolation used by Bellhop to calculate
%sound speed and its derivatives along the way
ENVmodel = settings.Value_EDIT_{27}; % S: cubic spline interpolation
                % C: C-linear interpolation
                % N: N2-linear interpolation
                % A: Analytic interpolation (requires adaptation of the
                % subroutine SSP and further model recompilation
                % Q: Quadratic approximation of the sound speed field
                % (requires the creation of a *.ssp file containing the
                % filed

% D.c Sea Floor Model
botModel = settings.Value_EDIT_{28}; % 'A' = Model bottom as Acousto Elastic Half-Space; manually enter parameters. SEE D.i.
%               % 'G' = Model bottom using grain size. SEE D.ii.
%               % 'Y' = Model bottom as Acousto Elastic Half-Space; Calculate
%               %       parameters with grain size and Algorithm Y. SEE D.ii.

% D.i. If modeling bottom using Acousto Elastic Half-Space, modify the following properties
%      (required for makeEnv.m to run, if botModel = 'A'):
AEHS.compSpeed = settings.Value_EDIT_{30}; % 1470.00;   % Compressional speed % No longer used - Sound speed at seafloor at site is now used instead
% This is now determined within the radial loop, during the first radial, along with Source Depth (SD)
AEHS.shearSpeed = settings.Value_EDIT_{31}; %129.90; %150;  % 146.70;   % Shear speed
AEHS.density = settings.Value_EDIT_{32}; %1.7  %1.15;        % Density.
%   This value (1.7 g/cm^3) was chosen based on the average density of
%   marine sediments found by Tenzer and Gladkikh (2014).
AEHS.compAtten = settings.Value_EDIT_{33};    % Compressional attenuation
AEHS.shearAtten = settings.Value_EDIT_{34};   % Shear attenuation

% D.ii If modeling bottom using Acousto Elastic Half-Space, modify the following properties
%        (required for makeEnv.m to run if botModel = 'Y'
SedDep = settings.Value_EDIT_{35}; %sediment depth you expect for shear velocity calculations (3m = surficial sediment)

% D.ii. If modeling bottom using grain size, select which dataset to use:
sedDatType = settings.Value_EDIT_{37}; % 'B' = BST data; 'I' = IMLGS data.
forceLR = settings.Value_EDIT_{38}; % If using BST data, set 0 to use high-res data where possible; 1, use low-res always

% E. CONFIGURE MODEL OUTPUT: RANGE AND RESOLUTION
total_range = settings.Value_EDIT_{41};    % Radial range around your site, in meters
rangeStep = settings.Value_EDIT_{42};         % Range resolution
depthStep = settings.Value_EDIT_{43};         % Depth resolution
numRadials = settings.Value_EDIT_{44};        % Specify number of radials - They will be evenly spaced.
%   Keep in mind, 360/numRadials = Your angular resolution.
nrr = total_range/rangeStep; %total # of range step output to be saved for pDetSim

% F. CONFIGURE PLOT OUTPUT
generate_RadialPlots = settings.Value_EDIT_{47}; % Generate radial plots? 1 = Yes, 0 = No
generate_PolarPlots = settings.Value_EDIT_{48}; % Generate polar plots? 1 = Yes, 0 = No

RL_threshold = settings.Value_EDIT_{49}; % Threshold below which you want to ignore data; will be plotted as blank (white space)
RL_plotMax = settings.Value_EDIT_{50}; % Colorbar maximum for plots; indicates that this is the max expected RL

% Polar Plots
makePolarPlots = [settings.Value_EDIT_{52}, ...
    settings.Value_EDIT_{53}, ...
    settings.Value_EDIT_{54}]; % [min depth, step size, max depth] - we should try deeper than 800...maybe 1200m?
% Radial plots are automatically generated for every radial
