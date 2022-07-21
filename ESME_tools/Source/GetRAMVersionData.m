function RAMVersionData = GetRAMVersionData(species)
% GetRAMVersionData  Returns structure containing parameters for all current RAM* executables in use
%
% USAGE:         RAMVersionData = GetRAMVersionData();           % get version data for all species of RAM
%                RAMVersionData = GetRAMVersionData(species);    % get species version data
%
%                where species = 'RAM'
%                                'RAMS'
%                                'RAMGeo'
%                                'RAMSurf'
%
% 4 availble species ... 
% IF species is omitted, structure returns with 4 substructures 
%   RAMVersionData.RAM        (RAM)
%   RAMVersionData.S          (RAMS)
%   RAMVersionData.Geo        (RAMGeo)
%   RAMVersionData.Surf       (RAMSurf)
%
% each contains the foillowing fields
%    .Ver         = full current version + build number
%    .MaxNumBath  = max number of bathymetry points (r,z)
%    .MaxNumZ     = max number of grid points in depth (z)
%    .MaxNumPade  = max number of expansion terms
%    .PGridFormat = structure containing complex pressure grid output binary format 
%
% ELSE IF species is supplied then the root structure directly contains the fields specified above
%
% The PGridFormat sub-structure has format:
%         .HeadJunkFieldNum    number of junk fields in header
%         .HeadJunkFieldSiz    junk field size as type string   (eg 'uint32')
%         .DataJunkFieldNum    number of junk fields in header
%         .DataJunkFieldSiz    junk field size as type string   (eg 'uint32')
%         .NzFieldSiz          Nz field size as type string     (eg 'int32')
%         .DataFieldNum        number of data fields header     (-1 if record length dependent)
%         .DataFieldSiz        data field size as type string   (eg 'float32')
 


% possible Grid formats
% 1
GForm.HeadJunkFieldNum =  1;
GForm.HeadJunkFieldSiz = 'uint32';
GForm.DataJunkFieldNum =  2;
GForm.DataJunkFieldSiz = 'uint32';
GForm.NzFieldSiz       = 'int32';
GForm.DataFieldNum     = -1;           % -1 = record length dependent
GForm.DataFieldSiz     = 'float32';
GridFormats(1)         = GForm;
% 2 ... ??? 


% RAM
temp.Ver               = []; % not yet available 
temp.ExeName           = 'ram.exe'     ;
temp.InName            = 'ram.in'      ;
temp.PGridName         = 'p.grid'      ;
temp.PLineName         = 'p.line'      ;
temp.TLGridName        = 'tl.grid'     ;
temp.TLLineName        = 'tl.line'     ;
temp.MaxNumBath        =  100          ;
temp.MaxNumZ           =  8000         ;
temp.MaxNumPade        =   10          ;
temp.PGridFormat       = GridFormats(1);
RAM                    = temp          ;

% S
temp.Ver               = []; % not yet available 
temp.ExeName           = 'rams.exe'    ;
temp.InName            = 'rams.in'     ;
temp.PGridName         = 'p.grid'      ;
temp.PLineName         = 'p.line'      ;
temp.TLGridName        = 'tl.grid'     ;
temp.TLLineName        = 'tl.line'     ;
temp.MaxNumBath        =   100         ;
temp.MaxNumZ           = 10000         ;
temp.MaxNumPade        =    10         ;
temp.PGridFormat       = GridFormats(1);
RAMS                   = temp          ;

% Geo
temp.Ver               = '1.5C00.03.00'; 
temp.ExeName           = 'RAMGeo.exe'  ;
temp.InName            = 'ramgeo.in'   ;
temp.PGridName         = 'p.grid'      ;
temp.PLineName         = 'p.line'      ;
temp.TLGridName        = 'tl.grid'     ;
temp.TLLineName        = 'tl.line'     ;
temp.MaxNumBath        =  100          ;
temp.MaxNumZ           =20000          ;
temp.MaxNumPade        =   10          ;
temp.PGridFormat       = GridFormats(1);
RAMGeo                 = temp          ;

% Surf
temp.Ver               = []; % not yet available
temp.ExeName           = 'ramsurf.exe' ;
temp.InName            = 'ramsurf.in'  ;
temp.PGridName         = 'p.grid'      ;
temp.PLineName         = 'p.line'      ;
temp.TLGridName        = 'tl.grid'     ;
temp.TLLineName        = 'tl.line'     ;
temp.MaxNumBath        =  100          ;
temp.MaxNumZ           = 8000          ;
temp.MaxNumPade        =   10          ;
temp.PGridFormat       = GridFormats(1);
RAMSurf                = temp          ;

% SGeo
temp.Ver               = '1.5C01.01.01'; 
temp.ExeName           = 'ramsgeo.exe' ;
temp.InName            = 'ramsgeo.in'  ;
temp.PGridName         = 'p.grid'      ;
temp.PLineName         = 'p.line'      ;
temp.TLGridName        = 'tl.grid'     ;
temp.TLLineName        = 'tl.line'     ;
temp.MaxNumBath        =   100         ;
temp.MaxNumZ           = 10000         ;
temp.MaxNumPade        =    10         ;
temp.PGridFormat       = GridFormats(1);
RAMSGeo                = temp          ;

% return species specific data only if properly requested
if exist('species', 'var')
   switch upper(species)
      case 'RAM'
         RAMVersionData = RAM       ;
      case 'RAMS'
         RAMVersionData = RAMS      ; 
      case 'RAMGEO'
         RAMVersionData = RAMGeo    ; 
      case 'RAMSURF'
         RAMVersionData = RAMSurf   ;
      case 'RAMSGEO'
         RAMVersionData = RAMSGeo   ;
      otherwise
         error(['ERROR: GetRamVersionData -> ''species'' parameter invalid']);
         RAMVersionData = [];
   end
else
   RAMVersionData.RAM     = RAM       ;
   RAMVersionData.RAMS    = RAMS      ;
   RAMVersionData.RAMGeo  = RAMGeo    ; 
   RAMVersionData.RAMSurf = RAMSurf   ;
   RAMVersionData.RAMSurf = RAMSGeo   ;
end
   
         
