% ClassifyWithOcularFeatures_script.m
%
% Created 8/14/13 by DJ for one-time use.

%% Set up
subjects = [22:30 32];
sessions_cell = {2:14, [3 6:17], 1:15, 1:15, 1:15, 1:15, 1:15, 1:15, [1:10 12:15], 2:16};
offsets = [-12 -4 48 60 68 68 92 112 -32 88];
cvmode = '10fold';
nSubjects = numel(subjects);
%% Get eye pos features
[dwell_time, sac_size, sac_speed, fixtime_max, fixtime_mean, nsac, fixtime_first] = GetVariousEyeFeatures(subjects,sessions_cell);
bigEyeFeature = AppendFeatures(dwell_time, sac_size, sac_speed, fixtime_max, fixtime_mean, nsac, fixtime_first);
%% Classify Eyepos Features

Az_eye(1,:) = ClassifyWithOcularFeatures({R.truth},dwell_time);
Az_eye(2,:) = ClassifyWithOcularFeatures({R.truth},sac_size);
Az_eye(3,:) = ClassifyWithOcularFeatures({R.truth},sac_speed);
Az_eye(4,:) = ClassifyWithOcularFeatures({R.truth},fixtime_max);
Az_eye(5,:) = ClassifyWithOcularFeatures({R.truth},fixtime_mean);
Az_eye(6,:) = ClassifyWithOcularFeatures({R.truth},nsac);
Az_eye(7,:) = ClassifyWithOcularFeatures({R.truth},fixtime_first);
Az_eye(8,:) = ClassifyWithOcularFeatures({R.truth},bigEyeFeature);

