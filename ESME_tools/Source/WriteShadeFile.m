function WriteShadeFile(title, freq, sd, rd, rr, p, filename, plottype, xs, ys, theta)
% WriteShadeFile ... writes complex pressure field to shade filename  (.shd)
%                    
% Usage:      WriteShadeFile(title, freq, sd, rd, rr, p [, filename][, plottype])
%
% The .shd filename format is used by Bellhop and Kraken ... this function was
% originally motivated by a need to fit RAM into the AcT UI. RAMGeo has been
% modifed by CMST to generate complex pressure output but in formats that
% parallel the tl.line and .grid formats. 
%
% Ref: ReadShadeBin  by AJD (see this function for further refs) 
%
% INPUT
% ------------------------------------------------------------------------
% title     title of run (string)
% freq      frequency (Hz)
% sd        vector of source depths
% rd        vector of receiver depths
% rr        vector of receiver ranges
% p         complex pressure for unity source strength (nrd x nrr x nsd)
% filename  full path + name of target filename (string) 
%        or filename access code (uint)
%        or = 'int' for interactive filename selection (DEFAULT)         
%           (need to specify 'int' to use interactive option IF also
%           specifying plottype)
% plottype  don't know what this is but its a char*10 
%          = '          ' (DEFAULT)
% xs       ? (default = 0.0);
% ys       ? (default = 0.0);
% theta    ? (default = 0.0);
%
% note Nsd, Nrd and Nr are not passed and are handled using LENGTH function
%
% Centre for Marine Science and Technology
% Physics Dept
% Curtin University
%
% Revision 0         16 June     2003 ... ALM
%
% Revision 0.1       07 October  2004 ... ALM
%                 -  complex pressure modified to match Scooter/Kracken Phase convention 
%                    (reflect z through origin or phase+pi)
%                 -  note that the Scooter/Phase convention isn't ideal since it needs to 
%                    reflipped in creating sensible transfer functions but this makes it consistent (not implemented yet)
%
% Revision 0.2       02 February 2005 ... ALM
%                 -  modify header format to cope with Rx depth (rd) vector being longer than 2x Rx range (rr) vector
%                    and hence longer than the std record length (=2*nrr)
%                    TWO OPTIONS
%                    1) invert matrix so rr and rd are flipped and set flag
%                    2) wrap rd over mulitple records ... 
%                       OPTION 2 is implimented preferred since this can be applied to Tx depths also (sd) 
%                       and eliminates the need for additional variable and is therefore backwards-compatible

%initialise 
nsd           = length(sd);
nrd           = length(rd);
nr            = length(rr);
bytes_uchar   = 1;
bytes_int32   = 4;
bytes_float32 = 4;

TRUE          = 1;
FALSE         = 0;


if exist('filename')
   if strcmpi(filename, 'int') % note this doesn't crash if filename is infact a FID
      imode = TRUE;
   else
      imode = FALSE;
   end
else
   imode = TRUE;
end

      
if ~imode
   if ischar(filename) 
      % open filename
      fid = fopen( filename, 'wb' );
      if fid < 0
         uiwait(warndlg(['Couldn''t create filename: ' filename]));
         return;
      end
   else
      % file is already open
      fid = filename;
   end
else
   % interactive filename selection ...
   [filename, path] = uiputfile('*.shd', 'Save Complex Pressure As ');
   if filename == 0
      %exit on cancel
      return;
   else
      %build full name
      filename = [path, filename];
      %try filename open again
      fid = fopen(filename, 'wb');
      if fid < 0
         uiwait(warndlg(['Couldn''t create filename: ' filename]));
         filenameStatus = 0;
         return;
      end
   end
end

% check optionals
if ~exist('plottype');  plottype = '          '; end
if ~exist('xs')      ;  xs       = 0           ; end
if ~exist('ys')      ;  ys       = 0           ; end
if ~exist('theta')   ;  theta    = 0           ; end


% determine record length from number of columns (ranges slices) in p
% tensor ... each complex entry is a 2 x 32bit number (4+4 bytes)

