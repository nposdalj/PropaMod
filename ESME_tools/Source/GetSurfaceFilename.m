function RunDef = GetSurfaceFilename(RunDef, DirInfo)
%GetSurfaceFilename    UI for getting Surface Elevation Profile Filename from User
%
%                RunDef = GetSurfaceFilename(RunDef)  ;
%
% Revision 0.0   02 December 2004 ... ALM
%

persistent SurfPath

TRUE   = 1;
FALSE  = 0;

if ~isempty(RunDef.SurfFName)
   SurfPath = StripPath(RunDef.SurfFName);
elseif isempty(SurfPath)
   SurfPath = [DirInfo.MainWork RunDef.SubDir];
end

if nargin ~= 2
   error('ERROR -> GetSurfaceFilename: Incorrect number of parameters');
else
   % assume reset
   RunDef.SurfFName = '' ;
   RunDef.UseSurfFile = 0;
   
   % prompt for file 
   Prompt = {'Use surface profile data  file (number of ranges then range (km) depth (m) pairs) (y/n)'};
   if RunDef.UseSurfFile
      SurfStr = 'y';
   else
      SurfStr = 'n';
   end
   Ans = inputdlg(Prompt,'Surface Profile Data ... ', [1,100], {SurfStr});

   if ~isempty(Ans)
      RunDef.UseSurfFile = strcmpi(Ans{1}, 'y');
      if RunDef.UseSurfFile
         Here = pwd;
         if ~exist(SurfPath, 'dir');
            LibMakeDirectory(SurfPath);
         end
         cd(SurfPath);
         [File Path] = uigetfile('*.srf', 'Surface data file (<Cancel> = use flat surface profile)');
         cd(Here);
         if File ~= 0
            SurfPath         = Path;
            RunDef.SurfFName = [Path File];
         end
      end
   end
end