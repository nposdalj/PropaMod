function RunDef = GetBathymetryFilename(RunDef, DirInfo)
%GetBathymetryFilename    UI for getting Bathymetry Filename from User
%
%                RunDef = GetBathymetryFilename(RunDef)  ;
%
% Revision 0.0   02 December 2004 ... ALM
% Revision 0.1   13 May      2005 ... ALM
%                - bug and stupidity correction
% Revision 0.2   06 June     2006 ... ALM
%                - modify prompts

persistent BathPath

TRUE   = 1;
FALSE  = 0;
NOYES  = {'NO','YES'};
BathName = '';

if nargin ~= 2
   error('ERROR -> GetBathymetryFilename: Incorrect number of parameters');
else
    % path and file defaults 
    if ~isempty(RunDef.BathFName)
        [BathPath,BathName] = StripPath(RunDef.BathFName);
    elseif isempty(BathPath)
        BathPath = [DirInfo.MainWork RunDef.SubDir];
    end

   %prompt for file
   done = FALSE;
   while ~done
       done   = TRUE;
       tstr   = 'Bathymetry File Specification';
       prompt = {'Use Bathymetry File?', ...
                 '', ...
                 '         Models that do not support range-dependent', ...
                 '          bathymetry will ignore specified the specified file', ...
                 '', ...
                 '         FILE FORMAT:  row 1 -> N;  rows 2:N+1 -> r(km) z(m)',''};
       bstrs  = {'NO','YES - GET FILE','USE CURRENT','?'};
       defidx = 1;
       if ~isempty(BathName)
           prompt = [prompt, {['CURRENT:  ', RunDef.BathFName],''}];
           if RunDef.UseBathFile, defidx = 3; end
           bstr   = questdlg(prompt,tstr, bstrs{1}, bstrs{2}, bstrs{3}, bstrs{defidx});
       else
           if RunDef.UseBathFile, defidx = 2; end
           bstr   = questdlg(prompt,tstr, bstrs{1}, bstrs{2}, bstrs{4}, bstrs{defidx});
       end

       switch bstr         
           case bstrs{1}
               % switch OFF and no change to file 
               RunDef.UseBathFile = FALSE;
           case bstrs{2}
               here = pwd;
               if exist(BathPath, 'dir');
                   cd(BathPath);
               end
               [File Path] = uigetfile('*.bty', 'Bathymetry data file',BathName);
               cd(here);
               if File ~= 0
                   RunDef.UseBathFile = TRUE;
                   BathPath           = Path;
                   RunDef.BathFName   = [Path File];
               else 
                   done = FALSE;
               end
           case bstrs{3}
               % switch ON and use current file
               RunDef.UseBathFile = TRUE;
           case bstrs{4}
               done = FALSE;
               hmsg = {'Bathymetry file data is supplied as a 2-column ascii file', '' ...
                       'row 1           -> N : N = # of data pairs'               , '',...
                       'row 2:N+1   ->  r(km)  z(m)'                               };
               uiwait(msgbox(hmsg,'Bathymetry File Specification','help','modal'));
       end
   end
end