close all; clc; clear all;
DATA_VERSION_NO = '4';
SUBJECT_NO = '8';

HDCA_DIR = fullfile('..', 'HDCA');
addpath(genpath(HDCA_DIR));
HDCA_DIR = fullfile('..', 'Jangraw Functions');
addpath(genpath(HDCA_DIR));

%% Load data and change the format so each subject has its own cell array
LOAD_PATH = fullfile('..', 'Data', ['training_v', DATA_VERSION_NO], 'training_data.mat');
load(LOAD_PATH);

billboard_cat_tmp = billboard_cat;
block_tmp = block;
dwell_times_tmp = dwell_times;
EEG_tmp = EEG;
head_rotation_tmp = head_rotation;
pupil_tmp = pupil;
stimulus_type_tmp = stimulus_type;
subject_tmp = subject;
target_category_tmp = target_category;
clear 'billboard_cat' 'block' 'dwell_times' 'EEG' 'head_rotation' 'pupil' 'stimulus_type' 'subject' 'target_category'

billboard_cat = cell(8,1);
block = cell(8,1);
dwell_times = cell(8,1);
EEG = cell(8,1);
head_rotation = cell(8,1);
pupil = cell(8,1);
stimulus_type = cell(8,1);
subject = cell(8,1);
target_category = cell(8,1);

for i = 1:8
    billboard_cat{i} = billboard_cat_tmp(subject_tmp == i);
    block{i} = block_tmp(subject_tmp == i);
    dwell_times{i} = dwell_times_tmp(subject_tmp == i);
    EEG{i} = EEG_tmp(:,:,subject_tmp == i);
    head_rotation{i} = head_rotation_tmp(subject_tmp == i,:);
    pupil{i} = pupil_tmp(subject_tmp == i,:);
    stimulus_type{i} = stimulus_type_tmp(subject_tmp == i);
    subject{i} = subject_tmp(subject_tmp == i);
    target_category{i} = target_category_tmp(subject_tmp == i);
end

%% Pass Pupil and Head Rotation Data to RunHybridHdcaClassifier.m
% i = 8;
% trainingwindowlength = .5 * 60; %500 ms bins. eye tracker at 60 Hz.
% trainingwindowoffset = (60:trainingwindowlength:size(pupil{8},2)-trainingwindowlength);
% cvmode = '5fold';
% data = pupil{i};
% data = reshape(data, [1, size(data,2), size(data, 1)]);
% 
% %[y, y_level1] = RunPupilHeadrot(pupil{i}, stimulus_type{i}, trainingwindowlength, trainingwindowoffset, cvmode);
% [y, w, v, fwdModel, y_level1] = RunHybridHdcaClassifier(data, stimulus_type{i}, trainingwindowlength, trainingwindowoffset, cvmode);

%% Pass Dwell-Time Data to RunHybridHdcaClassifier.m


%%
% clear all; clc; close all;
% addpath('../Jangraw Functions');
% 
% sample = rand(100,5);
% truth = round(rand(1000,1));
% data = rand(1000,241);
% [Az, v] = ClassifyWithOcularFeatures(truth, data);
