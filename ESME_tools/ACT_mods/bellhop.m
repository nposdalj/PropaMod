function bellhop( filename )

% useage: bellhop( filename )
% where filename is the environmental file
%
% runs the BELLHOP program
% funky syntax to trap unimportant errors
% mbp Dec. 2002


if ( isempty( filename ) )
   warndlg( 'No envfil has been selected', 'Warning' );
else
   warning off
   try copyfile( [ filename '.ati' ], 'ATIFIL' ); catch end
   try copyfile( [ filename '.bty' ], 'BTYFIL' ); catch end
   try copyfile( [ filename '.trc' ], 'TRCFIL' ); catch end
   try copyfile( [ filename '.brc' ], 'BRCFIL' ); catch end
   try copyfile( [ filename '.sbp' ], 'SBPFIL' ); catch end
   eval(['!which bellhop'])
      
   eval( [ '! bellhop.exe ' filename ] )
   
   delete 'ATIFIL';
   delete 'BTYFIL';
   delete 'TRCFIL';
   delete 'BRCFIL';
   delete 'SBPFIL';
   try movefile( 'ARRFIL', [ filename '.arr' ] ); catch end
   try movefile( 'RAYFIL', [ filename '.ray' ] ); catch end
   try movefile( 'SHDFIL', [ filename '.shd' ] ); catch end
   warning on
end
