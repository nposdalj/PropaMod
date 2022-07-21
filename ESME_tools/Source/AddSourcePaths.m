function DirInfo = AddSourcePaths(DirInfo)
%AddSourcePaths        Adds paths to source code
%
% USAGE:       AddSourcePaths(DirInfo)
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

[PathList, DirInfo] = GetSourcePaths(DirInfo);
% ADD
for ii = 1:length(PathList)
   addpath(PathList{ii});
end