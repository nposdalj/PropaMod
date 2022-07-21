function [ArrData, delta, filename] = ReadBellhopArrFile(filename, rr, rd, sd)
%ReadBellhopArrFile       Convenient and optionally interactive envelope for ReadArrivalsAsc.m, returns data in structure 
%
%USAGE                    [ArrData, delta, pathname] = ReadBellhopArrFile(filename, [rr, rd, sd])
%
%INPUT                    filename         = source filename (usually .arr) (can also be used to pass default path without filename)
%                         rr,rd,sd         = receiver range, receiver depth, source depth
%                                            any of these can be passed ':' to indicate all or a single value only (do not pass vectors)
%
%                                            These are used by ReadBellhopArrData if supplied - see that function's help for details
%
%OUTPUT
%                         ArrData.Amp
%                                .Delay
%                                .SrcAngle
%                                .RcvrAngle
%                                .NumTopBnc
%                                .NumBotBnc
%                                .NArrMat
%                                .NSD
%                                .NRD
%                                .NR
%                                .SD
%                                .RD
%                                .RR
%
%
%                         delta                 = type "help ReadBellhopArrData" for details
%
%                          These are all R x A x D x S matricies unless the triple (rr, rd, sd) is specified 
%                          R = number or Rx Ranges
%                          A = maximum number of Arrivials
%                          D = number or Rx Depths
%                          A = number of Tx (Source) depths
%
%                          If (rr, rd, sd) is specified and does not completely match a point in the file, the closest point is returned
%                          Caller can check proximity by using the delta value (see definition above) 
%
%                          filename        = file from which data was extracted including path
%                               
%
%Revision 0.0     22 September 2005 ... Amos L Maggi
%Revision 0.01    24 April     2006 ... Amos L Maggi
%                 - bug fix: cd now returns to working directory after file selection 

persistent pathname;

TRUE  = 1;
FALSE = 0;

UseFile  = FALSE;
UsePath  = FALSE;
here     = pwd  ;
ArrData  = []   ;
delta    = []   ;
filename = ''   ;

if exist('filename', 'var') 
   if exist(filename, 'dir')  % dir only
      pathname = filename;
   elseif exist(filename, 'file')
      % use file supplied
      UseFile = TRUE;
   end
end
if ~isempty(pathname)
   if exist(pathname, 'dir')
      % ok to use pname
      UsePath = TRUE;
   end
end


% all branches covered by next conditional - existing filename passes over, cancel results in exit prior to read attempt
if ~UseFile
   if UsePath
      cd(pathname);
   end
   % INTERACTIVE BIT - ask for get file
   [ftemp, ptemp] = uigetfile('*.arr', 'Select file to plot');
   cd(here); 
   % test
   if isnumeric(ftemp) || isnumeric(ptemp)
      % cancelled      
      return;
   else
      filename = [ptemp ftemp] ;
      pathname = ptemp         ;
   end
end

% read file
[ Amp, Delay, SrcAngle, RcvrAngle, NumTopBnc, NumBotBnc, NArrMat, NSD, NRD, NR, SD, RD, RR ] = ReadArrivalsAsc(filename);

ArrData.Amp         = Amp         ;
ArrData.Delay       = Delay       ;
ArrData.SrcAngle    = SrcAngle    ;
ArrData.RcvrAngle   = RcvrAngle   ;
ArrData.NumTopBnc   = NumTopBnc   ;
ArrData.NumBotBnc   = NumBotBnc   ;
ArrData.NArrMat     = NArrMat     ;
ArrData.NSD         = NSD         ;
ArrData.NRD         = NRD         ;
ArrData.NR          = NR          ;
ArrData.SD          = SD          ;
ArrData.RD          = RD          ;
ArrData.RR          = RR          ;

if exist('rr', 'var') & exist('rd', 'var') & exist('sd', 'var') 
   [Temp, delta] = ReadBellhopArrData(ArrData, rr, rd, sd);
   if ~isempty(Temp)
      ArrData = Temp;
      clear('Temp');
   end
end


