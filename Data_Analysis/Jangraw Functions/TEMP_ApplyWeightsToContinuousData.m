% TEMP_ApplyWeightsToContinuousData.m
%
% Created 10/31/13 by DJ.

%% Load & set up
load TEMP_HybridClassifier_Results R_eegpsdt

subjects = [22:30 32];
sessions_cell = {2:14, [3 6:17], 1:15, 1:15, 1:15, 1:15, 1:15, 1:15, [1:10 12:15], 2:16};
offsets = [-12 -4 48 60 68 68 92 112 -32 88];
% cvmode = '10fold';
nSubjects = numel(subjects);

%%

iSubj = 10;
subject = subjects(iSubj);
sessions = sessions_cell{iSubj};
offset = offsets(iSubj);
w = mean(mean(R_eegpsdt(iSubj).w,4),3); % ic x bin
v = mean(mean(R_eegpsdt(iSubj).v,4),3); % 1 x bin+psbin+dt

%% Load EEG and behavior structs
y = loadBehaviorData(subject,sessions,'3DS');
EEG = pop_loadset('filename',...
    sprintf('3DS-%d-all-filtered-noduds-noeog-epoched-ica.set',subject));

%% Get eye pos and pupil size
[ps,xeye,yeye] = deal(cell(1,numel(sessions)));
for i=1:numel(sessions)        
    load(sprintf('3DS-%d-%d-eyepos',subject,sessions(i)));
    xeye{i} = eyepos(:,1);
    yeye{i} = eyepos(:,2);
    ps{i} = InterpolateBlinks(pupilsize,y(i).eyelink.record_time-1+(1:length(pupilsize)),y(i));
end
% Normalize pupil size to be percentage change
mean_ps = nanmean(cat(1,ps{:}));
ps_pct = ps;
for i=1:numel(sessions)
    ps_pct{i} = ps{i}/mean_ps*100;
end

%% Find saccade times


%% Apply classifier

%%%%% PICK FEATURES %%%%%
useEEG = 0;
usePS = 1;
useDT = 0;
%%%%%%%%%%%%%%%%%%%%%%%%%

% Declare PS bins
tBaseline = [-1000 0];%[0 100];
binwidth = 500; % in ms
binstart = 0:500:2500; % in ms

nEegBins = 9;
v_ps = v(nEegBins+(1:numel(binstart)));
tRange = [min([tBaseline,binstart]), max(binstart+binwidth)];
t = tRange(1):tRange(2);
pskernel = zeros(length(t),1); 
for i=1:numel(binstart);
    isInWin = t>=binstart(i) & t<(binstart(i)+binwidth);
    pskernel(isInWin) = v_ps(i)/sum(isInWin); % multiply avg by v_ps(i)
end
isInBaseline = t>=tBaseline(1) & t<tBaseline(2);
pskernel(isInBaseline) = -sum(v_ps)/sum(isInBaseline);

%%
ps_y = cell(1,numel(ps));
for i=1:numel(sessions)
    fprintf('session %d/%d...\n',i,numel(sessions))
    ps_y{i} = conv(ps_pct{i},pskernel,'same');
end
%%
clf;
objIsTarget = cell(1,numel(sessions));
objY = cell(1,numel(sessions));
for i=1:numel(sessions)
    subplot(5,3,i)
    cla; hold on;
    plot(ps_pct{i});
    plot((1:length(ps_y{i})) - t(1), ps_y{i},'g');
    plot(get(gca,'xlim'),[0 0],'k-');
    PlotVerticalLines(y(i).eyelink.saccade_times - y(i).eyelink.record_time + 1,'k:');
    sacToObjTimes = y(i).eyelink.saccade_events(:,1) - y(i).eyelink.record_time + 1;
    iObjs = y(i).eyelink.saccade_events(:,2);
    objIsTarget{i} = strcmp('TargetObject',{y(i).objects(iObjs).tag});
    objY{i} = ps_y{i}(sacToObjTimes + t(1));
    PlotVerticalLines(sacToObjTimes(~objIsTarget{i}),'b');
    PlotVerticalLines(sacToObjTimes(objIsTarget{i}),'r');
end
y_new = cat(1,objY{:})';
truth_new = [objIsTarget{:}];