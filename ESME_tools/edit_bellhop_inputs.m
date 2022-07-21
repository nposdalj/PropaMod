function outdir = edit_bellhop_inputs(indir, varargin)
% Inputs:
% newFreqHzNum % freq you want to put in (Hz)]
% newSedStr = '1481 310.3 1.149 0.00386 0';
% modSed % set to true if you want to change the sediment composition parameters
% modFreq % set to true if you want to change the frequency


if nargin == 1 % rename only case
    newFreqHzNum = NaN;
    newSedStr = ' ';
    modSed = false; % set to true if you want to change the sediment composition parameters
    modFreq = false;
elseif nargin == 2 % rename and change frequency case
    newFreqHzNum = varargin{1};
    newSedStr = ' ';
    modFreq = true;
    modSed = false;
elseif nargin == 3 % rename, change frequency, and change sediment composition case 
    newFreqHzNum = varargin{1};    
    modFreq = true;

    if ~isempty(varargin{2})
        newSedStr = varargin{2};
        modSed = true;
    else 
        modSed = false;
    end
else
    error('Invalid number of input arguments');
end


listing = dir(indir); % what files are in the directory
cd(indir)
outdir = strcat(num2str(newFreqHzNum/1000), 'kHz'); 
if ~isdir(strcat(indir, '\', outdir))
    mkdir(indir, outdir)
end

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

% Pull env files in one by one and change the desired info


newFreqHz = num2str(newFreqHzNum); 
newFreqkHz = num2str(newFreqHzNum/1000);
ICount = 0;
for itr2 = 1:length(envIdx)
    fileIn = listing(envIdx(itr2)).name;
    [fileInPath, fileInName, fileInExt]= fileparts(fileIn);
    fid_in = fopen(fileIn);
    outFileName = strcat(fileInName, '_temp',fileInExt);
    fid_out = fopen(outFileName, 'w+');
    isAstar = 0;
    lineCounter = 1;
    while ~feof(fid_in)
        
        s = fgets(fid_in);
        if isAstar == 1 && modSed == true
            s = strrep(s, '0 0 0 0 0', newSedStr);
            Astar = 0;
        end
        if lineCounter == 1
            % parse out new file name
            remain = 'holder';
            tokeNum = 1;
            s2 = s;
            token = {};
            while ~isempty(remain)
                [token{tokeNum}, remain] = strtok(s2, ' ');
                tokeNum = tokeNum + 1;
                s2 = remain;
            end
            site_quotes = char(token{2});
            site = site_quotes(2:end-1);
            newOutFile = strcat(outdir, '\', site, '_', newFreqkHz, 'kHz', '_', char(token(length(token))), '_', 'deg');
            
        elseif lineCounter == 2 && modFreq == true
            % enter new frequency
            s = strrep(s, s, sprintf('%s\r\n', newFreqHz));
        end
        % find the line before the one holding the sediment info, and turn
        % on Astar flag:
        isAstar = strcmpi(cellstr(s), cellstr(strcat(sprintf('''%c*'' ','A'),  ' 0.0')));   
        isI = strcmpi(cellstr(s), cellstr(sprintf('''%c'' ','I')));   
        if ICount == 1
            s = strrep(s,'3000','5000');
            ICount = 0;
        end
        if isI 
            ICount = 1;
        end
        % whatever s has become, write it
        fprintf(fid_out,'%s',s);
        lineCounter = lineCounter+1;
    end

    fclose(fid_in);
    fclose(fid_out);
    
    % now rewrite the file with the new, informational name
    fid_temp = fopen(outFileName);
    fid_rename = fopen([newOutFile, fileInExt], 'w+');
     while ~feof(fid_temp)
        s = fgets(fid_temp);
        fprintf(fid_rename,'%s',s);
    end
    fclose(fid_temp);
    fclose(fid_rename);
    % delete temp file
    delete(outFileName)
    
    % find and rename other associated files: ssp and bty
    sspInFile = [fileInName, '.ssp'];
    sspOutFile = [newOutFile, '.ssp'];
    btyInFile = [fileInName, '.bty'];
    btyOutFile = [newOutFile, '.bty'];
    trcInFile = [fileInName, '.trc'];
    trcOutFile = [newOutFile, '.trc'];
    fid_in_ssp = fopen(sspInFile);
    fid_out_ssp = fopen(sspOutFile,'w+');
    fid_in_bty = fopen(btyInFile);
    fid_out_bty = fopen(btyOutFile, 'w+');
    fid_in_trc = fopen(trcInFile);
    fid_out_trc = fopen(trcOutFile, 'w+');
    
    while ~feof(fid_in_ssp)
        s = fgets(fid_in_ssp);
        fprintf(fid_out_ssp,'%s',s);
    end
    while ~feof(fid_in_bty)
        s = fgets(fid_in_bty);
        fprintf(fid_out_bty,'%s',s);
    end
    while ~feof(fid_in_trc)
        s = fgets(fid_in_trc);
        fprintf(fid_out_trc,'%s',s);
    end    
    fclose all;
end