function Dir = GetAcDirectoryInfo()
%This file contains the locations of the directories that this program uses.
%Modify it to suit your system configuration


Top           = 'C:\Program Files\CMST Software\AcTUP v2.2L\'               ;   % uppermost directory installation
AcToolBox     = [Top 'AT\']            ;   % Root directory for acoustic toolbox - change this to suit your system (trailing \ required)

% AcT 
Dir.Kraken    = [AcToolBox 'bin\']      ;   % Location of kraken.exe, krakenc.exe etc.
Dir.Scooter   = [AcToolBox 'bin\']      ;   % location of scooter.exe etc.
Dir.Bellhop   = [AcToolBox 'bin\']      ;   % location of bellhop.exe etc.
Dir.Ram       = [Top 'RAM\']            ;   % location of ram.exe (or equivilant)
Dir.Global    = [AcToolBox 'bin\']      ;   % location of other acoustic toolbox executables
 
% AcTUP (MATLAB) Source
Dir.AcTUP     = [Top, 'AcTUP\']         ;

% Working Directories
Dir.MainWork  = [Dir.AcTUP, 'Output\'] ;       % Working directory - program will write to and read from this area
Dir.RunDef    = [Dir.AcTUP, 'RunDef\'] ;       % Program will store run definitions in this directory
Dir.Bath      = [Dir.AcTUP, 'Bathymetry\'] ;   % Optional storage location for bathymetry files - more for testing rather than regular use

% Previously used directories - these must be absolute since they will contain paths selected by user
Dir.LastBatch   = [Dir.RunDef];
Dir.LastRunDef  = [Dir.RunDef] ;



































% ===================================================================
% Revision History
% ================
% Revision 0.0 to 1.?         2002-2006 ... AJD/ALM
% Revision 2.0         17 July     2006 ... ALM
%                      - Source code root not user defined