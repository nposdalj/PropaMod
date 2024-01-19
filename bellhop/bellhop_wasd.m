function bellhop_wasd( filename, version )

% run the BELLHOP program
%
% usage: bellhop( filename )
% where filename is the environmental file

% WASD 2024/01/19 - Derived bellhop_wasd.m from bellhop.m (Path was
% H:\NP_propagationmodeling_backup\AcousticsToolbox\Matlab\bellhop.m.)
% Modified to toggle version of BELLHOP to run.

% Locate chosen version of BELLHOP
% runbellhop = which( 'bellhop.exe' );
switch version
    case 'jah'
        runbellhop = which('bellhop_jah.exe');
    case 'cxx'
        runbellhop = which('bellhopcxx.exe');
end

if ( isempty( runbellhop ) )
   error( 'bellhop.exe not found in your Matlab path' )
else
   eval( [ '! "' runbellhop '" ' filename ] );
end