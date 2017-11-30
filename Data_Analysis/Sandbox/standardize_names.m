clear all; clc; close all;

SAVE_ON = false;

BLOCKS = [13, 9, 7, 13, 16, 18, 23, 33];

for i = 1
    for j = 1:BLOCKS(i)
        clear dwell_time
        clear dwell_times
        clear eeg
        clear EEG
        clear head_rotation
        clear pupil
        clear stimulus_type
        
        LOAD_PATH = fullfile('Data', ['subject_', num2str(i)], ['s', num2str(i), '_b', num2str(j), '_epoched.mat']);
        load(LOAD_PATH);
        
        if exist('dwell_time')
            dwell_times = dwell_time;
            clear dwell_time;
            disp('updated dwell time: ')
            disp(['subject: ' num2str(i)])
            disp(['block: ' num2str(j)])
        end
        if exist('eeg')
            EEG = eeg;
            clear eeg;
            disp('updated eeg: ')
            disp(['subject: ' num2str(i)])
            disp(['block: ' num2str(j)])
        end
        
        if SAVE_ON
            SAVE_PATH = fullfile('Data', ['subject_', num2str(i)], ['s', num2str(i), '_b', num2str(j), '_epoched.mat']);
            save(SAVE_PATH, 'dwell_times', 'EEG', 'head_rotation', 'pupil', 'stimulus_type')
        end
    end
end

disp('done')