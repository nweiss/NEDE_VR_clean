clear all; close all; clc;

LOAD_PATH1 = fullfile('..','Data','training_v5','training_data_neil_pilot_HRinICA.mat');
load(LOAD_PATH1);
LOAD_PATH2 = fullfile('..','Data','raw_mat','subject_10','s10_b2_raw.mat');
load(LOAD_PATH2);
FUNC_PATH = fullfile('..','Functions');
addpath(FUNC_PATH);
DEP_PATH = fullfile('..','Dependancies');
addpath(DEP_PATH);
stimulus_type = convertLabels(stimulus_type);

if true
    EEG = rmvRotationComps(EEG,head_rotation); 
end

% look at an individual subject
if false
    only_sub = 4;
    dwell_times(subject~=only_sub) = [];
    EEG(:,:,subject~=only_sub) = [];
    head_rotation(subject~=only_sub,:) = [];
    pupil(subject~=only_sub,:) = [];
    stimulus_type(subject~=only_sub) = [];
    block(subject~=only_sub) = [];
end

% look at first set of 20 blocks
if true
    dwell_times(block>=20) = [];
    EEG(:,:,block>=20) = [];
    head_rotation(block>=20,:) = [];
    pupil(block>=20,:) = [];
    stimulus_type(block>=20) = [];
end

% look at an individual block
if false
    dwell_times(block~=2) = [];
    EEG(:,:,block~=2) = [];
    head_rotation(block~=2,:) = [];
    pupil(block~=2,:) = [];
    stimulus_type(block~=2) = [];
end

% look at the trials per block
if false
    trialsPerBlock = zeros(max(block),1);
    for i = 1:max(block)
        trialsPerBlock(i) = sum(block == i);
    end
    figure
    plot(trialsPerBlock, '*')
    ylim([0,20])
    title('Trials Per Block')
    xlabel('Block Number')
    ylabel('Number of Trials')
end

% look at a handfull of randomly selected pupil trials
if false
    k = 15;
    nTarg = sum(stimulus_type == 1);
    nDist = sum(stimulus_type == 0);
    targInd = find(stimulus_type == 1);
    distInd = find(stimulus_type == 0);
    rng=5;
    randTargInd = targInd(randperm(nTarg,k));
    randDistInd = distInd(randperm(nDist,k));
    pupilTargSamples = pupil(randTargInd,:);
    pupilDistSamples = pupil(randDistInd,:);
    t = linspace(-1000,3000,size(pupil,2));
    figure
    plot(t,pupilTargSamples,'b')
    hold on
    plot(t,pupilDistSamples,'r')
    legend('Targets','\color{red} Distractors')
end

% look at the distributuion of the pupil
if false
    figure
    targMean = mean(pupil(stimulus_type==1,:),1);
    targStd = std(pupil(stimulus_type==1,:),1);
    distMean = mean(pupil(stimulus_type==0,:),1);
    distStd = std(pupil(stimulus_type==0,:),1);
    t = linspace(-1000,3000,size(pupil,2));    
    H1 = shadedErrorBar(t,targMean,targStd,'b',1);
    hold on
    H2 = shadedErrorBar(t,distMean,distStd,'r',1);
    legend([H1.mainLine, H2.mainLine], 'targets', 'distractors', 'Location', 'SouthWest')
    title('Pupil Distributions with Standard Deviation')
    xlabel('Time')
    ylabel('Pupil Radius')    
end

% look at a handfull of randomly selected head rotation trials
if false
    head_rotation = abs(head_rotation);
    ind = head_rotation > 100;
    head_rotation(ind) = nan;
    k = 15;
    nTarg = sum(stimulus_type == 1);
    nDist = sum(stimulus_type == 0);
    targInd = find(stimulus_type == 1);
    distInd = find(stimulus_type == 0);
    rng=5;
    randTargInd = targInd(randperm(nTarg,k));
    randDistInd = distInd(randperm(nDist,k));
    hrTargSamples = head_rotation(randTargInd,:);
    hrDistSamples = head_rotation(randDistInd,:);
    t = linspace(-500,1500,size(head_rotation,2));
    figure
    plot(t,hrTargSamples,'b')
    hold on
    plot(t,hrDistSamples,'r')
    legend('Targets','\color{red} Distractors')
    ylim([-5,50])
    title('Randomly Selected Head Rotation Trials')
    xlabel('time')
    ylabel('degrees')
