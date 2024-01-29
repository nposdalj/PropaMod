% print_params.m
% WASD 2024-01-29 - Created print_params.m

% Report all user input parameters associated with PropaMod model.
% Save as text file.
% print_params.m is set up as a subroutine to the program
% bellhop_PropMod.m, and will not work independent of that program.

%% 7. Save User-input params to a text file; move this after SSP and include SSP that was inputted into that run (file name and the actual SSP)

hdepth = SD; % ADDED BY AD
txtFileName = [newFolderName '_' freqiChar 'kHz_Input_Parameters.txt'];
paramfile = fullfile(intermedDirFi, txtFileName);
fileid = fopen(paramfile, 'w');
fclose(fileid);
fileid = fopen(paramfile, 'at');
fprintf(fileid, ['User Input Parameters for Run ' newFolderName ', Freq ' freqiChar ' kHz'...
    '\n\nCreated by\t' author '\nDateTime\t' datestr(datetime('now'), 'yyyymmdd HHMMSS') '\nUser Note' userNote...
    '\n\nSite\t' Site '\nRegion\t' Region ...
    '\n\nSSP INPUT\nFile Name\t' SSPfile, '\nSSP Type\t' SSPtype '\nMonth\t' SSPmoReporting...
    '\n\nHYDROPHONE PARAMETERS\nSL\t' num2str(SL) '\nSD\t' num2str(SD) '\nhlat\t' num2str(hlat) '\nhlon\t' num2str(hlon) '\nhdepth\t' num2str(hdepth) '\nFrequency\t' num2str(freq{freqi})...
    '\n\nACOUSTO ELASTIC HALF-SPACE\nCompressional Speed\t' num2str(AEHS.compSpeed) '\nShear Speed\t' num2str(AEHS.shearSpeed) '\nDensity\t' num2str(AEHS.density) '\nCompressional Attenuation\t' num2str(AEHS.compAtten)...
    '\n\nRANGE & RESOLUTION\nRange\t' num2str(total_range) '\nRange Step\t' num2str(rangeStep) '\nNumber of Radials\t' num2str(numRadials) '\nRad Step\t' num2str(radStep) '\nDepth Step\t' num2str(depthStep)...
    '\n\nPLOT GENERATION\nGenerate Polar Plots\t' num2str(generate_PolarPlots) '\nGenerate Radial Plots\t' num2str(generate_RadialPlots)...
    '\nRL Threshold\t' num2str(RL_threshold) '\nRL Plot Maximum\t' num2str(RL_plotMax) '\nDepth Levels\t' num2str(makePolarPlots)... % '\nRadial Plots\t' num2str(makeRadialPlots)...
    '\n\n\nSSP\nDepth\tSound Speed']);
SSP_Reporting = (table2array(SSP)).';
fprintf(fileid, '\n%4.0f\t%4.11f', SSP_Reporting);
fclose(fileid);

copyfile(paramfile,fullfile(saveDir_subFi, txtFileName)) % Copy to saveDir_sub
copyfile(paramfile,fullfile(plotDirFi, txtFileName)); % Copy to plotDir