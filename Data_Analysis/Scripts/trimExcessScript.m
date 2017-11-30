% In an older version of the NEDE_online script, we saved all of the EEG
% data together with a lot of trailing zeros leftover from the initialization of the
% variable. This script deletes those trailing zeros.

close all; clc; clear all;

% Settings
SAVE_ON = true;
SUBJECT_NUM = 10;
BLOCK_NUM = 1;

LOAD_PATH = fullfile('..','..','Data','raw_mat',['subject_',num2str(SUBJECT_NUM)],['s',num2str(SUBJECT_NUM),'_b',num2str(BLOCK_NUM),'_raw.mat']);
SAVE_PATH = fullfile('..','..','Data','raw_mat',['subject_',num2str(SUBJECT_NUM)],['s',num2str(SUBJECT_NUM),'_b',num2str(BLOCK_NUM),'_trimmed.mat']);
load(LOAD_PATH);

FUNC_PATH = fullfile('..','Functions');
addpath(FUNC_PATH)

%% Trim off end of the data
[eeg.time_series,eeg.time_stamps] = trimExcess(eeg.time_series,eeg.time_stamps);
[unity.time_series,unity.time_stamps] = trimExcess(unity.time_series,unity.time_stamps);
[eye.time_series,eye.time_stamps] = trimExcess(eye.time_series,eye.time_stamps);

if SAVE_ON
    save(SAVE_PATH,'eye','eeg','unity');
    disp('Data Saved!')
end