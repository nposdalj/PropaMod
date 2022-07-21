function matOut = map_ESME_TL_delph(indir, diveDepth,TLthresh) %Regina added TLthresh to input arguments

% indir = directory holding .shd files and .bty files
% diveAl = dive altitude of animal
% load('E:\calculating_range\TransmissionLoss.mat')%Regina Added
%in TL, each month has its own column and each row is a different freq
%could create a loop to loop through TLs for each freq....
%example of syntax: TL(20+1,3) is TL for 20 Hz in January (3rd month of
%deployment)
% TLthresh = TL(20+1,3);  % Any transmission loss above this threshold makes the signal undetectable 
cd(indir)
listing = dir(indir);
verbose = false; % turns on plotting
j = 1;
figcnt = 0;
TLvec = [];
for itr = 1:length(listing)
    [pathstr, Fname, ext] = fileparts(listing(itr).name);
    if strcmp(ext,'.shd')
        fileName = listing(itr).name;
        loadFile = fullfile(indir, fileName);
        btyFile = fullfile(indir, strcat(Fname, '.bty'));
        
        angleLoc = strfind(fileName,'_');
        thisAngle(j) = str2num(fileName(angleLoc(2)+1:angleLoc(3)-1));
        
        if j == 1
            %first time through, get a name to save the output files with
            % doing it here because now we know where the spaces are
            saveName = strcat(fileName(1: angleLoc(2)), num2str(diveDepth), 'mDepth');
        end
        
        % Read in data
        BathData{j} = ReadBathymetryFile(btyFile);
        [~, freq, nsd, nrd, nrr, sd, rd, rr, tlt, ~,~] = ReadShadeBin( fileName );
  
        % Figure out which cell of TL matrix should be used for each
        % distance.
        TLmat = -20*log10(tlt);%tlt is complex pressure
        
        tlIdx = [];

        for itr_depth = 1:length(rr)%rr is range in meters
            [~,altRow] = min(abs(rd - diveDepth));
            tlIdx(itr_depth) = altRow;
            TLvec(j,itr_depth) = TLmat(altRow,itr_depth);
        end
        
        if verbose
            %figure(200+figcnt)
            figure;
            plot(rr,TLvec(j,:),'*');
            figcnt = figcnt+1;
            title(thisAngle(j));
        end
        % h = imagesc(rangeVec, depthVec,radial);
        j = j+1;
    end
end

[b,IX] = sort(thisAngle);%Angles are not in order, so we need to sort to go around circle in order of radial angles, IX is index
sortedTLVec = TLvec(IX,:);
sortedAngle = thisAngle(IX)';%same as b.

LocForRange=(find(rr>=2000));%find locations greater than or equal to 2km
MaxRadius=LocForRange(1);%the point where range is 2km (or slightly over)
figure;
plotHandle = bullseye(sortedTLVec(:,1:MaxRadius),'N',10,'rho', [1 rr(MaxRadius)],'tht',[0 360], 'tht0', 180);
title(gca, {'Transmission loss'; strcat('Frequency: ', num2str(freq), ' Hz;    ',...
    '  Radius: ', num2str(rr(MaxRadius)/1000), ' km;    ','  Dive Depth: ', num2str(diveDepth), ' m')}, 'FontSize', 16)

% Save plots and data
cd(indir)
saveas(gca, strcat(saveName, '_polarPlot.png'))
saveas(gca, strcat(saveName, '_polarPlot.fig'))
matOut = strcat(saveName, '_polar.mat');
save(matOut)

sortedTLVecLim = [];
for mLim = 1:size(sortedTLVec,1)
    for nLim = 1:size(sortedTLVec,2)
        if sortedTLVec(mLim, nLim)> TLthresh
            sortedTLVecLim(mLim, nLim) = TLthresh + 5;
        else
            sortedTLVecLim(mLim, nLim) = sortedTLVec(mLim, nLim);
        end
    end
end
figure;
% jj = 1500; %  radius cutoff
% plotHandle = bullseye(sortedTLVecLim(:,1:jj),'N',10,'rho', [1 rr(end)],'tht',[0 360],'tht0', 180);
plotHandle = bullseye(sortedTLVecLim(:,1:MaxRadius),'N',10,'rho', [1 rr(MaxRadius)],'tht',[0 360],'tht0', 180);%rr(500) is 5km=5,000 m
title(gca, {strcat('Transmission loss,', num2str(TLthresh), 'dB cutoff'); strcat('Frequency: ', num2str(freq), ' Hz;    ',...
    '  Radius: ', num2str(rr(MaxRadius)/1000), ' km;    ','  Dive Depth: ', num2str(diveDepth), ' m')}, 'FontSize', 16)

saveas(gca, strcat(saveName, '_polarPlotCutoff.png'))
saveas(gca, strcat(saveName, '_polarPlotCutoff.fig'))

1;