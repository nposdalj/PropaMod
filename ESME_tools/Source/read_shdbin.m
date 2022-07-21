function [ title, freq, nsd, nrd, nrr, sd, rd, rr, tlt ] = read_shdbin( filename )

% Reads in TL surfaces from a binary Bellhop/Kraken .SHD file 
% without having to convert to ASCII first.
% Chris Tiemann, Feb. 2001

fid = fopen( filename, 'rb' );
recl = fread( fid, 1, 'int32'); %record length in bytes will be 4*recl
title = setstr( fread( fid, 80, 'uchar' ) )';  

fseek(fid, 4*recl, -1); %reposition to end of first record
plottype = fread(fid, 10, 'uchar');
xs    = fread( fid, 1, 'float32');
ys    = fread( fid, 1, 'float32');
theta = fread( fid, 1, 'float32');

fseek(fid, 2*4*recl, -1); %reposition to end of second record
freq = fread( fid, 1, 'float32'); 
nsd  = fread( fid, 1, 'int32');
nrd  = fread( fid, 1, 'int32');
nrr  = fread( fid, 1, 'int32');

fseek(fid, 3*4*recl, -1); %reposition to end of third record
sd = fread( fid, nsd, 'float32');

fseek(fid, 4*4*recl, -1); %reposition to end of fourth record
rd = fread( fid, nrd, 'float32');

fseek(fid, 5*4*recl, -1); %reposition to end of fifth record
rr = fread( fid, nrr, 'float32');


%Each record holds data from one source depth/receiver depth pair

tlt = zeros( nrd, nrr, nsd );

for i = 1:nsd
  disp(['Reading data for source ' num2str(i) ' of ' num2str(nsd)])
  for j = 1:nrd
    recnum = 6 + (i-1)*nrd + j; 
    fseek(fid, (recnum-1)*4*recl, -1);      %Move to end of previous record
 
    temp = fread(fid, 2*nrr, 'float32');    %Read complex data
    tlt(j, :, i) = temp( 1:2:2*nrr ) + sqrt(-1)*temp(2:2:2*nrr); 
    %Transmission loss matrix indexed by  rd x rr x sd

  end
end

fclose(fid);