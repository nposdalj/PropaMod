% pDetSim_constructWS.m
% Role in workflow:
    % bellhopDetRange.m -> pDetSim_constructWS.m -> pDetSim_v3Pm.m
    % Build radials        Adapt output             Model det probability
% Uses output from bellhopDetRange.m to generate a workspace friendly for
% pDetSim_v3Pm.m, as it is configured at present.

% In recording 7/15/22 - we go through what all the vars are at ~0:40:00
% Code outline started by AD and script continued by NP 07182022
% Edited to loop through all site folders NP 05172023
% WASD 2024/01/19 - Incorporated edits made by JAH to pDetSim_constructWS.m
clearvars
close all
%% Params defined by User
% AllSite = {'BS','GS','JAX','BC','NC','NFC','OC','WC','BP','HZ','HAT_A','HAT_B'};
AllSite = {'AB'};
Region = 'GoA';
sp = 'Pm';
GDrive = 'G';
% inputDirMAIN = [GDrive,':\My Drive\PropagationModeling\Radials\']; % Where your data is coming from
% exportDirMAIN = [GDrive,':\My Drive\PropagationModeling\DetSim_Workspace\']; % Where the assembled workspace will be saved
% inputDirMAIN = 'H:\Baja_GI\PropaMod\Radials\'; % Where your data is coming from (for Baja)
% exportDirMAIN = 'H:\Baja_GI\PropaMod\DetSim_Workspace\'; % Where the assembled workspace will be saved (for Baja)
inputDirMAIN = 'H:\GoA_AB\PropaMod\Radials\'; % Where your data is coming from (for GoA)
exportDirMAIN = 'H:\GoA_AB\PropaMod\DetSim_Workspace\'; % Where the assembled workspace will be saved (for GoA)
for v = 1:length(AllSite)
    site = AllSite{v};
    exportDir = [exportDirMAIN,site];
    
    %Find all workspace that end with .bellhopDetRange (for all three classes)
    firstFN = [site,'.*','bellhopDetRange.mat'];
    fileList = cellstr(ls(exportDir)); % Get a list of all the files in the start directory
    fileMatchIdx = find(~cellfun(@isempty,regexp(fileList,firstFN))>0);
    concatFilesMAIN = fileList(fileMatchIdx);
    
    for w = 1:length(concatFilesMAIN)
        % Load all workspace from bellhopDetRange to extract nrr and rr
        load(fullfile(exportDir, concatFilesMAIN{w}))
        %Find fequency for naming
        if contains(concatFilesMAIN{w},'9.500000e+00kHz')
            freq = '9.5kHz';
            freqNAME = '9.500000e+00kHz';
        elseif contains(concatFilesMAIN{w},'010kHz')
            freq = '10kHz';
            freqNAME = '010kHz';
        elseif contains(concatFilesMAIN{w},'8.500000e+00kHz')
            freq = '8.5kHz';
            freqNAME = '8.500000e+00kHz';
        elseif contains(concatFilesMAIN{w},'7.750000e+00kHz')
            freq = '7.75kHz';
            freqNAME = '7.750000e+00kHz';
        elseif contains(concatFilesMAIN{w},'9.250000e+00kHz')
            freq = '9.25kHz';
            freqNAME = '9.250000e+00kHz';
        else
            freq = '10.5kHz';
            freqNAME = '1.050000e+01kHz';
        end
        %% Loop through .shd files and extract depth and transmission loss
        %find folder name to specify .shd file
        texta = extractAfter(concatFilesMAIN{w},[site,'_']);
        textb = extractBefore(texta,['_',freqNAME]);
        inputDir = [inputDirMAIN,site,'\',textb,'\',freq];
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
            % matOut = ESME_TL_3D(D, 'Bellhop');            % Added by JAH
            matOut = ESME_TL_3D(inputDir, 'Bellhop');       % Added by JAH
    
            %create transmisson loss model
            PLslice = squeeze(pressure(1, 1,:,:));
            PL = -20*log10(abs(PLslice));
            PL(:,1) = PL(:,2);
            sortedTLVec(idsk) = {PL}; 
   
            %save radial depth
            rd_inter = Pos.r.z;
            rd_all(idsk) = {rd_inter}; %depth array to be used in pDetSim
        end
        thisAngle = radials; %change radial variable to match pdetSim code
        %% Save and export workspace for pDetSim_v3Pm.m
        save([exportDir,['\',site,'_',freq,'_3DTL.mat']],'rr','nrr','rd_all','sortedTLVec','hdepth','thisAngle','botDepthSort','freqSave','-v7.3')
    end
end