%% Plot Eyepos Features
clf
PlotUniqueLines([],Az_eye(:,order)','.')
% plot(Az_eye(:,order)','.-')
hold on
plot([0 11],[0.5 0.5],'k--','linewidth',2)
xlim([0 11])
ylim([0.3 1])
legend('dt','sacsize','sacspeed','max tfix','mean tfix','nfix','first tfix','Hybrid','Location','NorthWest')
title('Eye Features')
xlabel('Subject (sorted by EEG Az)')
ylabel('AUC')




%% Get Pupil Features
[ps_bin, ps_max, ps_latency, ps_deriv] = GetVariousPupilFeatures(ps_all,t_epoch,binstart,binwidth);
bigPupFeature = AppendFeatures(ps_bin, ps_max, ps_latency, ps_deriv);
%% Classify Pupil Features

Az_pup(1,:) = ClassifyWithOcularFeatures({R.truth},ps_bin);
Az_pup(2,:) = ClassifyWithOcularFeatures({R.truth},ps_max);
Az_pup(3,:) = ClassifyWithOcularFeatures({R.truth},ps_latency);
Az_pup(4,:) = ClassifyWithOcularFeatures({R.truth},ps_deriv);
Az_pup(5,:) = ClassifyWithOcularFeatures({R.truth},bigPupFeature);

%% Plot Pupil Features
clf
plot(Az_pup(:,order)','.-')
hold on
plot([0 11],[0.5 0.5],'k--','linewidth',2)
xlim([0 11])
ylim([0.3 1])
legend('pd','pd max','pd latency','pd deriv','Hybrid','Location','NorthEast')
title('Pupil Features')
xlabel('Subject (sorted by EEG Az)')
ylabel('AUC')



%% Combine all eye and pupil measures
bigFeature = AppendFeatures(bigEyeFeature,bigPupFeature);

Az_eyepup(1,:) = ClassifyWithOcularFeatures({R.truth},bigEyeFeature);
Az_eyepup(2,:) = ClassifyWithOcularFeatures({R.truth},bigPupFeature);
Az_eyepup(3,:) = ClassifyWithOcularFeatures({R.truth},bigFeature);

%% Plot Pupil Features
clf
plot(Az_eyepup(:,order)','.-')
hold on
plot([0 11],[0.5 0.5],'k--','linewidth',2)
xlim([0 11])
ylim([0.3 1])
legend('All EyePos features','All Pupil features','Hybrid','Location','NorthEast')
title('Combined Eye + Pupil Features')
xlabel('Subject (sorted by EEG Az)')
ylabel('AUC')


%% Try hybrid classifiers with EEG
useEEG = 1;
for i=1:numel(subjects)
    fprintf('-----------------------------\n');
    fprintf('--- Subject %d/%d ---\n',i,numel(subjects));
    load(sprintf('ALLEEG%d_NoeogEpochedIcaCropped.mat',subjects(i))); % ALLEEG
    y = loadBehaviorData(subjects(i),sessions_cell{i},'3DS');
    R_eegeye(i) = ClassifyWithEegAndDwellTime(ALLEEG,y,cvmode,offsets(i),bigEyeFeature{i},useEEG);
    R_eegpup(i) = ClassifyWithEegAndDwellTime(ALLEEG,y,cvmode,offsets(i),bigPupFeature{i},useEEG);
    R_eegeyepup(i) = ClassifyWithEegAndDwellTime(ALLEEG,y,cvmode,offsets(i),bigFeature{i},useEEG);
end

%%
Az_eegeyepup(1,:) = [R_eeg.Az];
Az_eegeyepup(2,:) = [R_eegeye.Az];
Az_eegeyepup(3,:) = [R_eegpup.Az];
Az_eegeyepup(4,:) = [R_eegeyepup.Az];
Az_eegeyepup(5,:) = [R_eegpsdt.Az];

%% Plot EEG-hybrid classifiers
clf
plot(Az_eegeyepup(:,order)','.-')
hold on
plot([0 11],[0.5 0.5],'k--','linewidth',2)
xlim([0 11])
ylim([0.3 1])
legend('EEG',' EEG + All EyePos features','EEG + All Pupil features','Hybrid','Old Hybrid','Location','NorthEast')
title('Combined EEG + Eye + Pupil Features')
xlabel('Subject (sorted by EEG Az)')
ylabel('AUC')

%% Get mean weights from uber-hybrid classifier
featurenames = {'EEG(100)','EEG(200)','EEG(300)','EEG(400)','EEG(500)','EEG(600)','EEG(700)','EEG(800)','EEG(900)',...
    'dt','sacsize','sacspeed','max tfix','mean tfix','nfix', 'first tfix',...
    'pd(0)','pd(500)','pd(1000)','pd(1500)','pd(2000)','pd(2500)','pd max','pd latency','pd''(0)','pd''(500)','pd''(1000)','pd''(1500)','pd''(2000)','pd''(2500)'};

eeg_feats = find(strncmp('EEG',featurenames,3));
pd_feats = find(strncmp('pd(',featurenames,3));
dpdt_feats = find(strncmp('pd''',featurenames,3));
% featurenames = {'EEG(100)','EEG(200)','EEG(300)','EEG(400)','EEG(500)','EEG(600)','EEG(700)','EEG(800)','EEG(900)',...
%     'dt','pd(0)','pd(500)','pd(1000)','pd(1500)','pd(2000)','pd(2500)'};


v_raw = cat(4,R_eegeyepup.v);
% v_raw = cat(4,R_eegpsdt.v);
v = mean(mean(v_raw,3),4);
stderr_v = std(mean(v_raw,3),[],4)/sqrt(nSubjects);
nFeats = length(v);

%% Get stats on these weights
v_subjmean = squeeze(mean(v_raw,3));
p = nan(1,nFeats);
for i=1:nFeats
%     p(i) = signrank(v_subjmean(i,:),0); % two-tailed test
    [~,p(i)] = ttest(v_subjmean(i,:),0,0.05,'right'); % one-tailed test
end
% convert to one-tailed test (v>0)
% p = p/2;
% p(median(v_subjmean,2)<0) = 1;

%% plot weights and which ones are significantly above zero
clf;
set(gcf,'Position',[4 1114 2562 370]);
hold on
cutoffs = [0.05, 0.01, 0.005, 0.001];
% ONESTAR_CUTOFF = 0.05; % p value cutoff
% TWOSTAR_CUTOFF = 0.01; % p value cutoff
% THREESTAR_CUTOFF = 0.005; % p value cutoff
% FOURSTAR_CUTOFF = 0.001; % p value cutoff

errorbar(1:nFeats,v,stderr_v,'.')

% plot(find(p<THREESTAR_CUTOFF),v(p<THREESTAR_CUTOFF),'co','linewidth',2,'Markersize',8);
% plot(find(p<TWOSTAR_CUTOFF),v(p<TWOSTAR_CUTOFF),'go','linewidth',2,'Markersize',8);
% plot(find(p<ONESTAR_CUTOFF),v(p<ONESTAR_CUTOFF),'ro','linewidth',2,'Markersize',8);
% plot(p,'r.-')

colors = 'rgcmyk';
legendstr = cell(1,numel(cutoffs));
for i=numel(cutoffs):-1:1 % reverse order for legend purposes
    height = .03*i-.02;
    plot([-1 find(p<cutoffs(i))],ones([1 sum(p<cutoffs(i))+1])*height,[colors(i) '^'],'linewidth',2,'Markersize',6);
    legendstr{end-i+1} = sprintf('p<%g',cutoffs(i));
end
% plot([-1 find(p<FOURSTAR_CUTOFF)],ones([1 sum(p<FOURSTAR_CUTOFF)+1])*0.1,'m^','linewidth',2,'Markersize',6);
% plot([-1 find(p<THREESTAR_CUTOFF)],ones([1 sum(p<THREESTAR_CUTOFF)+1])*0.07,'c^','linewidth',2,'Markersize',6);
% plot([-1 find(p<TWOSTAR_CUTOFF)],ones([1 sum(p<TWOSTAR_CUTOFF)+1])*0.04,'g^','linewidth',2,'Markersize',6);
% plot([-1 find(p<ONESTAR_CUTOFF)],ones([1 sum(p<ONESTAR_CUTOFF)+1])*0.01,'r^','linewidth',2,'Markersize',6);

% Put lines between connected features
plot(eeg_feats,v(eeg_feats),'-')
plot(pd_feats,v(pd_feats),'-')
plot(dpdt_feats,v(dpdt_feats),'-')

plot([0 nFeats+1],[0 0],'k--','linewidth',2)
xlim([0 nFeats+1])
set(gca,'xtick',1:length(v),'xticklabel',featurenames)
% xticklabel_rotate(1:length(v),45,featurenames)
legend([{'Weights'},legendstr]);
% legend('Weights',sprintf('p<%g',FOURSTAR_CUTOFF),sprintf('p<%g',THREESTAR_CUTOFF),sprintf('p<%g',TWOSTAR_CUTOFF),sprintf('p<%g',ONESTAR_CUTOFF))
xlabel('Feature')
ylabel('Feature Weight')
title('Hybrid Classifier weights and (uncorrected) p values')