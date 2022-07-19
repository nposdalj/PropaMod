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
%% Loop through .shd files
detfn = ['Radial_','.*','.shd']; %.shd file names
fileList = cellstr(ls(inputDir)); %all file names in folder
fileMatchIdx = find(~cellfun(@isempty,regexp(fileList,detfn))>0); % Find the file name that matches the filePrefix
concatFiles = fileList(fileMatchIdx); %find actual file names

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
end

load(fullfile(inputDir, 'package_for_constructWS.mat'))
load(fullfile(inputDir, '.shd files'))
%% Construct rr and nrr
% rr - Vector w/ range of hydrophone stepping by # m
% nrr - Total # of range steps in data
rr = rangeStep; % re-save rangeStep from bellhopDetRange.m as rr
nrr             % re-save range variable from bellhopDetRange.m as nrr
%% Construct rd_all
% rd_all - Cell array w/ each cell containing the depths for 1 radial
rd_all
% Now that I think about it did John load this in separately? In which case
% this intermediate file might have to be switched up accordingly
%% Construct sortedTLVec
% sortedTLVec - Cell array w/ each cell containing the TL for 1 radial
sortedTLvec % this is the thing we need to extract from BELLHOP's .shd's but we dk how

% Step 1: Extract TL from .shd's
% Step 2: Organize data
%% Save and export workspace for pDetSim_v3Pm.m

save('filename.mat','rr','nrr','rd_all','sortedTLvec')
