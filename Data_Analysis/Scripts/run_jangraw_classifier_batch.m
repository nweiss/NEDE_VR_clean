% Runs the Jangraw hybrid classifier on the VR NEDE data.
% Generates classifications from each modality seperately and then a
% combined classification as well. The four modalities are EEG, pupil
% dilation, head-rotation, and dwell time.

close all; clc; clear all;

%% Settings
DATA_VERSION_NO = '6'; % version of the stored data
nFolds = 10;
SAVE_ON = false;

%% Paths
DIR = fullfile('..','..','NEDE_Online');
addpath(genpath(DIR));

%% Load Data
LOAD_PATH = fullfile('..','..','..','Dropbox','NEDE_Dropbox','Data',['training_v',DATA_VERSION_NO],'training_data.mat');
load(LOAD_PATH);

%% Misc
% For data version 4: Update the format of the data so each subject has its own cell array
if strcmp(DATA_VERSION_NO, '4')
    [billboard_cat,block,dwell_times,EEG,head_rotation,pupil,stimulus_type,subject,target_category] = array2cell(billboard_cat,block,dwell_times,EEG,head_rotation,pupil,stimulus_type,subject,target_category);
end
    
%% Main
nSubjects = numel(subject);
subjects = 1:nSubjects;

for i = subjects
%Use the absolute value of head rotation
head_rotation = abs(head_rotation);

% Update the stimulus type so that (0=distractor,1=target)
stimulus_type = convertLabels(stimulus_type);

% Shuffle the trials prior to partitioning them into training/testing sets
% shuffleMap = cell(max(SUBJECTS),1);
% for i = 1:8
%     rng(i);
%     shuffleMap{i} = randperm(nTrials(i));
%     
%     billboard_cat{i}=billboard_cat{i}(shuffleMap{i});
%     block{i}=block{i}(shuffleMap{i});
%     dwell_times{i}=dwell_times{i}(shuffleMap{i});
%     EEG{i}=EEG{i}(:,:,shuffleMap{i});
%     head_rotation{i}=head_rotation{i}(shuffleMap{i},:);
%     pupil{i}=pupil{i}(shuffleMap{i},:);
%     stimulus_type{i}=stimulus_type{i}(shuffleMap{i});
%     target_category{i}=target_category{i}(shuffleMap{i});
% end

% Keep trials from only one day of experiment
% blocksToKeep = (28:42);
% trialsToDel = ~ismember(block{8},blocksToKeep);
% billboard_cat{i}(trialsToDel) = [];
% block{i}(trialsToDel)=[];
% dwell_times{i}(trialsToDel)=[];
% EEG{i}(:,:,trialsToDel)=[];
% head_rotation{i}(trialsToDel,:)=[];
% pupil{i}(trialsToDel,:)=[];
% stimulus_type{i}(trialsToDel)=[];
% target_category{i}(trialsToDel)=[];

%% HDCA classifier
cvmode = [num2str(nFolds),'fold'];
level2data = [];
fwdModelData = [];

dwell_level1 = cell(max(SUBJECTS),1);
EEG_level1 = cell(max(SUBJECTS),1);
pupil_level1 = cell(max(SUBJECTS),1);
headrotation_level1 = cell(max(SUBJECTS),1);

v_dwell = cell(max(SUBJECTS),1);
v_EEG = cell(max(SUBJECTS),1);
v_pupil = cell(max(SUBJECTS),1);
v_headrotation = cell(max(SUBJECTS),1);
v_comb = cell(max(SUBJECTS),1);

Az.dwell = nan(max(SUBJECTS),1);
Az.dwell_v2 = nan(max(SUBJECTS),1);
Az.EEG = nan(max(SUBJECTS),1);
Az.pupil = nan(max(SUBJECTS),1);
Az.headrotation = nan(max(SUBJECTS),1);
Az.comb = nan(max(SUBJECTS),1);

ROC_x_dt1 = cell(max(SUBJECTS),1);
ROC_y_dt1 = cell(max(SUBJECTS),1);
ROC_x_pup = cell(max(SUBJECTS),1);
ROC_y_pup = cell(max(SUBJECTS),1);
ROC_x_hr = cell(max(SUBJECTS),1);
ROC_y_hr = cell(max(SUBJECTS),1);
ROC_x_eeg = cell(max(SUBJECTS),1);
ROC_y_eeg = cell(max(SUBJECTS),1);
ROC_x_comb = cell(max(SUBJECTS),1);
ROC_y_comb = cell(max(SUBJECTS),1);

level1_comb = cell(max(SUBJECTS),1);
y_comb = cell(max(SUBJECTS),1);

