% Perform dimensionality reduction on continuous (non-epoched) EEG data.
close all; clc; clear all;

% Settings
SAVE_ON = false;
INCLUDE_HR_ICA = false; % Append head rotation data to EEG data prior to taking ICA
SUBJECT_NUM = 10;
BLOCK_NUM = 1;

LOAD_PATH = fullfile('..','..','Data','raw_mat',['subject_',num2str(SUBJECT_NUM)],['s',num2str(SUBJECT_NUM),'_b',num2str(BLOCK_NUM),'_raw.mat']);
SAVE_PATH = fullfile('..','..','Data','reduced_dims',['subject_',num2str(SUBJECT_NUM)],['s',num2str(SUBJECT_NUM),'_b',num2str(BLOCK_NUM),'_dr.mat']);
load(LOAD_PATH);


%% Filter Data


%% PCA
disp('Running PCA...')
[coeff,score,latent,tsquared,explained,mu] = pca(eeg.time_series','NumComponents',20);

disp('Done')