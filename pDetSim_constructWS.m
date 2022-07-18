% pDetSim_constructWS.m
% Role in workflow:
    % bellhopDetRange.m -> pDetSim_constructWS.m -> pDetSim_v3Pm.m
    % Build radials        Adapt output             Model det probability
% Uses output from bellhopDetRange.m to generate a workspace friendly for
% pDetSim_v3Pm.m, as it is configured at present.

% In recording 7/15/22 - we go through what all the vars are at ~0:40:00
clearvars
close all

%% Params defined by User
Site = 'GS';
Region = 'WAT';
sp = 'Pm';

GDrive = 'H';
inputDir = [GDrive,'']; % Where your data is coming from
exportDir = [GDrive,'']; % Where the assembled workspace will be saved

%% Load in data
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
