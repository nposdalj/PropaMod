function WriteBellhopArrAtFieldPt(ArrData, filename)
%WriteBellhopArrAtFieldPt      Writes a subset of data from Bellhop arrival data (i.e. for a field point) to file
%
%USAGE                    WriteBellhopArrAtFieldPt(ArrData, filename)
%
%                         Before using this you will need to use:
%                                  ReadBellhopArrFile  -> data from file      -> structure
%                                  ReadBellhopArrData  -> data from structure -> structure for single field point 
%                                  SortBellhopArrData  -> sort data in required order (time +/-, amplitude +/-)
%
%INPUT                    ArrData          = source data structre - see ReadBellhopArrFile
%
%INLINE O/P               None at this stage - in future filename if interactive option implemented
%
%FILE   O/P               tab delimited  text file (for all you excel users)
%                         row 1      ->  filename
%                         row 2      ->  headers for single entry data:         NArrMat NSD  NRD  NR  SD  RD  RR
%                         row 4      ->  single entry data 
%                         row 5      ->  headers for column data                Delay  Amp  Phase nU  nL  TxAngle  RxAngle
%                         row 6:end  ->  column data
%
%                         
%
%Revision 0.0     23 September 2005 ... Amos L Maggi
TRUE  = 1;
FALSE = 0;

fid = fopen(filename, 'wt');
if fid > 0
   fprintf(fid, StripPath(filename, 'f'));
   fprintf(fid, 'NArrMat\tNSD\tNRD\tNR\tSD\tRD\tRR\n');
   fprintf(fid, '%d\t%d\t%d\t%d\t%f\t%f\t%f\n', ArrData.NArrMat,ArrData.NSD,ArrData.NRD,ArrData.NR,ArrData.SD,ArrData.RD,ArrData.RR);
   fprintf(fid, 'Delay\tAmp\tPhase\tnU\tnL\tTxAngle\tRxAngle\n');
   for ii = 1:ArrData.NArrMat,
      fprintf(fid, '%f\t%f\t%f\t%f\t%f\t%f\t%f\n', ArrData.Delay(ii),abs(ArrData.Amp(ii)),angle(ArrData.Amp(ii)),ArrData.NumTopBnc(ii),ArrData.NumBotBnc(ii),ArrData.SrcAngle(ii),ArrData.RcvrAngle(ii));
   end
end
fclose(fid);
   
