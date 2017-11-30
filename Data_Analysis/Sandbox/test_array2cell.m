close all; clc; clear all;

DATA_VERSION_NO = '4';
SUBJECT_NO = '8';

DIR = fullfile('..', '..', 'NEDE_Online');
addpath(genpath(DIR));

%% Load data and change the format so each subject has its own cell array
LOAD_PATH = fullfile('..', 'Data', ['training_v', DATA_VERSION_NO], 'training_data.mat');
load(LOAD_PATH);

[billboard_cat, block, dwell_times, EEG, head_rotation, pupil, stimulus_type, subject, target_category] = array2cell(billboard_cat, block, dwell_times, EEG, head_rotation, pupil, stimulus_type, subject, target_category)