for i = SUBJECTS
    nTrials = length(dwell_times{i});
    cv = setCrossValidationStruct(cvmode,nTrials);
    
    % Dwell Time
    trainingwindowlength = 1;
    trainingwindowoffset = [1];
    dwell_times{i} = permute(dwell_times{i}, [3,1,2]);
    [y_dt,~,~,~,dwell_level1{i},ROC_x_dt1{i},ROC_y_dt1{i},~,Az.dwell(i)] = RunHybridHdcaClassifier2(dwell_times{i},stimulus_type{i},trainingwindowlength,trainingwindowoffset,cvmode);
    [X_dt2,Y_dt2,T_dt2,Az.dwell_v2(i)] = perfcurve(squeeze(stimulus_type{i}), squeeze(squeeze(dwell_times{i})), 0);
    
    % Pupil
    trainingwindowlength = .5*60; % half a second at 60 herz
    trainingwindowoffset = (1*60:trainingwindowlength:4*60-trainingwindowlength);
    pupil{i} = permute(pupil{i}, [3,2,1]);
    [y_pup,w,v_pupil{i},fwdModel,pupil_level1{i},ROC_x_pup{i},ROC_y_pup{i},T_pup,Az.pupil(i)] = RunHybridHdcaClassifier2(pupil{i},stimulus_type{i},trainingwindowlength,trainingwindowoffset,cvmode);
    
    % Head Rotation
    trainingwindowlength = floor(.25*75); % quarter second at 75 herz
    trainingwindowoffset = (floor(.5*75):trainingwindowlength:2*75-trainingwindowlength);
    head_rotation{i} = permute(head_rotation{i}, [3,2,1]);
    [y_hr,w,v_headrotation{i},fwdModel,headrotation_level1{i},ROC_x_hr{i},ROC_y_hr{i},T_hr,Az.headrotation(i)] = RunHybridHdcaClassifier2(head_rotation{i},stimulus_type{i},trainingwindowlength,trainingwindowoffset,cvmode);
    
    % EEG
    trainingwindowlength = 25;
    trainingwindowoffset = (153:25:385-25);
    [y_eeg,w,v_EEG{i},fwdModel,EEG_level1{i},ROC_x_eeg{i},ROC_y_eeg{i},T_eeg,Az.EEG(i)] = RunHybridHdcaClassifier2(EEG{i},stimulus_type{i},trainingwindowlength,trainingwindowoffset,cvmode);
    
    % Combined Model
    trainingwindowlength = 1;
    trainingwindowoffset = 1;
    level1_comb{i} = cat(2, EEG_level1{i}, pupil_level1{i}, headrotation_level1{i});
    [y_comb{i},w,v_comb{i},fwdModel,EEG_level1{i},ROC_x_comb{i},ROC_y_comb{i},T_comb,Az.comb(i)] = RunHybridHdcaClassifier2(dwell_times{i},stimulus_type{i},trainingwindowlength,trainingwindowoffset,cvmode, level1_comb{i});

end

Az.dwell(3) = [];
Az.dwell_v2(3) = [];
Az.EEG(3) = [];
Az.pupil(3) = [];
Az.headrotation(3) = [];
Az.comb(3) = [];

figure
plot((1:max(SUBJECTS)-1),Az.dwell,'-*')
hold on
plot((1:max(SUBJECTS)-1),Az.EEG,'-*')
hold on
plot((1:max(SUBJECTS)-1),Az.headrotation,'-*')
hold on
plot((1:max(SUBJECTS)-1),Az.pupil,'-*')
hold on
plot((1:max(SUBJECTS)-1),Az.comb,'-*')
legend('dwell','EEG','headrotation','pupil','combined')
xlabel('subject')
ylabel('AUC')
title('Various Models')
ylim([0,1])
grid on

figure
plot((1:max(SUBJECTS)-1),Az.dwell_v2,'-*')
hold on
plot(1:max(SUBJECTS)-1,Az.dwell,'-*')
xlabel('subject')
ylabel('AUC')
legend('dwell from HDCA', 'raw dwell')
title('dwell processing comparisons')
ylim([0,1])
grid on

% plot ROC curves
figure
subplot(2,3,1)
plot(ROC_x_dt1{DISPLAY_SUBJ},ROC_y_dt1{DISPLAY_SUBJ})
title('dwell time')
subplot(2,3,2)
plot(ROC_x_pup{DISPLAY_SUBJ},ROC_y_pup{DISPLAY_SUBJ})
title('pupil')
subplot(2,3,3)
plot(ROC_x_hr{DISPLAY_SUBJ},ROC_y_hr{DISPLAY_SUBJ})
title('head rotation')
subplot(2,3,4)
plot(ROC_x_eeg{DISPLAY_SUBJ},ROC_y_eeg{DISPLAY_SUBJ})
title('EEG')
subplot(2,3,5)
plot(ROC_x_comb{DISPLAY_SUBJ},ROC_y_comb{DISPLAY_SUBJ})
title('combined')

% calculate precision of predicted targets
precision = zeros(max(SUBJECTS),1);
for i = SUBJECTS
    nTrials = numel(y_comb{i});
    nPredTarg = floor(nTrials/4);
    [tmp,ind_pred_targ] = sort(y_comb{i}, 'descend');
    truth_of_pred_targ = stimulus_type{i}(ind_pred_targ(1:nPredTarg));
    precision(i) = sum(truth_of_pred_targ==1)/nPredTarg;
end
precision(3) = [];
figure
plot(precision)
hold on
plot([1,7],[.25,.25], '--k')
legend('precision','chance')
title('precision')
xlabel('subject')
ylabel('precision')
ylim([0,1])

disp('done')