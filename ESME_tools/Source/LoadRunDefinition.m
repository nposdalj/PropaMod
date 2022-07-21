function [RunDef, FileOK] = LoadRunDefinition(DirInfo, filename)
%LoadRunDefinition    loads saved or default run definition depending on IP parameters
%
%
%USAGE            USE DEFAULT (HARDCODED) RunDefinition (including environment)
%                 RunDef           =  LoadRunDefinition(DirInfo)            ->  uses hardcoded (default) parameters
%                 RunDef           =  LoadRunDefinition()                   ->  same as above but DirInfo is 
%                                                                               obtained using AcDirectoryInfo.m
%                 USE DEFAULT (File) RunDefinition (including environment)
%                 RunDef           =  LoadRunDefinition(DirInfo, -1)        ->  uses File-sourced default parameters
%                 RunDef           =  LoadRunDefinition([], -1)             ->  same as above but DirInfo is 
%                                                                               obtained using AcDirectoryInfo.m
%                 USE SAVED RunDefnition
%                 [RunDef, FileOK] =  LoadRunDefinition(DirInfo, filename)  ->  reads RunDef from mat file
%                                                                               builds default params using DirInfo from AcDirectoryInfo.m
%                                                                               (for backward compatibility reasons)
%
%                 [RunDef, FileOK] =  LoadRunDefinition([], filename)       ->  reads RunDef from mat file
%                                                                               builds default params using DirInfo from AcDirectoryInfo.m
%
%                 FileOK           = 1 if filename OK and contains Def
%                                  = 0 if otherwise (default RunDef returned)
%
% Revision 0.0   01 December 2004 ... ALM
%                - this is the first attempt at systematically storing ALL model run parameters in a single structure 
%                  which can easily be retreived for future reference or reuse
%
% Revision 0.1   12 May      2005 ... ALM
%                - Add FileOK flag to o/p
%                These mods are part of the first step towards true batch
%                processing capability
%                - Add Scooter member
%                - Add LastFilename member
%                - Add RunID member as cell array
%                  This will initially keep one string as active RunID to
%                  be used when run from file (expansion to multiple runs/models h
%                  per file should be trivial but prefer method below for later use)
%
%                ** would have preferred to add logical switches to each broad
%                model and thus keep the whole structure more object-like
%                but requires too much modification to AcT_UI at this stage
%                
%                eg -> RunDef.RAM.RAMSGeo      = 0/1
%                      RunDef.Scooter.GreensFn = 0/1   | + app methods
%                      RunDef.Scooter.TL       = 0/1   |
%
%                a more streamlined designed can be implemented later -
%                e.g. when modifying to add new model (e.g. adding AG's CM code)
%                Suggest that major redesign -> version 1.0
%
%                (note will also need to add filename to each model sub
%                struct OR better yet add model tag to general filename)
%        
%
% Revision 0.2   31 May      2005 ... ALM
%                - Modify to read put Environment objects from old Defs into EnvArr (when this does not exist in def file)
%
% Revision 0.3   10 July     2006 ... ALM (Viva l'Italia!!)
%                - For some strange reason I'm using the presence of DirInfo to test for default loading of .Environment
%                  Really this is only needed as part of the process to create background object over which the filed information
%                  is written for purposes of backwards compatibility
%                - Change default RunID from '' to 'Scooter+Fields' since this needs no additional parameters beyond 
%                  model-independent parameters and do not allowed stored blank RunID values to overwrite this
%
% Revision 0.4   21 July     2006 ... ALM (Viva l'Italia!!)
%                - Add, for RAMS*, minimum shear speed for substrate to accomodate automatic conversion from 
%                  fluid substrate environments (RAMS* appears to crash for purely fluid substrate - not sure what happens
%                  when cs -> 0 at isolated points or regions though)
%                - Add default file option
%         
%
% Centre for Marine Science and Technology
% Physics Department
% Curtin University
% Perth, Western Australia

TRUE          = 1;
FALSE         = 0;
FileOK        = FALSE;
FileDefault   = FALSE;
RunID_DEFAULT = 'Scooter+Fields';

%check input
if ~exist('DirInfo', 'var'), DirInfo = []; end
if isempty(DirInfo)
   DirInfo  = GetAcDirectoryInfo;
end
if ~exist('filename', 'var'), filename = ''; end
% DEFINE Run Definition from HARDCODED PARAMETERS - THIS IS USED AS BACKGROUND DEF ~ B.C.
if isnumeric(filename)  % i.e. -1
   filename = [DirInfo.RunDef, 'Default.mat'];
   % check existance
   if ~exist(filename, 'file'), 
      filename = ''; 
   else
      FileDefault   = TRUE;
   end
end

% -> Environment
RunDef.EnvArr        = AcEnvArr('Default', DirInfo)  ;
RunDef.Environment   = GetElement(RunDef.EnvArr, 1)  ;

% -> Propagation 
RunDef.RunID         = {RunID_DEFAULT}               ;  % cell array of RunIDs for run from file

RunDef.Title         = 'Default run parameters'      ;  %Title for run
RunDef.Freq          = [10 20 50 100 200 500]        ;  %Frequency(s) (may be an array definition) (Hz)
RunDef.Zs            =   10                          ;  %Source depth (m)
RunDef.Zr            = [5:5:150]                     ;  %Receiver depth (may be an array definition) (m)
RunDef.RMin          =  100                          ;  %Minimum range (m)
RunDef.RMax          = 1000                          ;  %Maximum range (m)
RunDef.NRange        =  200                          ;  %Number of range SLICES (not # STEPS as perhaps annotated elsewhere)
RunDef.dR            =  []                           ;  %Range Step size(m) ... DERIVED PARAMETER
RunDef.SubDir        = ''                            ;
RunDef.FPrefix       = 'Test'                        ;
RunDef.ManualEnvEdit = FALSE                         ;
RunDef.UseBathFile   = FALSE                         ;
RunDef.BathFName     = ''                            ;
RunDef.UseSurfFile   = FALSE                         ;  % RAMSurf only at this but should be with Bathymetry file 
RunDef.SurfFName     = ''                            ;
RunDef.LastFilename  = ''                            ;  %default - not from file

Bellhop.RunType          = 'RB'          ;
Bellhop.NBeams           =    50         ; %Number of beams
Bellhop.StartAngle       =   -80         ; %Starting angle (degrees)
Bellhop.EndAngle         =    80         ; %Ending angle (degrees)
Bellhop.StepSize         =     0.0       ; %Step size along ray for raytrace (wavelengths)
Bellhop.UseBathyFile     = FALSE         ; % FOR BACKWARD COMPATIBILITY ONLY 
Bellhop.BathyFName       = ''            ; % FOR BACKWARD COMPATIBILITY ONLY 

Kraken.ExhaustiveSearch  =  TRUE         ;

Fields.GrnPathname       = ''            ;  % Greens Pathname for grn -> shd conversion
Fields.GrnFilename       = ''            ;  % Greens Filename for grn -> shd conversion
Fields.GrnBasename       = ''            ;  % Greens Filename for grn -> shd conversion
Fields.rmin              = 0             ;  % minimum range for grn to shd
Fields.rmax              = 0             ;  % maximum range for grn to shd
Fields.nr                = 0             ;  % number of range slices

RAM.Species              = 'RAMSGeo'     ;  % Solid Substrate case is most general
RAM.zr                   =    -1         ;  % user select
RAM.dz_lambda            =     0.25      ;  % dz/lambda - maximum rec value
                                                          % Jensen et al., "C.O.A." recommend <= 0.25 
%RAM.ndz                  =     1         ;  % suggestion
RAM.dzgridmin            =    10         ;  % suggestion 
RAM.dr_dz                =     5         ;  % dr/dz     - maximum rec value for bottom interaction 
                                                          % Jensen et al., "C.O.A." recommend
                                                          % 2 - 5 for    bottom interaction 
                                                          % 20-50 for no bottom interaction 
%RAM.ndr                  =     1         ;  % suggestion
RAM.drgridmin            =    10         ;  % suggestion 
RAM.zmplt                =    -1         ;  % user select or auto
RAM.c0                   =  1500         ;  % suggestion
RAM.np                   =     6         ;  % suggestion
RAM.ns                   =     1         ;  % suggestion
RAM.rs                   =     0         ;  % suggestion
RAM.irot                 =     0         ;  % suggestion
RAM.theta                =     0         ;  % suggestion
%RAM.LastLayerDz          =   100         ;  % no longer needed
RAM.LastLayerDz_lambda   =    10         ;  % normalise    Dz/lambda
%RAM.AttenLayerDz         =   100         ;  % suggestion
RAM.AttenLayerDz_lambda  =    10         ;  % normalise    Dz/lambda
RAM.AttenLayerAttenPMax  =    10         ;  % suggestion
RAM.AttenLayerAttenSMax  =    10         ;  % suggestion
%RAM.AttenLayerDz         =   100         ;  % suggestion
RAM.CsMin                =    10         ;  % suggestion (see notes Revision 0.4)
% _________________________________________ PROFILES ARE LIFTED FROM ENVIRONMENT - comment out possible expansion
%RAM.zb                   =    []         ;  % z vs bathymetry profile                                          [m, m]
%RAM.cw                   =    []         ;  % z vs water     layer compressive sound speed profile             [m, m/s]
%RAM.cw                   =    []         ;  % z vs water     layer compressive sound speed profile             [m, m/s]
%RAM.cp                   =    []         ;  % z vs substrate layer compressive sound speed profile             [m, m/s]
%RAM.cs                   =    []         ;  % z vs substrate layer shear       sound speed profile             [m, m/s]
%RAM.rhob                 =    []         ;  % z vs substrate layer density                                     [m, g/cm³]
%RAM.attnp                =    []         ;  % z vs substrate layer compressive attenuation coefficient profile [m, dB/lambda]
%RAM.attns                =    []         ;  % z vs substrate layer shear       attenuation coefficient profile [m, dB/lambda]

RunDef.RAM               = RAM           ;
RunDef.Bellhop           = Bellhop       ;
RunDef.Fields            = Fields        ;
RunDef.Kraken            = Kraken        ;


% LOAD FROM FILE or use only default values ???
if ~isempty(filename) 
   % load Def from file
   if exist(filename, 'file')        % is filename is a valid file on disk ?
      load('-mat', filename);
      if exist('Def', 'var')         % load successful ? 
          FileOK = TRUE;
          if FileDefault
             Def.LastFilename = '';  % do not encourage Default File overwrite !!
          else
             Def.LastFilename = filename;
          end
      else
         disp(['WARNING -> LoadRunDefinition: ', filename, ' does not contain Def - default run definition loaded']);
      end
   else
      disp(['WARNING -> LoadRunDefinition: invalid filename ', filename, ' - default run definition loaded']); 
      clear('filename');      
   end
end

% Bring file RunDefinition up to current spec ....
if FileOK     
   % write over background definition (for backward compatibility reasons) ...
   %     The background structure, RunDef, contains all necessary fields - 
   %     The input/file structure, Def,    may contain redundant fields and these will be ignored   
   DefFields = fieldnames(Def);   
   % is there an EnvArr field ?
   ExistEnvArr = 0;
   for ii = 1:length(DefFields), ExistEnvArr = ExistEnvArr + strcmp(DefFields{ii}, 'EnvArr'); end
   for ii = 1:length(DefFields)
      field = DefFields{ii};
      param = getfield(Def, field);
      if isfield(RunDef, field)
         % special cases to deal with
         switch field
            case {'Bellhop','Kraken','RAM'}
               % avoid wholesale overwrite of RAM, BELLHOP and KRAKEN parameters
               SubDef    = getfield(Def   , field);
               SubRunDef = getfield(RunDef, field);
               SubFields = fieldnames(SubDef);
               for jj = 1:length(SubFields)
                  subfield = SubFields{jj};
                  param    = getfield(SubDef, subfield);
                  % is the (file) field currently used
                  if isfield(SubRunDef, subfield)
                     SubRunDef = setfield(SubRunDef, subfield, param);
                  end
               end
               RunDef = setfield(RunDef, field, SubRunDef);
            case 'Environment'
               % previous versions do not have an environment array object so this needs to be loaded with Environment
               if ~ExistEnvArr
                  % create one
                  EnvArrData.Name      =  GetName(param)        ;
                  EnvArrData.EnvArr    = {param}                ;
                  EnvArrData.RangeVec  = [0]                    ;
                  EnvArrData.dRInterp  =  0                     ;
                  RunDef.EnvArr        =  AcEnvArr(EnvArrData)  ;
               end
            case 'RunID'
               % Some old RunDefs will have empty RunID string - do not permit this
               % Also an oversight on my part in another part of the code meant that 
               % this was saved as a string rather than as a cell array - test for this and correct
               if iscell(Def.RunID) 
                  if ~isempty(Def.RunID{1})
                     RunDef.RunID = Def.RunID;
                  end
               elseif ischar(Def.RunID) 
                  if ~isempty(Def.RunID)
                     RunDef.RunID = {Def.RunID};
                  end
               end
            otherwise  % simple parameters
               RunDef = setfield(RunDef, field, param);
         end
      end
   end
end

