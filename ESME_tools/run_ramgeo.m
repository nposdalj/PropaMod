function run_ramgeo(indir)


listing = dir(fullfile(indir,'*.env')); % what files are in the directory
cd(indir)

for itr2 = 1:length(listing)
    fileIn = listing(itr2).name;
    % [~, fileInName, ~] = fileparts(fileIn);
    
    % temporarily rewrite current .env file to a "ramgeo.in" file
    copyfile(fileIn,'ramgeo.in')
    [~,rootFile,~] = fileparts(fileIn);
    ramgeo('ramgeo.in',rootFile);
    fprintf('Done with radial %0.0f of %0.0f\n',itr2,length(listing))

end