% pDetSim_constructWS.m
% Role in workflow:
    % bellhopDetRange.m -> pDetSim_constructWS.m -> pDetSim_v3Pm.m
    % Build radials        Adapt output             Model det probability
% Uses output from bellhopDetRange.m to generate a workspace friendly for
% pDetSim_v3Pm.m, as it is configured at present.

% In recording 7/15/22 - we go through what all the vars are at ~0:40:00
% Code outline started by AD and script continued by NP 07182022
clearvars
close all
%% Params defined by User
Site = 'NC';
Region = 'WAT';
sp = 'Pm';

GDrive = 'I';
inputDir = [GDrive,':\My Drive\PropagationModeling\Radials\',Site]; % Where your data is coming from
exportDir = [GDrive,':\My Drive\PropagationModeling\DetSim_Workspace\',Site]; % Where the assembled workspace will be saved
%% Load workspace from bellhopDetRange to extract nrr and rr
load(fullfile(exportDir, [Site,'_bellhopDetRange.mat']))
%% Loop through .shd files and extract depth and transmission loss
detfn = ['Radial_','.*','.shd']; %.shd file names
fileList = cellstr(ls(inputDir)); %all file names in folder
fileMatchIdx = find(~cellfun(@isempty,regexp(fileList,detfn))>0); % Find the file name that matches the filePrefix
concatFiles = fileList(fileMatchIdx); %find actual file names

rd_all = num2cell(zeros(1,length(concatFiles))); %create empty array for radial depth to be used later with pDetSim
sortedTLVec = num2cell(zeros(1,length(concatFiles))); %create empty array for transmission loss to be used later with pDetSim

for idsk = 1 : length(concatFiles)
    % Load file
    fprintf('Loading %d/%d file %s\n',idsk,length(concatFiles),fullfile(inputDir,concatFiles{idsk}))
    D = fullfile(inputDir,concatFiles{idsk});
    [PlotTitle, PlotType, freqVec, freq0, atten, Pos, pressure] = read_shd(D);
    PLslice = squeeze(pressure(1, 1,:,:));
    PL = -20*log10(abs(PLslice));
    [x1,y1] = meshgrid(1:10:(10*size(PL,2)),1:10:(10*size(PL,1))); %10 in 1:10:(10*size(PL,2)) varies with resolution; note to self to remove hard-coding
    [xq1,yq1] = meshgrid(1:(10*size(PL,2)),1:(10*size(PL,1))); %10 in 1:(10*size(PL,2)) varies with resolution; note to self to remove hard-coding
    zq = interp2(x1,y1, PL,xq1, yq1);
    
    zq = interp2(x1,y1, PL,xq1, yq1);
    sortedTLVec(idsk) = {zq}; %transmission loss vector to be used in pDetSim
    
    %save radial depth
    rd_inter = Pos.r.z;
    rd_all(idsk) = {rd_inter}; %depth array to be used in pDetSim
end
%% Save and export workspace for pDetSim_v3Pm.m
save([exportDir,['\',site,'_','12kHz_3DTL.mat']],'rr','nrr','rd_all','sortedTLVec','hdepth','-v7.3')