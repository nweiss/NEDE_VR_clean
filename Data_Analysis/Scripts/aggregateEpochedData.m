% This script takes in data that is epoched for each block of each subject
% and aggregates it into one large .mat file containing all the data as 
% well as which subject and block it came from.
clear all; clc; close all;

%% SETTINGS
DATA_VERSION_NO = '6';
SAVE_ON = true;

% Number of blocks recorded for each subject
BLOCKS = [13,9,0,13,16,33,23,42,0,39,40,0,40];
SUBJECTS = 13; %[1,2,4,5,6,7,8];

% Delete trials with extreme head rotation values. This happens occasionaly
% on the last stimulus of a block if the game exits before the end of the
% epoch.
DELETE_EXT_HEAD_ROT = false;  

% Delete trials that include an EEG value over a certain threshold. Happens
% with bad electrodes.
DELETE_EXT_EEG = false;
threshold = 750;

%% PATHS
ERROR_BAR_PATH = fullfile('..', 'dependancies', 'shadedErrorBar');
addpath(ERROR_BAR_PATH);

FUNCTION_PATH = fullfile('..','Functions');
addpath(FUNCTION_PATH);

%% Main Script
dwell_times_agg = [];
EEG_agg = [];
head_rotation_agg = [];
pupil_agg = [];
stimulus_type_agg = [];
billboard_cat_agg = [];
target_category_agg = [];
subject = [];
block = [];

for i = 13% SUBJECTS
    for j = 1:BLOCKS(i)
        clear dwell_time
        clear eeg
        clear head_rotation
        clear pupil
        clear stimulus_type
        clear billboard_cat
        clear target_category
        
        LOAD_PATH = fullfile('..','..','..','Dropbox','NEDE_Dropbox',...
            'Data', ['epoched_v' DATA_VERSION_NO], ['subject_', num2str(i)],...
            ['s', num2str(i), '_b', num2str(j), '_epoched.mat']);
        load(LOAD_PATH);
        
        dwell_times_agg = cat(2, dwell_times_agg, dwell_times);
        EEG_agg = cat(3, EEG_agg, EEG);
        head_rotation_agg = cat(1, head_rotation_agg, head_rotation);
        pupil_agg = cat(1, pupil_agg, pupil);
        stimulus_type_agg = cat(2, stimulus_type_agg, stimulus_type);
        billboard_cat_agg = cat(2, billboard_cat_agg, billboard_cat);
        target_category_agg = cat(2, target_category_agg, target_category);
        
        tmp1 = i*ones(1,length(stimulus_type));
        subject = cat(2,subject, tmp1);
        
        tmp2 = j*ones(1,length(stimulus_type));
        block = cat(2,block,tmp2);
    end
end

n_trials_before_pruning = length(stimulus_type_agg);
disp(['Total trials before pruning: ' num2str(n_trials_before_pruning)])

% For subject 11
% EEG_agg(:,:,1) = [];
% head_rotation_agg(1,:) = [];
% pupil_agg(1,:) = [];
% stimulus_type_agg(1) = [];
% dwell_times_agg(1) = [];
% billboard_cat_agg(1) = [];
% target_category_agg(1) = [];

%% Delete Trials with extreme head rotation values
% on the last trial of a given block, occassionally, the last 300 ms or so
% are cut off resulting in a head rotation of -180
ext_head_rotation = find(min(head_rotation_agg,[],2) < -170);
disp(['Trials with extreme head rotation values: ' num2str(length(ext_head_rotation))])

if DELETE_EXT_HEAD_ROT
    dwell_times_agg(ext_head_rotation) = [];
    EEG_agg(:,:,ext_head_rotation) = [];
    head_rotation_agg(ext_head_rotation,:) = [];
    pupil_agg(ext_head_rotation,:) = [];
    stimulus_type_agg(ext_head_rotation) = [];
    billboard_cat_agg(ext_head_rotation) = [];
    target_category_agg(ext_head_rotation) = [];
    subject(ext_head_rotation) = [];
    block(ext_head_rotation) = [];
end
disp(['Trials after pruning extreme head rotations: ' num2str(length(stimulus_type_agg))])

%% Delete Trials with Really Extreme EEG Values

% Look at the channel spectra prior to deleting trials with extreme EEG values 
% eeglab
% EEGlab = pop_importdata('data', 'EEG_agg', 'srate', 256)
% pop_spectopo(EEGlab)

% Delete trials that contain extreme EEG values
maxima = max(max(EEG_agg, [], 2),[],1);
maxima = reshape(maxima, [size(maxima, 3), 1]);
minima = min(min(EEG_agg, [], 2),[],1);
minima = reshape(minima, [size(minima, 3), 1]);

extreme_eeg = find((maxima > threshold) | (minima < -threshold));
if DELETE_EXT_EEG
    dwell_times_agg(extreme_eeg) = [];
    EEG_agg(:,:,extreme_eeg) = [];
    head_rotation_agg(extreme_eeg,:) = [];
    pupil_agg(extreme_eeg,:) = [];
    stimulus_type_agg(extreme_eeg) = [];
    billboard_cat_agg(extreme_eeg) = [];
    target_category_agg(extreme_eeg) = [];
    subject(extreme_eeg) = [];
    block(extreme_eeg) = [];

    figure
    plot(maxima)
    hold on
    plot(minima)
    title('maxima and minima of EEG')
end

disp(['Trials with extreme eeg values: ' num2str(length(extreme_eeg))])
disp(['Trials after pruning extreme EEG: ' num2str(length(stimulus_type_agg))])
disp(['Fraction of trials pruned: ' num2str(1-length(stimulus_type_agg)/n_trials_before_pruning)])

% Look at the channel spectra after deleting trials with extreme EEG values 
% eeglab
% EEGlab = pop_importdata('data', 'EEG_agg', 'srate', 256)
% pop_spectopo(EEGlab)
% pop_spectopo(EEGlab, 1, [0, 1500], 'EEG')

%% Save Data
if SAVE_ON
    EEG = EEG_agg;
    head_rotation = head_rotation_agg;
    pupil = pupil_agg;
    stimulus_type = stimulus_type_agg;
    dwell_times = dwell_times_agg;
    billboard_cat = billboard_cat_agg;
    target_category = target_category_agg;
    
    % Convert data to have a seperate cell array for each subject
    [billboard_cat, block, dwell_times, EEG, head_rotation, pupil, stimulus_type, subject, target_category] = array2cell(billboard_cat, block, dwell_times, EEG, head_rotation, pupil, stimulus_type, subject, target_category);

    SAVE_PATH = fullfile('..','..','..','Dropbox','NEDE_Dropbox',...
            'Data', ['training_v' DATA_VERSION_NO], 'training_data.mat');
    save(SAVE_PATH, 'EEG', 'head_rotation', 'pupil', 'stimulus_type', 'dwell_times', 'billboard_cat', 'target_category', 'subject', 'block')
    disp('Data Saved')
end
    
disp('done')