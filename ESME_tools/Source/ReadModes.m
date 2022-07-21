function [ pltitl, freq, ck, z, phi, cpt, cst, rhot, deptht, cpb, csb, rhob, depthb, Nmedia, depth, rho ] = ReadModes( filename, modes );

% read_modes_bin
% useage:
%    [ pltitl, freq, ck, z, phi ] = read_modes_bin( filename, modes )
% read the modes produced by KRAKEN
% filename is without the extension, which is assumed to be '.moA'
% modes is an optional vector of mode indices

%Original:
% derived from readKRAKEN.m    Feb 12, 1996 Aaron Thode
%
%Modified by Alec Duncan

fid = fopen( filename, 'r' );
lrecl = fread( fid, 1, 'long' );

%Try changing this line for the sun, if doesn't work
lrecl = 4 * lrecl;

rec = 0;  %Record length is one less than in the krakm.f file
fseek( fid, rec * lrecl, -1 );
fseek( fid, 4, 0 );
pltitl = setstr( fread( fid, 80, 'uchar' ) )';
freq   = fread( fid, 1, 'float' );
Nmedia = fread( fid, 1, 'long' );
Ntot   = fread( fid, 1, 'long' );

if Ntot < 0, return; end

rec = 1;
fseek( fid, rec * lrecl, -1 );
N = fread( fid, Nmedia, 'long' );
Mater = setstr( fread( fid, [ 8, Nmedia ], 'uchar' ) );

rec = 2;
fseek( fid, rec * lrecl, -1 );
bctop  = setstr( fread( fid, 1, 'char' ) );
cpt    = fread( fid, [ 2, 1 ], 'float' );
cst    = fread( fid, [ 2, 1 ], 'float' );
rhot   = fread( fid, 1, 'float' );
deptht = fread( fid, 1, 'float' );

bcbot  = setstr( fread( fid, 1, 'char' )' );
cpb    = fread( fid, [ 2, 1], 'float' );
csb    = fread( fid, [ 2, 1], 'float' );
rhob   = fread( fid, 1, 'float' );
depthb = fread( fid, 1, 'float' );

rec = 3;
fseek( fid, rec * lrecl, -1 );
bulk  = fread( fid, [ 2, Nmedia ], 'float' );
depth = bulk( 1, : );
rho   = bulk( 2, : );

rec = 4;
fseek( fid, rec * lrecl, -1 );
m = fread( fid, 1, 'long' );
Lrecl = fread( fid, 1, 'long' );

rec = 5;
fseek( fid, rec * lrecl, -1 );
z = fread( fid, Ntot, 'float' );

% read in the modes

if nargin == 1
    modes = 1:m;    % read all modes if the user didn't specify
end

% don't try to read modes that don't exist
ii = find( modes <= m );
modes = modes( ii );
   
phi = zeros( Ntot, length( modes ) );   %number of modes
for ii = 1: length( modes )
    rec = 5 + modes( ii );
    fseek( fid, rec * lrecl, -1 );
    phitmp = fread( fid, [ 2, Ntot ], 'float' )'; %Data is read columwise first
    phi( :, ii ) = phitmp( :, 1 ) + i * phitmp( :, 2 );
end

% read in the wavenumbers

Ifirst = 1;
cktot = [];

%for I = 1 : ( 1 + ( 2 * m - 1 ) / Lrecl ),
%    rec = 5 + m + I;
%    fseek( fid, rec * lrecl, -1 );
%    Ilast = min( [ m Ifirst + Lrecl / 2 - 1 ] );
%    ck = fread( fid, [ 2, Ilast - Ifirst + 1 ], 'float' )';
%    cktot = [ cktot; ck ];
%    Ifirst = Ilast + 1;
%end
%ck = cktot( modes, 1 ) + i * cktot( modes, 2 );

rec = 6 + m;
fseek( fid, rec * lrecl, -1 );
ck = fread( fid, [ 2, m ], 'float' );
ck = ck( 1, : ) + i .* ck( 2, : );
ck=ck(:);    % return a column vector

fclose( fid );


