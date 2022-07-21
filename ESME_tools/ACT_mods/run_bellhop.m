function run_bellhop(indir)


listing = dir(indir); % what files are in the directory
cd(indir)
isEnv = [];
% get names of all the .env files
for itr = 1:length(listing)
    [~, ~, ext] = fileparts(listing(itr,1).name);
    if strcmp(ext, '.env')
        isEnv(itr) = 1;
    else
        isEnv(itr) = 0;
    end
end

envIdx = find(isEnv ==1);
for itr2 = 1:length(envIdx)
    fileIn = listing(envIdx(itr2)).name;
    [~, fileInName, ~] = fileparts(fileIn);
    bellhop(fullfile(indir,fileInName));
end