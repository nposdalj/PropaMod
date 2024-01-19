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
Site = 'CCE';
Region = 'CCE';
sp = 'Pm';
date = '240109c'; %date you created the transmission loss model
freq = '8.5kHz'; %peak frequency
%freqDir = '010'; %peak frequency for saving purposes (009, 010, 011)
freqDir = '8.500000e+00'; %peak frequency for saving purposes (009, 010, 011)

GDrive = 'G';
% inputDir = [GDrive,':\My Drive\PropagationModeling\Radials\',Site,'\',date,'\',freq]; % Where your data is coming from
% exportDir = [GDrive,':\My Drive\PropagationModeling\DetSim_Workspace\',Site]; % Where the assembled workspace will be saved
inputDir = ['H:\CCE_CCE\PropaMod\Radials\',Site,'\',date,'\',freq]; % Where your data is coming from
exportDir = ['H:\CCE_CCE\PropaMod\DetSim_Workspace\',Site]; % Where the assembled workspace will be saved
%% Load workspace from bellhopDetRange to extract nrr and rr
load(fullfile(exportDir, [Site,'_',date,'_',freqDir,'kHz_bellhopDetRange.mat']))
%% Loop through .shd files and extract depth and transmission loss
detfn = ['.*','.shd']; %.shd file names
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
    % matOut = ESME_TL_3D(D, 'Bellhop');
    matOut = ESME_TL_3D(inputDir, 'Bellhop');
    
    %create transmisson loss model
    PLslice = squeeze(pressure(1, 1,:,:));
    PL = -20*log10(abs(PLslice));
    PL(:,1) = PL(:,2);
    %PL(:,:) = PL(:,:)+6;
    sortedTLVec(idsk) = {PL}; 
   
    %save radial depth
    rd_inter = Pos.r.z;
    rd_all(idsk) = {rd_inter}; %depth array to be used in pDetSim
end
thisAngle = radials; %change radial variable to match pdetSim code
%% Save and export workspace for pDetSim_v3Pm.m
save([exportDir,['\',Site,'_',freq,'_3DTL.mat']],'rr','nrr','rd_all','sortedTLVec','hdepth','thisAngle','botDepthSort','freqSave','-v7.3')