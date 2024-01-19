function [ title, PlotType, freqVec, atten, Pos, pressure ] = read_shd_binY( varargin )

% Read TL surfaces from a binary Bellhop/Kraken .SHD file
% without having to convert to ASCII first.
%
% Useage:
% ... = read_shd_bin( filename, xs, ys )
% where (xs, ys) is the source coordinate in km
% (xs, ys) are optional
%
% Output is a 4-D pressure field p( Ntheta, Nsd, Nrd, Nrr )
%
% Original version by Chris Tiemann, Feb. 2001
% Lots of mods ... mbp
% Laurel added extension to multiple source lat/longs 2011

%error( nargchk( 1, 3, nargin, 'struct' ) );
narginchk( 1, 3 )

filename = varargin{1};

% optional frequency
if nargin == 2
    freq = varargin{ 2 };
end

% optional source (x,y) coordinate
if nargin >= 3
    xs = varargin{ 2 };
    ys = varargin{ 3 };
else
    xs = NaN;
    ys = NaN;
end

%%
fid = fopen( filename, 'rb' );
if ( fid == -1 )
    error( 'read_shd_bin.m: No shade file with that name exists' );
end

recl     = fread( fid,  1, 'int32' );     %record length in bytes will be 4*recl
title    = fread( fid, 80, '*char' )';

fseek( fid, 4 * recl, -1 ); %reposition to end of first record
PlotType = fread( fid, 10, '*char'   );
PlotType = PlotType';

fseek( fid, 2 * 4 * recl, -1 ); %reposition to end of second record
Nfreq  = fread( fid, 1, 'int32'   );
Ntheta = fread( fid, 1, 'int32'   );
Nsx    = fread( fid, 1, 'int32'   );
Nsy    = fread( fid, 1, 'int32'   );
Nsd    = fread( fid, 1, 'int32'   );
Nrd    = fread( fid, 1, 'int32'   );
Nrr    = fread( fid, 1, 'int32'   );
atten  = fread( fid, 1, 'float32' );

fseek( fid, 3 * 4 * recl, -1 ); %reposition to end of record 3
freqVec = fread( fid, Nfreq, 'float64' );

fseek( fid, 4 * 4 * recl, -1 ); %reposition to end of record 4
Pos.theta   = fread( fid, Ntheta, 'float32' );

if ( PlotType( 1 : 2 ) ~= 'TL' )
    fseek( fid, 5 * 4 * recl, -1 ); %reposition to end of record 5
    Pos.s.x     = fread( fid, Nsx, 'float32' );
    
    fseek( fid, 6 * 4 * recl, -1 ); %reposition to end of record 6
    Pos.s.y     = fread( fid, Nsy, 'float32' );
else   % compressed format for TL from FIELD3D
    fseek( fid, 5 * 4 * recl, -1 ); %reposition to end of record 5
    Pos.s.x     = fread( fid, 2,    'float32' );
    Pos.s.x     = linspace( Pos.s.x( 1 ), Pos.s.x( end ), Nsx );
    
    fseek( fid, 6 * 4 * recl, -1 ); %reposition to end of record 6
    Pos.s.y     = fread( fid, 2,    'float32' );
    Pos.s.y     = linspace( Pos.s.y( 1 ), Pos.s.y( end ), Nsy );
end

fseek( fid, 7 * 4 * recl, -1 ); %reposition to end of record 7
Pos.s.depth = fread( fid, Nsd, 'float32' );

fseek( fid, 8 * 4 * recl, -1 ); %reposition to end of record 8
Pos.r.depth = fread( fid, Nrd, 'float32' );

fseek( fid, 9 * 4 * recl, -1 ); %reposition to end of record 9
Pos.r.range = fread( fid, Nrr, 'float32' );
% Pos.r.range = Pos.r.range';   % make it a row vector

%%
% Each record holds data from one source depth/receiver depth pair

switch PlotType
    case 'rectilin  '
        pressure = zeros( Ntheta, Nsd, Nrd, Nrr );
        Nrcvrs_per_range = Nrd;
    case 'irregular '
        pressure = zeros( Ntheta, Nsd,   1, Nrr );
        Nrcvrs_per_range = 1;
    otherwise
        pressure = zeros( Ntheta, Nsd, Nrd, Nrr );
        Nrcvrs_per_range = Nrd;
end

%%
if isnan( xs )    % Just read the first xs, ys, but all theta, sd, and rd
    % get the index of the frequency if one was selected
    ifreq = 1;
    if exist( 'freq', 'var' )
       freqdiff = abs( freqVec - freq );
       [ ~, ifreq ] = min( freqdiff );
    end

    for itheta = 1 : Ntheta
        for isd = 1 : Nsd
            % disp( [ 'Reading data for source at depth ' num2str( isd ) ' of ' num2str( Nsd ) ] )
            for ird = 1 : Nrcvrs_per_range
                recnum = 10 + ( ifreq  - 1 ) * Ntheta * Nsd * Nrcvrs_per_range + ...
                              ( itheta - 1 )          * Nsd * Nrcvrs_per_range + ...
                              ( isd    - 1 )                * Nrcvrs_per_range + ...
                                ird    - 1;

                status = fseek( fid, recnum * 4 * recl, -1 ); %Move to end of previous record
                if ( status == -1 )
                    error( 'Seek to specified record failed in read_shd_bin' )
                end
                
                temp = fread( fid, 2 * Nrr, 'float32' );    %Read complex data
                pressure( itheta, isd, ird, : ) = temp( 1 : 2 : 2 * Nrr ) + 1i * temp( 2 : 2 : 2 * Nrr );
                % Transmission loss matrix indexed by  theta x sd x rd x rr
                
            end
        end
    end
else              % read for a source at the desired x, y, z.
    
    xdiff = abs( Pos.s.x - xs * 1000. );
    [ ~, idxX ] = min( xdiff );
    ydiff = abs( Pos.s.y - ys * 1000. );
    [ ~, idxY ] = min( ydiff );
    
    % show the source x, y that was found to be closest
    % [ Pos.s.x( idxX ) Pos.s.y( idxY ) ]
    for itheta = 1 : Ntheta
        for isd = 1 : Nsd
            % disp( [ 'Reading data for source at depth ' num2str( isd ) ' of ' num2str( Nsd ) ] )
            for ird = 1 : Nrcvrs_per_range
                recnum = 10 + ( idxX   - 1 ) * Nsy * Ntheta * Nsd * Nrcvrs_per_range + ...
                              ( idxY   - 1 )       * Ntheta * Nsd * Nrcvrs_per_range + ...
                              ( itheta - 1 )                * Nsd * Nrcvrs_per_range + ...
                              ( isd    - 1 )                      * Nrcvrs_per_range + ird - 1;
                status = fseek( fid, recnum * 4 * recl, -1 ); % Move to end of previous record
                if ( status == -1 )
                    error( 'Seek to specified record failed in read_shd_bin' )
                end
                
                temp = fread( fid, 2 * Nrr, 'float32' );    %Read complex data
                pressure( itheta, isd, ird, : ) = temp( 1 : 2 : 2 * Nrr ) + 1i * temp( 2 : 2 : 2 * Nrr );
                % Transmission loss matrix indexed by  theta x sd x rd x rr
                
            end
        end
    end
end

fclose( fid );

