%convert data from the eeg_data and eeg_ts format to eeg.time_stamps and
%eeg.time_series

clear all; clc; close all; 
SUBJECT = '4';
BLOCK = '13';
LOAD_PATH = fullfile('Data', ['subject_' SUBJECT],['raw_', BLOCK, '.mat']);
SAVE_PATH = fullfile('Data', ['subject_' SUBJECT],['s', SUBJECT, '_b', BLOCK, '_raw.mat']);

load(LOAD_PATH);

eeg.time_series = [zeros(1,length(eeg_ts)); eeg_data];
eeg.time_stamps = eeg_ts;
unity.time_series = unity_data;
unity.time_stamps = unity_ts;
eye.time_series = eye_data;
eye.time_stamps = eye_ts;

save(SAVE_PATH);
disp('done');