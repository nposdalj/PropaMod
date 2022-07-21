function [ title, freq, nsd, nrd, nrr, sd, rd, rr, tlt, FileStatus, EOF ] = ReadShadeBin(filename, TLmethod)
% READSHADEBIN
% Reads in TL surfaces from a binary Bellhop/Kraken .SHD file 
% without having to convert to ASCII first.
% Chris Tiemann, Feb. 2001
% Modified by Alec Duncan, June 2002 to add error checking
%
%filename is either the full file name for the shade file, including path and extension (string), or a
%file identifier (integer).  In the former case the file is opened, read and then closed.  In the latter case the file is 
%only read.
%
%title - title of run (string)
%freq - frequency (Hz)
%nsd - number of source depths
%nrd - number of receiver depths
%nrr - number of receiver ranges
%sd - vector of source depths
%rd - vector of receiver depths
%rr - vector of receiver ranges
%tlt -  complex pressure for a unity source strength (nrd x nrr x nsd)
%FileStatus - 1 if the data were read successfully, 0 otherwise 
%EOF        = boolean flag for EOF 
%
%
%Revision 2.0    03 February 2005 - ALM
%                - replace lines for reading header with more flexible subroutine
%                - see ReadShadeHeadBin
%                  * more robust against environments with aspect ratios
%                  * useful for fast, direct access to header 
%
%Revision 2.01   11 May      2006 - ALM
%                - add deblanking for title
%
%Revision 2.02   26 June     2006 - ALM
%                >> Compatibility issues with AT 2006
%                   For some reason the new shd files appear to have junk in the bytes between end of data and end of record
%                   This shows up as error in ReadShadeHEaderBin
%                   After reading data from last record of last f set, this attempts to go to next record only to find its past EOF
%                   thereby leaving the file pointer in the middle of the last record.
%                   THe file stays open and a subsequent call to ReadShadeHeaderBin to look for next f-set reads in junk bytes and 
%                   causes all sorts of problems - as a result of reading junk into "recl" 
%                   Interestingly, using previously generated shade files, reading "recl" from non-data bytes yielded 0 ! and so no 
%                   reading past EOF simply [] returns which triggered sensible responses
%                   FIX
%                   - Modify so fseek calls are checked for return values and manage file closure
%                   - Add EOF flag ... was going to add topion(s) to FileStatus but it use (as boolean) by existing code may be compromised

TRUE       = 1;
FALSE      = 0;

%tic;

FileStatus = TRUE;
EOF        = FALSE;


try
    % read header
    [title, freq, nsd, nrd, nrr, sd, rd, rr, fid, startposn,...
        reclf, recl, nextrec] = ReadShadeHeadBin( filename, 'OPEN', TLmethod);
    % remove trailing spaces
    title = deblank(title);

    % recl = is record length in bytes !
    % reclf = record length in float32s
    
    % Each record holds data from one source depth/receiver depth pair

    tlt = zeros( nrd, nrr, nsd );

    for ii = 1:nsd
        %disp(['Reading data for source ' num2str(i) ' of ' num2str(nsd)])
        for jj = 1:nrd
            recnum = nextrec + (ii-1)*nrd + jj-1;
            fseek(fid, recnum*recl+startposn, -1);      %Move to start of record

            temp = fread(fid, 2*nrr, 'float32');    %Read complex data
            tlt(jj, :, ii) = temp( 1:2:2*nrr ) + sqrt(-1)*temp(2:2:2*nrr);
            %Transmission loss matrix indexed by  rd x rr x sd

        end
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
    tlt = [];
end

if FileStatus
    fstatus = fseek(fid, (recnum+1)*4*recl+startposn, -1);  %Move to start of next data set
    if fstatus < 0, 
       EOF = TRUE; 
       %move to end of record instead
       fseek(fid,0,+1);
    end
end
        
if ischar(filename)
    fclose(fid);
end
%toc;