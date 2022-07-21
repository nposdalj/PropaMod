function [ amp, delay, SrcAngle, RcvrAngle, NumTopBnc, NumBotBnc, narrmat, nsd, nrd, nr, sd, rd, rr ] ...
    = ReadArrivalsAsc( ARRFIL, narrmx );

% read_arrivals_asc
% useage:
%[ amp, delay, narrmat, nsd, nrd, nr, sd, rd, rr ] ...
%    = read_arrivals_asc( ARRFIL, narrmx );
%
% Loads the arrival time/amplitude data computed by BELLHOP
% You must set the string ARRFIL specifying the Arrivals File
% narrmx specifies the maximum number of arrivals allowed
% mbp 9/96
%
%Modded by A Duncan
%
% Revision 0.1      08 December 2003 ... ALM
%                   - function dec to resemble filename (was read_arrivals_asc - how did it work?) 
%
% Revision 0.2      05 June     2006 ... ALM
%                   MODS FOR AT RELEASE 2006
%                   - add line to read maximum number of arrivals from "WRITE( ARRFIL, * ) MAXVAL( NArr( 1:Nrd, 1:Nr ) )"
%

FALSE   = 0;
TRUE    = 1;

ExpectBounceCounts = 1;  %1 if version of bellhop produces counts of interface bounces for each path, 0 otherwise
if ExpectBounceCounts
    NField = 7;
else
    NField = 4;
end

fid = fopen( ARRFIL, 'r');	% open the file

% read the header info

freq    = fscanf( fid, '%f',  1  );
nsd     = fscanf( fid, '%i',  1  );
nrd     = fscanf( fid, '%i',  1  );
nr      = fscanf( fid, '%i',  1  );
sd      = fscanf( fid, '%f', nsd );
rd      = fscanf( fid, '%f', nrd );
rr      = fscanf( fid, '%f', nr  );

% loop to read all the arrival info (delay and amplitude)

amp   = zeros( nr, 100, nrd, nsd );
delay = zeros( nr, 100, nrd, nsd );
narrmat = zeros(nr, nrd, nsd);

% MOD FOR AT RELEASE 2006 ------------------------------------------------------------------
% READ narrmax ... maybe 
pre2006  = FALSE;
startpos = ftell(fid);
narrmax  = fscanf( fid, '%i', 1   );
% is this > 0 
if narrmax == 0
   % keep reading - as soon as we've hit a non-zero value its pre-2006 ... (i.e. narrmax cannot be zero if there is data !)
   done = FALSE;
   while ~done
      [n, count] = fscanf( fid, '%i', 1   );
      if count > 0,
         if n > 0     % DATA FOUND - PRE-2006 
            % non-zero number of arrivals    - pre2006 file
            done    = TRUE;
            pre2006 = TRUE;
         end
      %else count == 0 % EOF - NO DATA FOUND  - 2006 version
         %count ==0 if invalid format or EOF - BUT invalid format is avoided by finding n > 0 on preceeding line !        
      end
   end         
else % narrmax > 0
   % read next line - is it a vector of arrival data or is it another integer?
   %     .arr files appear to use a leading whitespace for all data entries - this is not a blank digit field
   %        single entry will have 1 whitespace
   %        arrival data vector will have 7 whitespaces
   lstr        = fgetl(fid);
   nwspace     = sum(isstrprop(lstr, 'wspace'));
   %rewind file to position appropriate to version number
   if nwspace > 1
      % this is a pre-2006 Bellhop file !!
      pre2006 = TRUE;
   %else
       % this is a 2006 release Bellhop file
   end
end  
%return to start for data loop
fseek(fid, startpos, 'bof');

% MOD FOR AT RELEASE 2006 - END --------------------------------------------------------------

for isd = 1:nsd
   if ~pre2006
      narrmax(isd) = fscanf( fid, '%i', 1   );
   end      
   for ird = 1:nrd
      for ir = 1:nr
         narr = fscanf( fid, '%i', 1 );	% number of arrivals
         narrmat( ir, ird, isd ) = narr;
         if narr > 0   % do we have any arrivals?
            da = fscanf( fid, '%f', [ NField, narr ] );

            amp(   ir, 1:narr, ird, isd ) = da( 1, : ) .* exp( i * da( 2, : )*pi/180);
            delay( ir, 1:narr, ird, isd ) = da( 3, : );
            SrcAngle(  ir, 1:narr, ird, isd ) = da( 4, : );
            if ExpectBounceCounts
               RcvrAngle( ir, 1:narr, ird, isd ) = da( 5, : );
               NumTopBnc( ir, 1:narr, ird, isd ) = da( 6, : );
               NumBotBnc( ir, 1:narr, ird, isd ) = da( 7, : );
            else
               RcvrAngle = [];
               NumTopBnc = [];
               NumBotBnc = [];
            end
         end
      end		% next receiver range
   end		% next receiver depth
end	% next source depth
fclose( fid );

%amp   = amp(   :, 1:narrmx, :, : );
%delay = delay( :, 1:narrmx, :, : );
