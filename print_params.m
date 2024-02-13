% print_params.m
% WASD 2024-01-29 - Created print_params.m

% Report all user input parameters associated with PropaMod model, in plain
% language. Save as text file.
% print_params.m is set up as a subroutine to the program
% bellhop_PropMod.m, and will not work independent of that program.

% Create file and prep for editing
txtFileName = [runID '_' freqiChar 'kHz_Input_Parameters.txt'];
paramfile = fullfile(midDirFi, txtFileName);
% Make file or erase current contents of file
fid = fopen(paramfile, 'w');
fclose(fid);
% Open file to append contents
fid = fopen(paramfile, 'at');

% Header
fprintf(fid, ['User Input Parameters for Run ' runID ', Freq ' freqiChar ' kHz']);
fprintf(fid, ['\n\nAuthor\t' author]);
fprintf(fid, ['\nTimestamp\t' char(string(datetime('now', 'Format', 'yyyyMMdd HHmmss')))]);
fprintf(fid, ['\nNotes\t' userNote]);
fprintf(fid, ['\n\nRegion\t' Region]);
fprintf(fid, ['\nSite\t' Site]);
fprintf(fid, ['\nFrequency\t' num2str(freq{freqi})]);

% Section 1: SSP Specs
fprintf(fid, '\n\nSSP SPECS'); % Header
fprintf(fid, ['\nFile Name\t' SSPfile]); % File name
fprintf(fid, ['\nSSP Type\t' SSPtype]);
fprintf(fid, ['\nMonth\t' SSPmoReporting]);

% Section 2: Hydrophone Specs
fprintf(fid, '\n\nHYDROPHONE SPECS');
fprintf(fid, ['\nSL\t' num2str(SL)]); % This is reported, but it doesn't affect the model
fprintf(fid, ['\nSD\t' num2str(SD)]);
fprintf(fid, ['\nLatitude\t' num2str(hlat)]);
fprintf(fid, ['\nLongitude\t' num2str(hlon)]);
fprintf(fid, ['\nDepth\t' num2str(hdepth)]);
fprintf(fid, ['\Z-config Method\t' hzconfig]); % Method to configure hydrophone z-position
fprintf(fid, ['\Set Depth or Elevation\t' num2str(hz)]);

% Section 3: Model Specs
fprintf(fid, '\n\nMODEL SPECS'); % header
fprintf(fid, ['\nBELLHOP Version\t' bellhopVersion]);
fprintf(fid, '\nBATHYMETRY MODEL'); % Subsection: Bathymetry Model
fprintf(fid, ['\nBathymetry file\t' fullfile(GEBCODir, GEBCOFile)]);
fprintf(fid, ['\nBathymetry Model\t' BTYmodel]);
fprintf(fid, '\nENVIRONMENT MODEL'); % Subsection: Environment Model
fprintf(fid, ['\nSS Interpolation Method\t' SSPint]);
fprintf(fid, ['\nType of Surface\t' SurfaceType]);
fprintf(fid, ['\nAttenuation in Bottom\t' BottomAtten]);
fprintf(fid, ['\nThorpe Volume Attenuation\t' VolAtten]);
fprintf(fid, '\nSEA FLOOR MODEL'); % Subsection: Sea Floor Model
fprintf(fid, ['\nSea Floor Model\t' botModel]);
switch botModel
    case 'A'
        fprintf(fid, ['\nCompressional Speed\t' num2str(AEHS.compSpeed)]);
        fprintf(fid, ['\nShear Speed\t' num2str(AEHS.shearSpeed)]);
        fprintf(fid, ['\nDensity\t' num2str(AEHS.density)]);
        fprintf(fid, ['\nCompressional Attenuation\t' num2str(AEHS.compAtten)]);
    case {'G', 'Y'}
        fprintf(fid, '\nSediment Dataset\tB, BST');
        if strcmp(sedDatType, 'B')
            fprintf(fid, ['\nForce Low Resolution\t' num2str(forceLR)]);
        end
end

% Section 4: Model range and resolution
fprintf(fid, '\n\nRANGE & RESOLUTION');
fprintf(fid, ['\nRange\t' num2str(Range) ' m']);
fprintf(fid, ['\nRange Step\t' num2str(rStep) ' m']);
fprintf(fid, ['\nNumber of Radials\t' num2str(numRadials)]);
fprintf(fid, ['\nRad Step\t' num2str(thetaStep)]);
fprintf(fid, ['\nDepth Step\t' num2str(zStep) ' m']);

% Section 5: Plotting Specs
fprintf(fid, '\n\nPLOTTING SPECS');
fprintf(fid, ['\nGenerate Polar Plots\t' num2str(generate_PolarPlots)]);
fprintf(fid, ['\nGenerate Radial Plots\t' num2str(generate_RadialPlots)]);
fprintf(fid, ['\nRL Threshold\t' num2str(RL_threshold)]);
fprintf(fid, ['\nRL Plot Maximum\t' num2str(RL_plotMax)]);
fprintf(fid, ['\nDepth Levels\t' num2str(makePolarPlots)]);

% Section 6: SSP
fprintf(fid, '\n\n\nSSP\nDepth\tSound Speed'); % header
SSP_Reporting = (SSP).';
fprintf(fid, '\n%4.0f\t%4.11f', SSP_Reporting);

% End
fclose(fid);

copyfile(paramfile,fullfile(endDirFi, txtFileName)) % Copy to saveDir_sub
copyfile(paramfile,fullfile(plotDirFi, txtFileName)); % Copy to plotDir