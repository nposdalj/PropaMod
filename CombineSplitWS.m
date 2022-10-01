% CombineSplitWS
% Created by AD 2022-09-26
%
% To be used when a run had to be split in two (e.g., the first one crashed
% partway through but that part of the DetSim_Workspace was salvaged).
% The final, combined DetSim_Workspace which this script produces will be
% named with the date of the first run followed by the suffix 'F'.
%
% Use this script after generating the initial workspaces with
% bellhop_PropMod.m.
% On the side, copy the radial data from the first and second runs into one
% combined folder (rec: title this with date of first run followed by the
% suffix 'F').

clearvars

%% Params Defined by user
Site = 'WC';
Run1 = '220926c';
Run1_Date = '220925';
Run2 = '220926a';
Freq = '010';

%% Generate combined workspace
% Things that should be same between first and second parts: 
%   freqSave, nrr, radials, rr

% The thing that needs to be concatenated: botDepthSort.
% Finally, hdepth (which is known during most of the bellhop_PropMod.m
% script as SD) is only generated during the first radial, so only the
% first run has it.

% Load first part and rename botDepthSort, and rename hdepth:
load(['G:\My Drive\PropagationModeling\DetSim_Workspace\' Site '\' Site '_' Run1 '_' Freq 'kHz_bellhopDetRange.mat'])
botDepthSort1 = botDepthSort;
hdepth1 = hdepth;

% Load second part and rename botDepthSort:
load(['G:\My Drive\PropagationModeling\DetSim_Workspace\' Site '\' Site '_' Run2 '_' Freq 'kHz_bellhopDetRange.mat'])
botDepthSort2 = botDepthSort;

% Make full-length botDepthSort
clear botDepthSort
botDepthSort = botDepthSort2; % Start by making botDepthSort equal to botDepthSort2
botDepthSort(1:size(botDepthSort1, 1), :) = botDepthSort1(:,:); % Add in values from botDepthSort1
% botDepthSort is now complete.

% % Manually enter freqSave.
% freqSave = '9';

% Manually restore hdepth.
hdepth = hdepth1;

% Save new DetSim_Workspace with the suffix 'F' to denote final, combined version
% Just use the date of the first run
save(['G:\My Drive\PropagationModeling\DetSim_Workspace\' Site '\' Site '_' Run1_Date 'F_' Freq 'kHz_bellhopDetRange.mat'],...
    'rr','nrr','freqSave','hdepth','radials','botDepthSort')