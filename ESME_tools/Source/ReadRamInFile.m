function RamInput = ReadRamInFile(Species, FName)
%ReadRamInFile()
%
% Reads RAM initialisation files and transfers data to structure. 
% Structure members use same naming convention used by Mike Collins in 
% "User Guide for RAM Versions 1.0 and 1.0p" 
% ftp://ram.nrl.nav.mil/pub/RAM/
%
% USAGE: RamInput = ReadRamInFile(Species [, FName])
%
% OP:   RamInput   -> Structure with members:
%                     title      string   
%                     freq       [Hz]
%                     zs         source depth [m]
%                     zr         receiver depth [m]
%                     rmax       maximum range [m]
%                     dr         range calc increment [m]
%                     ndr        range decimation factor (>1)
%                     zmax       maximum depth [m]
%                     dz         depth calc increment [m]
%                     ndz        depth decimation factor (>1)
%                     zmplt      maximum depth for o/p grids
%                     c0         reference phase velocity [m/s]
%                     np         number of terms in rat expansion
%                     ns         # of stability constraints
%                     rs         range of stability constraint [m]
%                     r_zsurf    free surface profile (N x 2)
%                     r_zb       bathymetry profile (N x 2)
%                     RangeSlices
%  where
%      RangeSlices -> is an array of RangeSlice objects
%
%      RangeSlice  ->
%                     rp         range for profile set (slice) [m] 
%                     z_cw       sound speed profile (N x 2)
%                     z_cbp      bottom compressive sound speed profile (N x 2)
%                     z_cbs      bottom shear sound speed profile (N x 2)
%                     z_rhob     bottom density profile (N x 2)
%                     z_attenp   bottom compressive attenuation profile (N x 2)
%                     z_attens   bottom shear attenuation profile (N x 2) 
%
%       Note that in the above lists N is in general different for each
%       instance (not just for each slice)
%
% IP:   Species    -> 'RAM'
%                     'RAMS'
%                     'RAMGeo'
%                     'RAMSurf'
%                     'RAMSGeo'
%
%       FName      -> ram* input filename (including path)
%                     OPTIONAL 
%                     DEFAULT -> File Open Dialog launched 
%                        
%
%
% Version History
% ---------------
% Revision 0.0        20 June 2003 ... ALM
%                     Attempt to include version / compiler flexibility 
%                     The user can specify a code which identifies the
%                     compiled version of the code ...
%
% Revision 0.1        18 November 2004 ... ALM
%                     Add the CMST 'RAMSGeo'

% ©
% CMST 
% Physics Department
% Curtin University
% Perth, WA


% some constants
true     = 1;
false    = 0;
fnstr    = 'ReadRamInFile';
RamInput = [];

% DEAL WITH IP PARAMETERS
% has a version number been specified
if  ~exist('Species', 'var')
   msgbox({'Species or CMST build number for RAM not specified', 
      'Function Aborted'}, ...
      fnstr, 'warn');
   return;     
end  

% do we have too many arguments?
if nargin > 2
   msgbox({'Number of input argument exceeds function definition:', ...
         'surplus arguments ignored'}, ...
      fnstr, 'warn');
end

% do we need to ask for the filename
if exist('FName', 'var')
   % is the filename anygood ?
   if ~exist(FName, 'file');
      % failed
      FName = [];      
   end   
else 
   FName = [];
end
if isempty(FName) 
   [FName, Path] = uigetfile('*.in', 'Select RAM* initialisation file');
   if FName == 0 % cancelled 
      return;
   else % Got InFName
      FName = [Path FName];
   end
end         

% GET RUN PARAMETERS FROM ram.in FILE or equivalent
% try file open 
infile = fopen(FName, 'rt');
% if file open errors (shouldnt be any at this stage)
if infile < 0 % still!
   msgbox({'Initialisation file not found: ', infilename, 'Function Aborted'}, ...
      fnstr, 'warn');
   return;
end

