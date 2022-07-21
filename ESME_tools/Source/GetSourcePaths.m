function [PathList, DirInfo] = GetSourcePaths(DirInfo)
%GetSourcePaths        Prepares paths to source code 
%                      (these are based on user specified root - subs are non-user spedified)
%
% USAGE:       PathList = GetSourcePaths(DirInfo)
%
%              PathList is a cell array of paths to be added
%
% INPUT        DirInfo      --> See AcTUP
%
% See AcTUP for object definitions
%
% Revision History
% ================
% Revision 0.0      17 July         2006 ... ALM
% Revision 0.1      25 July         2006 ... ALM
%                   - move source root definition here to avoid user overwrite
%                   - now need to return DirInfo
% -----------------------------------------------------------------------------------------------------------

ReleaseSpec       = LoadReleaseSpec;
DirInfo.Source    = [DirInfo.AcTUP, 'Source\']  ;

% PATH LISTS
% non-release dependent
PathList{1}      = DirInfo.Source                     ;
PathList{2}      = [DirInfo.Source, 'Utilities\']     ; 
PathList{3}      = [DirInfo.Source, 'PlottingTools\'] ; 
%     release dependent
switch ReleaseSpec
   case 'FULL'
      PathList{4}      = [DirInfo.Source, 'CmstClasses\']   ;
      PathList{5}      = [DirInfo.Source, 'PostProcessor\'] ;
end
      