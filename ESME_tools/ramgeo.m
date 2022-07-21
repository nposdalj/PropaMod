function ramgeo( filename, FName)
% ripped from acoustic toolbox to run esme actup - kef 130401
% useage: ramgeo( filename )
% where filename is the environmental file
%
% runs the RAMGEO program
% funky syntax to trap unimportant errors
% mbp Dec. 2002


if ( isempty( filename ) )
    warndlg( 'No envfil has been selected', 'Warning' );
else
    warning off
    %    try copyfile( [ filename '.ati' ], 'ATIFIL' ); catch end
    %    try copyfile( [ filename '.bty' ], 'BTYFIL' ); catch end
    %    try copyfile( [ filename '.trc' ], 'TRCFIL' ); catch end
    %    try copyfile( [ filename '.brc' ], 'BRCFIL' ); catch end
    %    try copyfile( [ filename '.sbp' ], 'SBPFIL' ); catch end
    
    eval( [ '! ramgeo.exe ' filename '> logt.txt'] )
    eval(['! move /Y tl.grid ' FName '.grid >> logt.txt']);  %  std  RAM* transmission loss files
    eval(['! move /Y tl.line ' FName '.line >> logt.txt']);  %  std  RAM* transmission loss files
    eval(['! move /Y p.grid  ' FName '.pgrid >> logt.txt']);  %  CMST RAM* pressure (complex) files
    % eval(['! move /Y ' p.line  ' "' FName '.pline" ]);  %  CMST RAM* pressure (complex) files
    
    RamIn = ReadRamInFile('RAMGeo', [FName, '.env']);
    PGrid = ReadRamPGrid('RAMGeo', [], [FName, '.pgrid']); % [] use current/version parameters
    % --------------------------
    if ~isempty(PGrid)
        nzplt = size(PGrid,1);
        nrplt = size(PGrid,2);
        dzplt = RamIn.dz*RamIn.ndz;
        drplt = RamIn.dr*RamIn.ndr;
        rr    = (1:1:nrplt) .* drplt;
        rd    = (1:1:nzplt) .* dzplt;
        rd    = rd-RamIn.dz;
        
        WriteShadeFile(['RAMGeo', ' - ', RamIn.title], ...
            RamIn.freq, ...
            RamIn.zs, ...
            rd, ...
            rr, ...
            PGrid, ...
            [FName, '.shd']);
    end
    %    delete 'ATIFIL';
    %    delete 'BTYFIL';
    %    delete 'TRCFIL';
    %    delete 'BRCFIL';
    %    delete 'SBPFIL';
    %    try movefile( 'ARRFIL', [ filename '.arr' ] ); catch end
    %    try movefile( 'RAYFIL', [ filename '.ray' ] ); catch end
    %    try movefile( 'SHDFIL', [ filename '.shd' ] ); catch end
    warning on
end
