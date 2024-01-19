%VZ: Modified from Eric Snyder's makeEnv.m code

function makeEnv(filepath, filename, freq, z, ssp, SD, RD, NR, RR, SSPint, SurfaceType, BottomAtten, VolAtten, botModel, botParms)

fpn = fullfile(filepath, [filename, '.env']);

% make file or erase current contents of file:
fid = fopen(fpn, 'w');
fclose(fid);

% open file to append contents
fid = fopen(fpn, 'at');

% line 1: title
fprintf(fid, ['''', filename, '''']);
fprintf(fid, '\t!TITLE\n');

% line 2: freq
% fprintf(fid, '12000\t!Freq (Hz)\n');
fprintf(fid, [num2str(freq),'\t!Freq (Hz)\n']);

% line 3: No. of media
fprintf(fid, '1\t! NMEDIA\n');

% line 4: interpolation type
txtCombo = [SSPint,SurfaceType,BottomAtten,VolAtten];
fprintf(fid, ['''',txtCombo,'''\t! SSPOPT (Analytic or C-linear interpolation)\n']);

% line 5: Bottom depth, number of depth values
fprintf(fid, '%d  0.0  %.3f\t! Depth of bottom (m)\n', 2, max(z));

% lines 6 to 6 + N: depth and ssp
fprintf(fid, '%d\t%.6f\t/ \n', z(1), ssp(1));
for nz = 2:length(z)
    fprintf(fid, '%.3f\t%.6f\t/ \n', z(nz), ssp(nz));
end

% Acoustic elastic half-space properties
switch botModel
    case {'A', 'Y'}
        fprintf(fid, '''A*'' 0.0\n');
        %A = model as Acousto-Elastic half space
        fprintf(fid, ' %.2f  %.1f  %.1f %.2f %.3f  /\n', ...
            botParms.SiteDepth, botParms.compSpeed, botParms.shearSpeed, botParms.density, botParms.compAtten);%JAH fixed bug
% fprintf(fid, ' 5000.0  %.3f  0.0 1.5 0.5  /\n', max(ssp)*1.01);
% Params: Depth, Compressional speed, Shear speed, Density, Compressional attenuation, Shear attenuation
%1.5 likely density (according to VZ)
%max(ssp)*1.01 = 1500 = sound speed profile in the mud (but probably off)
%0.5 is the attenuation
%0 = no density contrast or RMS roughness?
%5000 max depth

%Format of the above (added by AD for clarification)
%fprintf(fid, 'max depth, %.3f, density contrast, likely density,
%attenuation, /\n', sound speed profile in the mud)
case 'G'
        fprintf(fid, '''G*'' 0.0\n');
        fprintf(fid, ' %.2f  %.2f  /\n', max(ssp), botParms);
end

% Number of source depths (hydrophone location)
fprintf(fid, '%d\t! No. of SD\n', length(SD));

% Source depths
fprintf(fid, '%.4f  ', SD);
fprintf(fid, '/\t! SD\n');

% Number of receiver depths (ship locations)
fprintf(fid, '%d\t! No. of RD\n', length(RD));

% receiver depths
fprintf(fid, '%.4f  ', RD);
fprintf(fid, '/\t! RD\n');

% Number of receiver ranges (ship locations)
fprintf(fid, '%d\t! No. of RR\n', NR);

% Source depths
fprintf(fid, '%.4f  ', RR./1000);
fprintf(fid, '/\t! RR\n');

% model type
modelType = 'I';
fprintf(fid, ['''', modelType, '''\n']);

%No. of beams
switch modelType
    case 'I'
        fprintf(fid, '5000\n'); %JAH hard coded to 5000, otherwise is 32000
    case 'E'
        fprintf(fid, '2001\n')
    case 'C'
        fprintf(fid, '0\n');
end

% Beam angles - from Kait's 2016 paper
% "Three thousand rays were projected from the sensor position along each 
% radial at launch angles ranging from 0 to 90, where 90 is directly above the instrument"
%fprintf(fid, '0  90 /\n');
%fprintf(fid, '-90  90 /\n');
fprintf(fid, '-90  90 /\n');

% Step, ZBOX, RBOX (don't really know what this does)
% set step to 0 to allow program to select
%ZBOX - maximum ray depth (m)
%RBOX - maximum ray range (km)
% fprintf(fid, '50  5000 101.0');
fprintf(fid, '0.0 5000 40.4'); 

fclose(fid);