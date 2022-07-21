function [title, freq, nsd, nrd, nrr, sd, rd, rr, fid, startposn, reclf, recl, nextrec] = ReadShadeHeadBin( file, mode, TLmethod)
% ReadShadeHeadBin       Reads only header information from binary Shade File (not TL)
%
%USAGE:  [title, freq, nsd, nrd, nrr, sd, rd, rr, fid, startpoz, reclf, recl, nextrec] = ReadShadeHeadBin( file );
%
%INPUT        file     = target filename OR FID 
%             mode     = 'close' to return with file closed           DEFAULT IF file = filename
%                      = 'open'  to return with file open (see fid)   DEFAULT IF file = fid
%          
%
%OUTPUT       fid      = file ID ([] if closed)
%             startpoz = start position
%             reclf    = record length in float32s
%             recl     = record length in bytes
%             nextrec  = pointer to 1st record in data section of file (1st record after header)
%
%see ReadShadeBin.m for more detail (this code was just lifted from first section of entire read file)
%
%Revision 0.0     10 12 2004 - ALM
%                 - just grab from ReadShadeBin.m
%
%Revision 0.1     02 02 2005 - ALM
%                 - modified to read wrapped header information (see WriteShadeFile.m v0.2)
%
%Revision 0.2     20 04 2005 - ALM
%                 - modified to pass error msg instead of launch dialog (automatically)

%tic;
FileStatus = 1;

if ~exist('mode', 'var')
    mode = [];
end

if ischar(file)
    fid = fopen( file, 'rb' );
    if fid < 0
        uiwait(warndlg(['Couldn''t open input file: ' file]));

        FileStatus = 0;
        title = '';
        freq = [];
        nsd = [];
        nrd = [];
        nrr = [];
        sd = [];
        rd = [];
        rr = [];
        tlt = [];
        return;
    end            
    if isempty(mode), mode = 'CLOSE'; end;
else
    fid                    = file;
    if isempty(mode), mode = 'OPEN' ; end;
end

try
    startposn = ftell(fid); 
    % to be consistent with WriteShadeFile define recl and reclf as
    % record length (as number of float32s)
    reclf = fread( fid, 1, 'int32'); %record length in bytes will be 4*recl
    % record length in bytes
    recl  = 4*reclf;
    
    %
    title = setstr( fread( fid, 80, 'uchar' ) )';  

    fseek(fid, recl+startposn, -1); %reposition to end of first record
    plottype = fread(fid, 10, 'uchar');
    xs    = fread( fid, 1, 'float32');
    ys    = fread( fid, 1, 'float32');
    theta = fread( fid, 1, 'float32');

    fseek(fid, 2*recl+startposn, -1); %reposition to end of second record
    freq = fread( fid, 1, 'float32'); 
    nsd  = fread( fid, 1, 'int32');     
    if strcmpi(TLmethod, 'Bellhop')
        fread( fid, 1, 'int32');  % extra for bellhop
    end
    nrd  = fread( fid, 1, 'int32');
    nrr  = fread( fid, 1, 'int32');
    
    if (nrr<= 0) | (nsd <= 0) | (nrd <= 0) | (freq <= 0)
       FileStatus = 0;
       Msg = {'Invalid shade file parameters:', ...
          ['Frequency = ' num2str(freq)], ...
          ['Number of source depths = ' int2str(nsd)], ...
          ['Number of receiver depths = ' int2str(nrd)], ...
          ['Number of receiver ranges = ' int2str(nrr)]};

       % only launch warning if file = filename otherwise might already be open file past header
       %if isnumeric(file)
       %   uiwait(warndlg(Msg));
       %end
       tlt = Msg;
       sd = [];
       rd = [];
       rr = [];
       
    else
       % read source depths sd
       if strcmpi(TLmethod, 'Bellhop')
           nextrec = 4;% 
       else
           nextrec = 3; 
       end
       fseek(fid, nextrec*recl+startposn, -1)  ; %reposition to end of third record
       sd      = fread( fid, nsd, 'float32')   ;
       % read receiver depths rd
       nextrec =  nextrec + ceil(nsd/reclf)      ;
       fseek(fid, nextrec*recl+startposn, -1)  ; %reposition to end of fourth record
       rd      = fread( fid, nrd, 'float32')   ;       
       % read receiver ranges rr
       nextrec =  nextrec + ceil(nrd/reclf)      ;
       fseek(fid, nextrec*recl+startposn, -1)  ; %reposition to end of fifth record
       rr = fread( fid, nrr, 'float32')        ;
       % NO WRAPPING POSSIBLE since reclf = 2*nrr - always half the record capacity to spare
       nextrec =  nextrec+1                    ;
       dataptr =  nextrec * recl + startposn   ;
    end

catch
   FileStatus = 0;
   title = '';
   freq = [];
   nsd = [];
   nrd = [];
   nrr = [];
   sd = [];
   rd = [];
   rr = [];
end

if ischar(file) & strcmpi(mode, 'CLOSE')
   fclose(fid);
   fid   = [] ;
end
%toc