end

% look at the distributuion of the head rotation
if false
    head_rotation = abs(head_rotation);
    ind = head_rotation > 100;
    head_rotation(ind) = nan;
    figure
    targMean = mean(head_rotation(stimulus_type==1,:),1,'omitnan');
    targStd = std(head_rotation(stimulus_type==1,:),1,'omitnan');
    distMean = mean(head_rotation(stimulus_type==0,:),1,'omitnan');
    distStd = std(head_rotation(stimulus_type==0,:),1,'omitnan');
    t = linspace(-500,1500,size(head_rotation,2));    
    H1 = shadedErrorBar(t,targMean,targStd,'b',1);
    hold on
    H2 = shadedErrorBar(t,distMean,distStd,'r',1);
    legend([H1.mainLine, H2.mainLine], 'targets', 'distractors', 'Location', 'SouthWest')
    title('Head Rotation Distributions with Standard Deviation')
    xlabel('Time')
    ylabel('Degrees')
end

% look at the dwell-times cumulative histogram
if false
    nTarg = sum(stimulus_type==1);
    nDist = sum(stimulus_type==0);
    targCumHist = cumsum(hist(dwell_times(stimulus_type==1),1500),'reverse')/nTarg;
    distCumHist = cumsum(hist(dwell_times(stimulus_type==0),1500),'reverse')/nDist;
    figure
    t = linspace(0,1500,1500);
    plot(t,targCumHist)
    hold on
    plot(t,distCumHist)
    legend('targets','distractors')
    title('Dwell-Times Cumulative Histogram')
    xlabel('time')
    ylabel('Fraction of trials with dwell time > t')
end

% look at the dwell-times histograms
if false
    figure
    h1 = histogram(dwell_times(stimulus_type==0),50)
    h1.FaceColor = 'r';
    hold on
    h2 = histogram(dwell_times(stimulus_type==1),50)
    h2.FaceColor = 'b';
    legend('distractors','targets')
    title('Dwell-Times Histogram')
    xlabel('Dwell Time')
    ylabel('Count')
end

% look at the dwell-times scatter plots
if false
    figure
    plot(dwell_times(stimulus_type==1),'*')
    hold on
    plot(dwell_times(stimulus_type==0),'*')
    xlabel('count')
    ylabel('dwell-time')
    title('Dwell-Times Scatter Plot')
    legend('targets','distractors')
end

% look at the ERPs
if false
    eeg_epoched = EEG;
    ylim = [-30,30];
    EEGTarg = pop_importdata('setname','targets','data',eeg_epoched(:,:,stimulus_type==1),'chanlocs','biosemi_64.ced','xmin',-.5,'srate',256);
    EEGDist = pop_importdata('setname','distractors','data',eeg_epoched(:,:,stimulus_type==0),'chanlocs','biosemi_64.ced','xmin',-.5,'srate',256);
    ALLEEG = [EEGTarg, EEGDist];
    pop_comperp(ALLEEG,1,1,2,'ylim',ylim,'title','Targets-Distractors','addavg','on','subavg','on','diffavg','on');
    EEGMeanDiff = mean(EEGTarg.data,3)-mean(EEGDist.data,3);
    EEGMeanDiff = pop_importdata('setname','diff','data',EEGMeanDiff,'chanlocs','biosemi_64.ced','xmin',-.5,'srate',256);
    pop_topoplot(EEGMeanDiff,1,[0,100,200,300,400,500,600,1000],'Targets - Distractors');
    pop_topoplot(EEGTarg,1,[0,100,200,300,400,500,600,700,1000],'Targets');
    pop_topoplot(EEGDist,1,[0,100,200,300,400,500,600,700,1000],'Distractors');
end

disp('done')