size_cmplx = 8;                   % 2 x 4 bytes (or 2 x 'float32') 
recl  = size(p,2) * size_cmplx;   % record length in bytes
reclf = size(p,2) * 2         ;   % record length in 'float32's 
                                  % ie # fp numbers to make up record  
                                  % (Read fn x this by 4 to get # bytes)

% check title
if length(title) + bytes_int32 > recl   % wont fit in record
   title(recl-bytes_int32+1:end) = [];
end
if length(title) > 80                   % exceeds recommended limit
   title(81:end) = [];
elseif length(title) == 0               % is zero length
   title = ' '; % just in case ...
end

try
   % write header in records ... use
   %                                  FWRITE(FID,A,PRECISION,SKIP) 
   % to push the first entry of each record to correct location
   
   % record # 1  --------------------------------------------------
   fwrite(fid, reclf, 'int32');
   fwrite(fid, title, 'char');
   skipbytes = recl - bytes_int32 - length(title)*bytes_uchar;
   fwrite(fid, -ones([1,skipbytes]), 'char');
   % record # 2  --------------------------------------------------
   fwrite(fid, plottype, 'char');
   fwrite(fid, [xs, ys, theta], 'float32');
   skipbytes = recl - length(plottype)*bytes_uchar - 3*bytes_float32;
   fwrite(fid, -ones([1,skipbytes]), 'char');
   % record # 3  --------------------------------------------------
   fwrite(fid, freq, 'float32'); 
   fwrite(fid, [nsd, nrd, nr], 'int32');
   skipbytes = recl - 1*bytes_float32 - 3*bytes_int32;
   fwrite(fid, -ones([1,skipbytes]), 'char');
   % records # 4 to 4+n-1 ------------------------------------------
   % it is possible (but unlikely) that nsd > reclf - need to allow for wrapping into next record
   done   = FALSE;
   idx    = 1:nsd;
   while ~done
       % select elements of sd to write
       iend        = min(reclf,length(idx));
       widx        = idx(1:iend);
       % write record
       count       = fwrite(fid, sd(widx), 'float32');
       % remove reference to written elements from index vector       
       idx(1:iend) = [];       
       % what to do next ? 
       skipelements = reclf - count;
       if      skipelements > 0           % short of full record ?
           done     = TRUE;
           % fill in record and we're done
           skipbytes = skipelements * bytes_float32;
           fwrite(fid, -ones([1,skipbytes]), 'char');           
       elseif  length(idx)  > 0           % full record so maybe more elements to write ?
           % keep going
       elseif  length(idx) == 0           % full record AND NO MORE TO WRITE ?! only non error option left
           done = TRUE;
       end
   end
   % records # 4+n to 4+n+m-1 ------------------------------------
   % it is possible (but unlikely although it happenned to me) that nrd > reclf - need to allow for wrapping into next record
   done   = FALSE;
   idx    = 1:nrd;
   while ~done
       % select elements of sd to write
       iend        = min(reclf,length(idx));
       widx        = idx(1:iend);
       % write record
       count       = fwrite(fid, rd(widx), 'float32');
       % remove reference to written elements from index vector       
       idx(1:iend) = [];       
       % what to do next ? 
       skipelements = reclf - count;
       if      skipelements > 0           % short of full record ?
           done      = TRUE;
           % fill in record and we're done
           skipbytes = skipelements * bytes_float32;
           fwrite(fid, -ones([1,skipbytes]), 'char');
       elseif  length(idx)  > 0           % full record so maybe more elements to write ?
           % keep going
       elseif  length(idx) == 0           % full record AND NO MORE TO WRITE ?! only non error option left
           done = TRUE;
       end
   end
   % record  # 4+n+m ----------------------------------------------
   % by definition, rr always uses exactly half the record length
   fwrite(fid, rr, 'float32');
   skipbytes = recl - nr  * bytes_float32;
   fwrite(fid, -ones([1,skipbytes]), 'char');
   
   % END HEADER ------------------------------------------------------------------------------------------------------------------
   
   
   % write complex pressure
   for idepth = 1:nrd
      pflat(1:2:(2*nr-1)) = real(p(idepth,:));
      pflat(2:2:(2*nr)  ) = imag(p(idepth,:));
      fwrite(fid, pflat, 'float32');
      skipbytes = recl - 2 * nr * bytes_float32;
      if skipbytes > 0
         fwrite(fid, -ones([1,skipbytes]), 'char');
      end
   end
   
catch   
   title = '';
   freq = [];
   nsd = [];
   nrd = [];
   nrr = [];
   sd = [];
   rd = [];
   rr = [];
   tlt = [];
end

if fid > 0 
   fclose(fid);
end