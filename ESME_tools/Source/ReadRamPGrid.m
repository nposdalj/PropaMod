function PGrid = ReadRamPGrid(Species, VNum, FileName)
%ReadRamPGrid
%
%This function reads a RAM p.grid file into a single matrix of complex pressure
%Each row corresponds to a constant depth
%Each column corresponds to a constant range
%An empty matrix is returned if the file could not be read
%
%USAGE: PGrid    = ReadRamPGrid(Species, VNum, FileName)
%
%       PGrid    -> complex pressure field matrix
%       VNum     -> RAM version/build number (see version history below)
%       FileName -> path and filename for RAM grid output (something.grid usually)
%
% Background:
%
% Different compilers or compiler options affect the structure of binary
% records produced by the executable ... additional bytes appear at the 
% beginning of each record - the size of the record and number of 'junk'
% bytes depend on the compilation
%
% Valid VERSION Numbers ...
%
%             RAM Version Numbers
%             -------------------
%             NONE at this stage
%
%             RAMGeo Version Numbers
%             ----------------------
%             []                use that retreived by 'GetRAMVersionData.m'
%
%             1.5C00.01.00.01   version   1.5
%                               CMST extension 0.01.00 ... 
%                                   (user defined input and output filenames)
%                               Build Number:  001
%                               Compiler:      Compaq Visual Fortran 6 (ALM)
%                               Compiled:      05.06.2003 
%
%
% Related functions
% --------------------
% ReadRamTlGrid    
%
% Version History
% ---------------
% Revision 0.0        18 June 2003     ... ALM
%
% Revision 0.1        12 October 2004  ... ALM
%                    - VNum can now be passed as [] and the current version data held by GetRAMVersionData.m is used
%
%
% CMST 
% Physics Department
% Curtin University
% Perth, WA
%

% some constants
true = 1;
false = 0;
fnstr = 'ReadRamPGrid';
RecLenDependent = -1;

%initialise output
PGrid = [];

% DEAL WITH IP PARAMETERS
% is there enough of them
if nargin < 3
  msgbox({'Number of input arguments too small incorrect', ...
          'RAM Species, CMST build number for RAM or .grid filename not specified', ...
          'Function Aborted'}, ...
         fnstr, 'warn');
  return;     
end  
% is VNum on auto ?
if isempty(VNum)
   VNum = 'AUTO'; % auto
end

switch upper(VNum)
   case 'AUTO'
      RAMVersionData   = GetRAMVersionData(Species)'     ;
      HeadJunkFieldNum = RAMVersionData.PGridFormat.HeadJunkFieldNum ;
      HeadJunkFieldSiz = RAMVersionData.PGridFormat.HeadJunkFieldSiz ;
      DataJunkFieldNum = RAMVersionData.PGridFormat.DataJunkFieldNum ;
      DataJunkFieldSiz = RAMVersionData.PGridFormat.DataJunkFieldSiz ;
      NzFieldSiz       = RAMVersionData.PGridFormat.NzFieldSiz       ;
      DataFieldNum     = RAMVersionData.PGridFormat.DataFieldNum     ;
      DataFieldSiz     = RAMVersionData.PGridFormat.DataFieldSiz     ;
   otherwise
      % hard coded version dependent binary decoding data - (shouldn't be required any longer)
      % choose version (avoiding case issues with C)
      switch upper(Species)
         case {'RAM', 'RAMS', 'RAMSURF'}
            msgbox({[Species, ' is not yet covered by this function:'], ...
               'Function Aborted'}, ...
               fnstr, 'warn');
            return;
         case 'RAMGEO'
            switch upper(VNum)
               case {'1.5C00.01.00.01'}
                  HeadJunkFieldNum = 1;
                  HeadJunkFieldSiz = 'uint32';
                  DataJunkFieldNum = 2;
                  DataJunkFieldSiz = 'uint32';
                  NzFieldSiz       = 'int32';
                  DataFieldNum     = RecLenDependent;
                  DataFieldSiz     = 'float32';

               otherwise
                  msgbox({'Invalid CMST build number for RAMGeo:', ...
                     ['"VNum = ',VNum, '" ?'], ...
                     'Function Aborted'}, ...
                     fnstr, 'warn');
                  return;
            end % build number
         otherwise
            msgbox({'Invalid Species:', ...
               ['"', Species, '" ?'], ...
               'Function Aborted'}, ...
               fnstr, 'warn');
            return;
      end  % species
end % Vnum

FileID = fopen(FileName, 'r', 'ieee-le');

PGrid = [];


if FileID >= 0
  % skip header junk bytes 
  [Junk, Count0] = fread(FileID, HeadJunkFieldNum, HeadJunkFieldSiz);  
  % read number of records in range slice (number of depths in grid)
  [Nz, Count1] = fread(FileID, 1, NzFieldSiz);
  % record length is the size of the range slice ... that is the number of depths
  if DataFieldNum == RecLenDependent
    RecordLen = Nz;  % junk bytes (potentially) added after this many fields 
  else 
    RecordLen = DataFieldNum;
  end  
   
  %disp([int2str(Nz) ' depth elements']);
  
  if (Count1 == 1) & (Nz > 0)
    DoneAll = false;
    PGrid = zeros(Nz, 1);
    PColumn = zeros(Nz, 1);
    
    ICol = 1;
    while ~DoneAll
      %ICol
      DoneCol = false;
      StartSub = 1;
      
      while ~DoneCol & ~DoneAll   
        EndSub = StartSub + 2*RecordLen - 1;
        if EndSub > 2*Nz
          EndSub = 2*Nz;
          DoneCol = true;
        end
        NRead = ((EndSub - StartSub) + 1)/2;
        if NRead > 0
          %Skip junk at start of each column / data record
          [Junk, Count0] = fread(FileID, DataJunkFieldNum, DataJunkFieldSiz);            
          if  Count0 < DataJunkFieldNum % premature eof or other problem?
            DoneAll = 1;
            
          else             
            [PFlat, Count2] = fread(FileID, 2*NRead, DataFieldSiz);    
            if Count2 == 2*NRead     % OK ?
              istart = (StartSub+1)/2;
              iend   = EndSub/2;
              PColumn(istart:iend, 1) = PFlat(StartSub:2:(EndSub-1)) + sqrt(-1)*PFlat((StartSub+1):2:EndSub);
              StartSub = EndSub + 1;
            else                     % premature eof or other problem?
              DoneAll = true;
            end
          end
          
        else
          %disp('NRead <= 0');
          %NRead
          DoneCol = true;
        end
        
      end 
      if ~DoneAll
        PGrid(:, ICol) = PColumn(:);
        ICol = ICol+1;
      end
    end
    
  end
  fclose(FileID);
end
