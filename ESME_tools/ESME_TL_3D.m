function sortedTLVec = ESME_TL_3D(indir,TLmethod) 

% indir = directory holding .shd files and .bty files

% cd(indir)
listing = dir(indir);
j = 1;
rd_all= {};
cd(indir)
for itr = 1:length(listing)
    [pathstr, Fname, ext] = fileparts(listing(itr).name);
    if strcmp(ext,'.shd')
        fileName = listing(itr).name;
        loadFile = fullfile(indir, fileName);
        btyFile = fullfile(indir, strcat(Fname, '.bty'));
        
        angleLoc = strfind(fileName, '_');
        % angleLoc = itr;
        ll = length(angleLoc);
        thisAngle(j) = str2num(fileName(angleLoc(ll-1)+1:angleLoc(ll)-1));
        % thisAngle(j) = angleLoc;
        if j == 1
            % first time through, get a name to save the output files with
            % doing it here because now we know where the spaces are
            % saveName = strcat(fileName(1: angleLoc(3)));
            saveName = strcat(fileName(1:8));
        end
       
        
        % Read in data
        BathData = ReadBathymetryFile(btyFile);
        
        [~, freq, nsd, nrd, nrr, sd, rd, rr, tlt, ~,~] = ReadShadeBin(fileName, TLmethod);
%         if nrr>2000
%             nrr = 1000;
%             rr = rr(1:nrr);
%             tlt = tlt(:,1:nrr);
%         end
        rd_all{j} = rd;
        % turn TL into dB       
        TLmat = -20*log10(tlt);
        botDepth = BathData(2,:);
        botDepth_interp(j,:) = interp1(BathData(1,:),botDepth,rr,'spline');

        for i1 = 1:length(botDepth_interp(j,:))
            [~,botCutoff(i1,1)] = min(abs(botDepth_interp(j,i1) - rd));
        end
        for i2 = 1:size(TLmat,2)
            thisCut = botCutoff(i2);
            TLmat(thisCut:end,i2) = Inf;
        end
        
        
        
        % hold onto the whole slice in a cell array
        TLAll{j} = TLmat;

        % h = imagesc(rangeVec, depthVec,radial);
        j = j+1;
    end
end


[thisAngle,IX] = sort(thisAngle);
sortedTLVec = {};
for itr = 1:length(IX)
    sortedTLVec{itr} = real(TLAll{1,IX(itr)});    
    sortedTLVec{itr}(:,1) = sortedTLVec{itr}(:,2);

end
botDepthSort = botDepth_interp(IX,:);
rd_all = rd_all(IX);
% Save plots and data
cd(indir)
matOut = strcat(saveName, '_3DTL.mat');
save(matOut, 'thisAngle', 'rr', 'nrr', 'botDepthSort', 'sd', 'sortedTLVec', 'IX','rd_all')

% 
% plot vertical profile
profNum  =1;
thisProf = sortedTLVec{profNum};
thisBot = botDepth_interp(profNum,:);
botCutoff = [];
for itr = 1:length(thisBot)
    [~,botCutoff(itr,1)] = min(abs(thisBot(itr) - rd));
end
for itr2 = 1:size(thisProf,2)
    thisCut = botCutoff(itr2);
    thisProf(thisCut:end,itr2) = Inf;
end
figure(11);clf
% [cmap, lims, ticks, bfncol, ctable] = cptcmap('GMT_wysiwygcont.cpt', gca, 'mapping', 'scaled', 'ncol', 256);
% colormap(flipud(cmap));
imagesc(rr,rd,real(thisProf))
colorbar
1;