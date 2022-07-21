% Takes a set of RamGEO input files created by ESME, and uses them
% to run prop models across a whole range of frequencies.
% Also allows you to modify sediment parameters.
clearvars
indir = 'E:\calculating_range\64RadialsGCJan_NE';
%get this folder from C:\Users\Harp\AppData\Roaming\ESME Workbench\Database\scenarios\
freq =27;%20:10:100;  % range of frequencies you want it to run through
dive_depth = 40; % in meters
load('E:\AmbientNoise\DCPP02A - Dec 2 2014\TransmissionLoss.mat')%Regina Added

tic
for itr = 1:length(freq)
    
    %freqVec(itr) = freq(itr); %don't think you need this line...freqVec
    %isn't used
    
    outdir = chng_sedComp_ram(indir, freq(itr),dive_depth); % if you don't include a sediment 
    % string here (see next line of code) then chng_sedComp won't modify that part, 
    % it will only modify the frequency.
    % The sediment part is only useful for areas where there are holes in the sediment
    % record.
    % Alternate line of code:
    % outdir = chng_sedComp(indir, freq(itr), '1481 310.3 1.149 0.00386 0');
    runfile=strcat(indir,'\',outdir);
    run_ramgeo(runfile) % runs ramgeo
    
    %example of syntax: TL(20+1,3) is TL for 20 Hz in January (3rd month of
    %deployment)
    TLthresh = TL(freq(itr)+1,3);  % Any transmission loss above this threshold makes the signal undetectable

    
    % You can switch the following to call "map_ESME_TL_bin" if you want to use 
    % altitude off the seafloor rather than depth. Whichever you use, open
    % it up and make sure you're happy with the transmission loss threshold
    % used. 
    matOut = map_ESME_TL_delph(strcat(indir,'\',outdir), dive_depth, TLthresh);
    %matOut = map_ESME_TL_delph(indir, dive_depth);
    
    load(matOut, 'TLvec') % loads the mat file just created by map_ESME_TL_delph
    TLnoInf = isfinite(abs(TLvec));
    TLmean(itr,:) = mean(TLvec(TLnoInf), 1);
    for meanItr = 1:size(TLvec,2) % this is going through and figuring out mean attenuation as a function of distance for this site and frequency. You might not care.
        TLmean(itr,meanItr) = mean(real(TLvec(isfinite(TLvec(:,meanItr)), meanItr)));
    end
    clear TLvec
    %close all
end

save([indir, '\', 'freq_TL.mat'])
% Plots mean attenuation as a function of
% distance and frequency for this site.
figure(101); 
[cmap, lims, ticks, bfncol, ctable] = cptcmap('GMT_wysiwygcont.cpt', gca, 'mapping', 'scaled', 'ncol', 256);
colormap(flipud(cmap));
[mthresh, nthresh] = find(TLmean>=180);%TLmean>=max plotted transmission loss

TLmean_thresh = TLmean;
for mitr = 1: length(mthresh)
    m = mthresh(mitr);
	n = nthresh(mitr);
    TLmean_thresh(m, n) = 185;%change all values higher than 180 to 185 dB
end

im_h = imagesc(.005:.005:20, (freq),(real(TLmean_thresh(:,1:end-1))));%for TL up to 25 km, counts in 10s so max*10=range
set(gca,'FontSize', 14);
ylabel('Frequency (Hz)', 'FontSize', 14)
xlabel('Distance (km)', 'FontSize', 14)
cb_h = colorbar;
set(cb_h, 'FontSize', 14)
ylabel(cb_h, 'Transmission Loss(dB)')
toc