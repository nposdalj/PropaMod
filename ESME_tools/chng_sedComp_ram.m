function outdir = chng_sedComp_ram(indir, varargin)
% Inputs:
% newFreqHzNum % freq you want to put in (Hz)]
% newSedStr = '1481 310.3 1.149 0.00386 0';
% modSed % set to true if you want to change the sediment composition parameters
% modFreq % set to true if you want to change the frequency

%trouble shooting section
% indir = 'H:\data\Research\SOCAL habitat modeling\Propagation modeling\1k1gi3gu';
% nargin = 2;
% varargin = {48};

if nargin == 1 % rename only case
    newFreqHzNum = NaN;
    newSedStr = ' ';
    modSed = false; % set to true if you want to change the sediment composition parameters
    modFreq = false;
elseif nargin == 3 % rename and change frequency case
    newFreqHzNum = varargin{1};
    dive_depth=varargin{2};
    newSedStr = ' ';
    modFreq = true;
    modSed = false;
elseif nargin == 4 % rename, change frequency, and change sediment composition case
    newFreqHzNum = varargin{1};
    dive_depth=varargin{2};
    newSedStr = varargin{3};
    modFreq = true;
    modSed = true;
else
    error('Invalid number of input arguments');
end

listing = dir(indir); % what files are in the directory
cd(indir)
outdir = strcat(num2str(newFreqHzNum), 'Hz',num2str(dive_depth), 'm');%change folder name for different depths!
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
%newFreqkHz = num2str(newFreqHzNum/1000);
for itr2 = 1:length(envIdx)
    fileIn = listing(envIdx(itr2)).name;
    [fileInPath, fileInName, fileInExt]= fileparts(fileIn);
    fid_in = fopen(fileIn);
    outFileName = strcat(fileInName, '_temp',fileInExt);
    fid_out = fopen(outFileName, 'w+');
    isAstar = 0;
    lineCounter = 1;
    while ~feof(fid_in)%reads files line by line
        
        s = fgets(fid_in);%current line
        if isAstar == 1 && modSed == true
            s = strrep(s, '0 0 0 0 0', newSedStr);%find this string and replace with new string
            Astar = 0;
        end
        if lineCounter == 1%increases each time through the loop
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
            %need to make sure token val corresponds to bearing value (what degree #)!
            newOutFile = strcat(outdir, '\', site, '_', newFreqHz, 'Hz', '_', char(token(12)), '_', 'deg');
            
            
            
        elseif lineCounter == 2 && modFreq == true
            % enter new frequency
            s = strrep(s, s(1:9), sprintf('%0.6f',str2num(newFreqHz)));
        end
        
        %% These lines are very specific to data where there was the wrong info for the sediment
        bearingval=str2num(char(token(12)));%convert string to number
        if strcmpi(indir,'E:\calculating_range\GraniteCanyon30mJan');
            if bearingval>=22.5 && bearingval<=123.75
                if lineCounter==4
                    s=strrep(s,s(1:9),sprintf('%0.6f',1863.02));
                elseif lineCounter==170 || lineCounter==242
                    s=strrep(s,s(1:3),sprintf('%d\t%0.1f',0,1767.3));
                elseif lineCounter==172 || lineCounter==244
                    s=strrep(s,s(1:3),sprintf('%d\t%0.3f',0,1.845));
                elseif lineCounter==175 || lineCounter==247
                    s=strrep(s,s(1:4),sprintf('%d\t%d',885,40));
                end
            
            elseif bearingval>258.75 && bearingval<281.25
               if lineCounter==170 || lineCounter==242
                    s=strrep(s,s(1:6),sprintf('%d\t%0.1f',0,1767.3));
                elseif lineCounter==172 || lineCounter==244
                    s=strrep(s,s(1:7),sprintf('%d\t%0.3f',0,1.845));
                elseif lineCounter==175 || lineCounter==247
                    s=strrep(s,s(1:6),sprintf('%d\t%d',885,40));
                end
            end
        end
        if strcmpi(indir,'E:\calculating_range\DiabloJan30Hz')|| strcmpi(indir,'E:\calculating_range\64RadialsDCJan');
            if bearingval>=33.75 && bearingval<=56.25
                if lineCounter==4
                    s=strrep(s,s(1:9),sprintf('%0.6f',1052.9));
                elseif lineCounter==171 || lineCounter==244
                    s=strrep(s,s(1:3),sprintf('%d\t%d',0,1481));
                elseif lineCounter==173 || lineCounter==246
                    s=strrep(s,s(1:3),sprintf('%d\t%0.3f',0,1.149));
                elseif lineCounter==176 || lineCounter==249
                    s=strrep(s,s(1:4),sprintf('%d\t%d',495,40));
                end
            end
        elseif strcmpi(indir,'E:\calculating_range\DiabloApr');
            if bearingval>=33.75 && bearingval<=56.25
                if lineCounter==4
                    s=strrep(s,s(1:9),sprintf('%0.6f',1547.9));
                elseif lineCounter==171 || lineCounter==244
                    s=strrep(s,s(1:3),sprintf('%d\t%d',0,1481));
                elseif lineCounter==173 || lineCounter==246
                    s=strrep(s,s(1:3),sprintf('%d\t%0.3f',0,1.149));
                elseif lineCounter==176 || lineCounter==249
                    s=strrep(s,s(1:4),sprintf('%0.1f\t%d',742.5,40));
                end
            end
        end
        
        
        
        % find the line before the one holding the sediment info, and turn
        % on Astar flag:
        isAstar = strcmpi(cellstr(s), cellstr(strcat(sprintf('''%c*'' ','A'),  ' 0.0')));
        %         if isAstar==1
        %             lineCounter
        %             bearingval
        %         end
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
    
    % find and rename other associated files: pgrid and bty
    pgridInFile = [fileInName, '.pgrid'];
    pgridOutFile = [newOutFile, '.pgrid'];
    btyInFile = [fileInName, '.bty'];
    btyOutFile = [newOutFile, '.bty'];
    %     shdInFile = [fileInName, '.shd'];
    %     shdOutFile = [newOutFile, '.shd'];
    axsInFile = [fileInName, '.axs'];
    axsOutFile = [newOutFile, '.axs'];
    fid_in_pgrid = fopen(pgridInFile);
    fid_out_pgrid = fopen(pgridOutFile,'w+');
    fid_in_bty = fopen(btyInFile);
    fid_out_bty = fopen(btyOutFile, 'w+');
    %     fid_in_shd = fopen(shdInFile);
    %     fid_out_shd = fopen(shdOutFile, 'w+');
    fid_in_axs = fopen(axsInFile);
    fid_out_axs = fopen(axsOutFile, 'w+');
    
    while ~feof(fid_in_pgrid)
        s = fgets(fid_in_pgrid);
        fprintf(fid_out_pgrid,'%s',s);
    end
    while ~feof(fid_in_bty)
        s = fgets(fid_in_bty);
        fprintf(fid_out_bty,'%s',s);
    end
    %     while ~feof(fid_in_shd)
    %         s = fgets(fid_in_shd);
    %         fprintf(fid_out_shd,'%s',s);
    %     end
    while ~feof(fid_in_axs)
        s = fgets(fid_in_axs);
        fprintf(fid_out_axs,'%s',s);
    end
    fclose all;
end