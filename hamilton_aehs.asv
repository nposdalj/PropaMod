function [sed_vel, shear_vel, sed_dens, atten_comp, shear_atten]=hamilton_aehs(freq, grain_size)
% hamilton_aehs.m
% Two functions by Miller and Potti -- hamilton.m and atten.m -- adapted
% for our use and merged

%% Part I: Compressional Speed
% See relevant function by Miller and Potti: hamilton.m

% Combine Tables IA and IB from Hamilton 1980 with relevant variables
% NOTE: These values are for the continental shelf and continental slope.
%       Hamilton lists different values for the abyssal plain and hills.
HamiltonTab = array2table([0.92; 2.65; 3.38; 4.35; 5.02; 5.40; 5.86; 7.02; 8.52], ...
    'VariableNames', {'phi'});                                            % grain diams. (φ) from Hamilton (1980), Table IA
HamiltonTab.vel = [1836; 1749; 1702; 1646; 1652; 1615; 1579; 1549; 1520]; % Velocities from Hamilton (1980), Table IB

% Interpolate sediment velocities to the grain size of the current radial
sed_vel=interp1(HamiltonTab.phi, HamiltonTab.vel, grain_size);

%% NOTES: Differences between this function and hamilton_interp.m
% - hamilton.m assigns each sediment type listed in Table IA in Hamilton
%   (1980) a number 1-9, and makes a table with these numbers and the
%   corresponding velocity for each sediment (from Table IB in Hamilton
%   (1980).
% - Meanwhile, hamilton_interp.m ignores the sediment types given by
%   Hamilton and only links the velocities with the grain diameters (φ)
%   given in Hamilton (1980) Table IA. This is done because Hamilton (1980)
%   Table IA doesn't appear to use the same sediment names as the HFEVA
%   system (citation?), which is what we are using to link sediment types
%   with phi grain sizes.
%
% - Moreover, hamilton.m matches the input sediment type to the sediment types 1-9
%   and assigns the corresponding value on the right side of the table (sed_vel1)
% - hamilton_interp.m, however, INTERPOLATES the table of phi grain
%   diameters and sediment velocities to the input phi grain diameter.

%% Part II: Shear Speed, Compressional Attenuation, and Shear Attenuation
% This program finds the attenuation values based on the sediment type (dB/m)
% See relevant function by Miller and Potti: atten.m

% First, assign type_sand, type_silt, or type_clay based on Hamilton (1980), Table IA.
% Like Miller and Potti's function (atten.m), assign the first four sediments in Hamilton (1980)
% Table IA as sand-type, next two as silt-type, and last three as clay-type.

HamiltonPhi = [0.92; 2.65; 3.38; 4.35; 5.02; 5.40; 5.86; 7.02; 8.52]; % Grain diams. (φ) from Hamilton (1980), Table IA
[~, idx_bestPhi] = min(abs(HamiltonPhi - grain_size));  % Find the grain size in Hamilton (1980) Table
bestPhi = HamiltonPhi(idx_bestPhi);                     % IA which the input grain size is nearest to

% Assign values for sand, or set up table for interpolation
att_sand = [20 0.0001;
    4000 0.2;
    20000 5;
    100000 100];  % No reference given in atten.m
shear_sand = 170; % Check value and citation
shear_atten_sand = 13.2*(freq/1000); % Hamilton (1980) - See table on p.1331

% Assign values for silt, or set up table for interpolation
att_silt = [20 0.0003;
    10000 2;
    100000 20]; % No reference given in atten.m
shear_silt = 200; % Hard-coded in atten.m; no reference given
shear_atten_silt = 13.4*(freq/1000); % Hamilton (1980) - See table on p.1331

% Assign values for clay, or set up table for interpolation
att_clay = 2.42*(10^-5)*(freq^1.12); % Bowles-JASA (1997)
shear_atten_clay = 15.2*(freq/1000); % Hamilton (1980) - See table on p.1331
shear_clay=[1500 125;
    1600 300;
    1700 400;
    1800 500;
    2000 600];  % Reference:

switch bestPhi
    case {0.92, 2.65, 3.38, 4.35} % SAND-TYPE SEDIMENTS
        atten_comp = interp1(att_sand(:,1),att_sand(:,2),freq);
        shear_vel = shear_sand;
        shear_atten = shear_atten_sand;

    case {5.02, 5.40} % SILT-TYPE SEDIMENTS
        atten_comp = interp1(att_silt(:,1),att_silt(:,2),freq);
        shear_vel = shear_silt;
        shear_atten = shear_atten_silt;

    case {5.86, 7.02, 8.52} % CLAY-TYPE SEDIMENTS
        atten_comp = att_clay;
        shear_vel = interp1(shear_clay(:,1),shear_clay(:,2),sed_vel); % shear_vel = interp1(shear_clay(:,1),shear_clay(:,2),sed_speed);
        shear_atten = shear_atten_clay;
end

%% NOTES: Differences between this function and atten.m

% Instead of type, this function uses Grain Size to choose whether to assign sand-type,
% silt-type, or clay-type values.

%% Part III: Set density as 1.65, the constant sediment density used by OALIB's function socal_sed.m. 
sed_dens = 1.65; % Constant sediment density used by OALIB's function socal_sed.m.