% read run pararmeters
try
   % record # 1
   RamInput.title = fgetl(infile);
   % record # 2
   strbuffer = fgetl(infile);
   databuffer = sscanf(strbuffer, '%f %f %f');
   RamInput.freq = databuffer(1); 
   RamInput.zs = databuffer(2); 
   RamInput.zr = databuffer(3); 
   % record # 3
   strbuffer = fgetl(infile);
   databuffer = sscanf(strbuffer, '%f %f %d');
   RamInput.rmax = databuffer(1);
   RamInput.dr = databuffer(2);
   RamInput.ndr = databuffer(3);
   % record # 4
   strbuffer = fgetl(infile);
   databuffer = sscanf(strbuffer, '%f %f %d %f');
   RamInput.zmax = databuffer(1);
   RamInput.dz = databuffer(2);
   RamInput.ndz = databuffer(3);
   RamInput.zmplt = databuffer(4);
   % record # 5
   strbuffer = fgetl(infile);
   databuffer = sscanf(strbuffer, '%f %d %d %f');
   RamInput.c0 = databuffer(1);
   RamInput.np = databuffer(2);
   switch Species
      case {'RAMS', 'RAMSGeo'}
         RamInput.irot  = databuffer(3);
         RamInput.theta = databuffer(4);
         RamInput.ns    = [];
         RamInput.rs    = [];        
      otherwise
         RamInput.irot  = [];
         RamInput.theta = [];
         RamInput.ns    = databuffer(3);
         RamInput.rs    = databuffer(4);
   end
   % surface profile
   switch Species
      case 'RAMSurf'
         RamInput.r_zsurf = lReadProfile(infile);
      otherwise
         RamInput.r_zsurf = [];
   end
   % bathymetry
   RamInput.r_zb = lReadProfile(infile);
   
   % RANGE SLICES 
   RangeSlices = [];
   done = false;
   jj   = 1;
   while ~done
      % first slice range
      if jj ==1; RangeSlices(jj).rp = 0; end
      % compressive phase speed profile of water
      RangeSlices(jj).z_cw     = lReadProfile(infile);
      % compressive phase speed profile of (fluid) substrate
      RangeSlices(jj).z_cbp    = lReadProfile(infile);
      % shear phase speed profile of (fluid) substrate
      switch Species
         case {'RAMS', 'RAMSGeo'}
            RangeSlices(jj).z_cbs    = lReadProfile(infile);
         otherwise
            RangeSlices(jj).z_cbs    = [];
      end
      % density profile of (fluid) substrate
      RangeSlices(jj).z_rhob   = lReadProfile(infile);
      % compressive attenuation coefficient profile of (fluid) substrate
      RangeSlices(jj).z_attenp = lReadProfile(infile);
      % shear attenuation coefficient profile of (fluid) substrate
      switch Species
         case {'RAMS', 'RAMSGeo'}      
            RangeSlices(jj).z_attens = lReadProfile(infile);
         otherwise
            RangeSlices(jj).z_attens = [];
      end      
      % next slice range 
      strbuffer = fgetl(infile);
      if strbuffer ~= -1 
         % not eof flag
         [databuffer, count] = sscanf(strbuffer, '%f');
         if count == 0 
            %blank line - probably before eof ... in any case close out
            done = true;
         else
            jj = jj + 1;
            RangeSlices(jj).rp = databuffer(1);
         end
      else
         % EOF
         done = true;
      end      
   end % while range slice loop
   RamInput.RangeSlices = RangeSlices;
   
catch
   msgbox({['Error reading ', FName,], ...
         'It is possible that not all data has been retrieved or is available'}, ...
         fnstr, 'warn');
end
fclose(infile);

% PRIVATE FUNCTIONS ------------------------------------------------------

function prof = lReadProfile(fid)
% reads RAM profile from ram*.in formatted file

%initialise
true  = 1;
false = 0;
prof = [];
eop = false;
ii = 0;

% go - stop when the profile elements are {-1 -1} 
%      need only test first - all z > 0 !!

while ~eop
   strbuffer = fgetl(fid);
   databuffer = sscanf(strbuffer, '%f %f');
   if databuffer(1) < 0
      eop = true;
   else
      ii         = ii + 1;
      prof(ii,1) = databuffer(1);
      prof(ii,2) = databuffer(2);
   end
end
   
   
   
   