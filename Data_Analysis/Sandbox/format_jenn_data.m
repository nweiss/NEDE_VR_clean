clear all; clc; close all;

for i = 8
    for j = 1:8
        clear dwell_time
        clear eeg
        clear head_rotation
        clear pupil
        clear stimulus_type
        clear billboard_cat
        clear target_category
        
        LOAD_PATH = fullfile('Data', ['subject_', num2str(i)], ['s', num2str(i), '_b', num2str(j), '_epoched.mat']);
        load(LOAD_PATH);
        
        target_category = target_category * ones(1, length(stimulus_type));
        
        SAVE_PATH = fullfile('Data', ['subject_', num2str(i)], ['s', num2str(i), '_b', num2str(j), '_epoched_v2.mat']);
        save(SAVE_PATH, 'billboard_cat', 'dwell_times', 'EEG', 'head_rotation', 'pupil', 'stimulus_type', 'target_category');
    end
end

disp('done')