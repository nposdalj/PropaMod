function [ArrData, delta] = ReadBellhopArrData(ArrData, rr, rd, sd)
%ReadBellhopArrData       Extracts subset of data from (full or partial) ArrData structure as output by ReadBellhopArrFile
%
%USAGE                    [ArrData, exact] = ReadBellhopArrFile(ArrData, rr, rd, sd)
%
%INPUT                    ArrData          = source data structre - see ReadBellhopArrFile
%                         rr,rd,sd         = receiver range, receiver depth, source depth
%                                            any of these can be passed ':' to indicate all or a single value only (do not pass vectors)
%                                            (if any of these is empty - NOT MISSING, but empty, then they become ':')
%
%OUTPUT
%                         ArrData.Amp
%                                .Delay
%                                ....           see ReadBellhopArrFile
%                                               This will be [] on error
%
%                         delta                 = max(abs((rrfile-rr)/rr),abs((rrfile-rd)/rd),abs((sdfile-sd)/sd));
%                                               = 0  for exact match
%                                               = [] for un- or incompletely specified (rr,rd,sd);
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
%                               
%
%Revision 0.0     21 September 2005 ... Amos L Maggi

persistent pathname;

TRUE    = 1 ;
FALSE   = 0 ;

if nargin < 4
   return;
end

if isempty(rr)
   rr = ':';
end
if isempty(rd)
   rd = ':';
end
if isempty(sd)
   sd = ':';
end

if ischar(rr)
   if rr(1) == ':'
      rri    = [1:length(ArrData.RR)];
      % no need to compare values
      drr    = 0;
   else % if any other char escape !!
      return;
   end
else
   [rrfile, rri] = find_nearest(ArrData.RR, rr);
   drr           = abs((rrfile-rr)/rr);
end
if ischar(rd)
   if rd(1) == ':'
      rdi    = [1:length(ArrData.RD)];
      drd    = 0;
   else
      return;
   end
else
   [rdfile, rdi] = find_nearest(ArrData.RD, rd);
   drd           = abs((rdfile-rd)/rd);
end
if ischar(sd)
   if sd(1) == ':'
      sdi    = [1:length(ArrData.SD)];
      dsd    = 0;
   else
      return;
   end
else
   [sdfile, sdi] = find_nearest(ArrData.SD, sd);
   dsd           =  abs((sdfile-sd)/sd);
end

delta               =  max([drr,drd,dsd])                ;

% for some reason ReadArrivalsAsc has a fixed length for Amp and Delay of 100 

vidx   = [1:ArrData.NArrMat(rri,rdi,sdi)];

ArrData.Amp         = ArrData.Amp(rri,vidx,rdi,sdi)         ;
ArrData.Delay       = ArrData.Delay(rri,vidx,rdi,sdi)       ;
ArrData.SrcAngle    = ArrData.SrcAngle(rri,vidx,rdi,sdi)    ;
ArrData.RcvrAngle   = ArrData.RcvrAngle(rri,vidx,rdi,sdi)   ;
ArrData.NumTopBnc   = ArrData.NumTopBnc(rri,vidx,rdi,sdi)   ;
ArrData.NumBotBnc   = ArrData.NumBotBnc(rri,vidx,rdi,sdi)   ;
ArrData.NArrMat     = vidx(end)                             ;
ArrData.SD          = ArrData.SD(sdi)                       ;
ArrData.RD          = ArrData.RD(rdi)                       ;
ArrData.RR          = ArrData.RR(rri)                       ;

