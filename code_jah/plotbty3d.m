function varargout = plotbty3d( btyfil )

% Plot the bathymetry file
% usage: plotbty3D( btyfil )
% where btyfil is the BaThYmetry file (the extension is optional)
% e.g. plotbty( 'foofoo' )
%
% plots the BaThymetrY file used by Bellhop
% MBP April 2011

global units

[ x, y, z, ~, ~ ] = readbty3d( btyfil );

% set labels in m or km
xlab = 'Range-x (m)';
ylab = 'Range-y (m)';
x    = x * 1000.0;
y    = y * 1000.0;

if ( strcmp( units, 'km' ) )
   x    = x / 1000.0;
   y    = y / 1000.0;
   xlab = 'Range-x (km)';
   ylab = 'Range-y (km)';
end

[ X, Y ] = meshgrid( x, y );
surf( X, Y, z )
shading faceted
shading interp
colormap( flipud( jet ) )
colorbar

%%

hold on
xlabel( xlab )
ylabel( ylab )
zlabel( 'Depth (m)' )

%earthbrown = [ 0.5 0.3 0.1 ];
% h          = fill( r, z, earthbrown );

set( gca, 'ZDir', 'Reverse' )   % plot with depth-axis positive down

if ( nargout == 1 )
   varargout( 1 ) = { h };   % return a handle to the figure
end


