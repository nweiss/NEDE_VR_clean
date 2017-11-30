close all; clc; clear all;

% Settings
DATA_VERSION_NO = '4'; % version of the stored data
SUBJECTS = [1,2,4,5,6,7,8];

DIR = fullfile('..','..','NEDE_Online');
addpath(genpath(DIR));

savepath = fullfile('..','Data', 'training_v5', 'training_data.mat');

% Format the data so each subject has its own cell array
LOAD_PATH = fullfile('..','Data',['training_v',DATA_VERSION_NO],'training_data.mat');
load(LOAD_PATH);
[billboard_cat,block,dwell_times,EEG,head_rotation,pupil,stimulus_type,subject,target_category] = array2cell(billboard_cat,block,dwell_times,EEG,head_rotation,pupil,stimulus_type,subject,target_category);

EEG_ic = cell(max(SUBJECTS),1);
for subj = SUBJECTS;
% Reshape the EEG data such that each trial is appended to the previous
% trial along the dimension of time
EEG_reshaped = [];
for i = 1:size(EEG{subj},3)
    EEG_reshaped = cat(2, EEG_reshaped, EEG{subj}(:,:,i));
end

% PCA
[coeff, EEG_pcs] = pca(EEG_reshaped');
EEG_pcs = EEG_pcs(:,1:20)'; % Keep 20 pcs

% Put the EEG data back into its original shape
EEG_pc_epoched = [];
counter1 = 1;
counter2 = size(EEG{subj},2);
for i = 1:size(EEG{subj},3)
    EEG_pc_epoched = cat(3, EEG_pc_epoched, EEG_pcs(:,counter1:counter2));
    counter1 = counter1+size(EEG{subj},2);
    counter2 = counter2+size(EEG{subj},2);
end

% Run ICA
EEG_lab = pop_importdata('data', 'EEG_pc_epoched', 'dataformat', 'array');
EEG_ica = pop_runica(EEG_lab, 'icatype', 'runica');
% https://sccn.ucsd.edu/pipermail/eeglablist/2013/006954.html
EEG_ica.icaact = (EEG_ica.icaweights*EEG_ica.icasphere)*EEG_ica.data(EEG_ica.icachansind,:);

% Put IC projected data back into its original shape
EEG_ic_epoched = [];
counter1 = 1;
counter2 = size(EEG{subj},2);
for i = 1:size(EEG{subj},3)
    EEG_ic_epoched = cat(3, EEG_ic_epoched, EEG_ica.icaact(:,counter1:counter2));
    counter1 = counter1+size(EEG{subj},2);
    counter2 = counter2+size(EEG{subj},2);
end

EEG_ic{subj} = EEG_ic_epoched;

disp(['finished subject ', num2str(subj)]);
end
EEG = EEG_ic;
save(savepath, 'EEG', 'billboard_cat', 'block', 'dwell_times', 'head_rotation', 'pupil', 'stimulus_type', 'subject', 'target_category');

disp('done');