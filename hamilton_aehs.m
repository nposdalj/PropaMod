function [compSpd, shearSpd, density, compAtten] = hamilton_aehs(phi)
% function [sed_vel, shear_vel, sed_dens, atten_comp, shear_atten]=hamilton_aehs(freq, grain_size)

% hamilton_aehs.m
% Two functions by Miller and Potti -- hamilton.m and atten.m -- adapted
% for our use and merged

%% Part I: Compressional Speed
% See relevant function by Miller and Potti: hamilton.m

% Combine Tables IA and IB from Hamilton 1980 with relevant variables
% NOTE: These values are for the continental shelf and continental slope.
%       Hamilton lists different values for the abyssal plain and hills.

%% -9-1 Version

% Generate table of AEHS values.
% 5 cols: grain size (phi units), compressional speed, shear speed,
% density, and compressional attenuation.
aehsTab = [-1	2005.44	33.57	2.49	0.0167	% Sandy Gravel
    -0.5	1960.05	32.07	2.40	0.0164	% Very Coarse Sand
    0	1916.70	30.67	2.31	0.0160	% Muddy Sandy Gravel
    0.5	1875.38	30.15	2.23	0.0161	% Coarse Sand
    1	1836.19	29.66	2.15	0.0162	% Gravelly Muddy Sand
    1.5	1767.29	28.18	1.84	0.0159	% Sand or Medium Sand
    2	1709.42	27.02	1.62	0.0158	% Muddy Gravel
    2.5	1660.89	26.12	1.45	0.0157	% Silty Sand or Fine Sand
    3	1620.04	27.47	1.34	0.0170	% Muddy Sand
    3.5	1585.19	29.17	1.27	0.0184	% Very Fine Sand
    4	1554.66	30.82	1.22	0.0198	% Clayey Sand
    4.5	1526.79	32.34	1.19	0.0212	% Coarse Silt
    5	1499.90	18.57	1.17	0.0124	% Sandy Silt
    5.5	1482.78	9.84	1.15	0.0066	% Medium Silt
    6	1480.96	5.61	1.15	0.0038	% Silt
    6.5	1479.13	4.44	1.15	0.0030	% Fine Silt
    7	1477.31	3.51	1.15	0.0024	% Sandy Clay
    7.5	1475.49	2.81	1.15	0.0019	% Very Fine Silt
    8	1473.66	2.35	1.15	0.0016	% Silty Clay
    9	1470.01	2.13	1.14	0.0015];	% Clay
aehsTab = array2table(aehsTab, 'VariableNames', {'phi', 'compSpd', 'shearSpd', 'density', 'compAtten'});

% Edit shear speed column, as we do not want to use the default values
aehsTab.shearSpd = nan(size(aehsTab.shearSpd)); % Clear column
aehsTab.shearSpd(1:11) = 150; % Shear speed for "sand-type" sediments.
aehsTab.shearSpd(12:16) = 200; % Shear speed for "silt-type" sediments.
aehsTab.shearSpd(17:20) = 170; % Shear speed for "clay-type" sediments.

% Assign AEHS values depending on input grain size
phi_idx = find(aehsTab.phi == phi);
[compSpd] = aehsTab.compSpd(phi_idx);     % Assign compressional speed
[shearSpd] = aehsTab.shearSpd(phi_idx);   % Assign shear speed
[density] = aehsTab.density(phi_idx);     % Assign density
[compAtten] = aehsTab.compAtten(phi_idx); % Assign compressional attenuation

%% Hamilton's sizes version
% 
% aehsTab = array2table([-1:0.5:8, 9], 'VariableNames', {'phi'});
% 
% HamiltonTab = array2table([0.92; 2.65; 3.38; 4.35; 5.02; 5.40; 5.86; 7.02; 8.52], ...
%     'VariableNames', {'phi'});                                            % grain diams. (φ) from Hamilton (1980), Table IA
% HamiltonTab.vel = [1842.24; 1647.90; 1593.09; 1534.97; 1498.82; 1483.15; 1481.47; 1477.24; 1471.76];
% 
% % Interpolate sediment velocities to the grain size of the current radial
% sed_vel=interp1(HamiltonTab.phi, HamiltonTab.vel, grain_size);
% 
% %% NOTES: Differences between this function and hamilton_interp.m
% % - hamilton.m assigns each sediment type listed in Table IA in Hamilton
% %   (1980) a number 1-9, and makes a table with these numbers and the
% %   corresponding velocity for each sediment (from Table IB in Hamilton
% %   (1980).
% % - Meanwhile, hamilton_interp.m ignores the sediment types given by
% %   Hamilton and only links the velocities with the grain diameters (φ)
% %   given in Hamilton (1980) Table IA. This is done because Hamilton (1980)
% %   Table IA doesn't appear to use the same sediment names as the HFEVA
% %   system (citation?), which is what we are using to link sediment types
% %   with phi grain sizes.
% %
% % - Moreover, hamilton.m matches the input sediment type to the sediment types 1-9
% %   and assigns the corresponding value on the right side of the table (sed_vel1)
% % - hamilton_interp.m, however, INTERPOLATES the table of phi grain
% %   diameters and sediment velocities to the input phi grain diameter.
% 
% %% Part II: Shear Speed, Compressional Attenuation, and Shear Attenuation
% % This program finds the attenuation values based on the sediment type (dB/m)
% % See relevant function by Miller and Potti: atten.m
% 
% % First, assign type_sand, type_silt, or type_clay based on Hamilton (1980), Table IA.
% % Like Miller and Potti's function (atten.m), assign the first four sediments in Hamilton (1980)
% % Table IA as sand-type, next two as silt-type, and last three as clay-type.
% 
% HamiltonPhi = [0.92; 2.65; 3.38; 4.35; 5.02; 5.40; 5.86; 7.02; 8.52]; % Grain diams. (φ) from Hamilton (1980), Table IA
% [~, idx_bestPhi] = min(abs(HamiltonPhi - grain_size));  % Find the grain size in Hamilton (1980) Table
% bestPhi = HamiltonPhi(idx_bestPhi);                     % IA which the input grain size is nearest to
% 
% % Assign values for sand, or set up table for interpolation
% shear_sand = 170; % Check value and citation
% 
% % Assign values for silt, or set up table for interpolation
% shear_silt = 200; % Hard-coded in atten.m; no reference given
% 
% % Assign values for clay, or set up table for interpolation
% shear_clay=[1500 125;
%     1600 300;
%     1700 400;
%     1800 500;
%     2000 600];  % Reference:
% 
% switch bestPhi
%     case {0.92, 2.65, 3.38, 4.35} % SAND-TYPE SEDIMENTS
%         shear_vel = shear_sand;
% 
%     case {5.02, 5.40} % SILT-TYPE SEDIMENTS
%         shear_vel = shear_silt;
% 
%     case {5.86, 7.02, 8.52} % CLAY-TYPE SEDIMENTS
%         shear_vel = interp1(shear_clay(:,1),shear_clay(:,2),sed_vel); % shear_vel = interp1(shear_clay(:,1),shear_clay(:,2),sed_speed);
% end
% 
% %% NOTES: Differences between this function and atten.m
% 
% % Instead of type, this function uses Grain Size to choose whether to assign sand-type,
% % silt-type, or clay-type values.
% 
% %% Part III: Set density as 1.65, the constant sediment density used by OALIB's function socal_sed.m. 
% sed_dens = 1.65; % Constant sediment density used by OALIB's function socal_sed.m.