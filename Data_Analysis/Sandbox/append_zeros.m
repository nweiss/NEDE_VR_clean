% append zeros to EEG data with has a first dimension of 64 instead of 65
% read the four line eye signal into a 37 line signal

clear; close all; clc;

SUBJECTS = [1, 2];
BLOCKS = [13, 9];

BLOCKS_UPDATED = [0, 0];
BLOCKS_NOT_UPDATED = [0, 0];

for i = 2
    for j = 1:9
        clear eeg
        clear unity
        clear eye
        disp('variables cleared')
        
        LOAD_PATH_RAW = fullfile('Data', ['subject_', num2str(SUBJECTS(i))], ['s', num2str(SUBJECTS(i)), '_b', num2str(j), '_raw_v2.mat']);
        load(LOAD_PATH_RAW);
        
        if size(eeg.time_series, 1) == 64
            eeg.time_series = [zeros(1, length(eeg.time_stamps)); eeg.time_series];         
        end
        
        
        %[2,3,23,37]
        if size(eye.time_series, 1) == 4
            eye.time_series = [zeros(1,length(eye.time_stamps)); eye.time_series(1:2,:); zeros(19,length(eye.time_stamps)); eye.time_series(3,:); zeros(13,length(eye.time_stamps)); eye.time_series(4,:)]; 
        end
        
        SAVE_PATH_RAW = fullfile('Data', ['subject_' num2str(SUBJECTS(i))], ['s', num2str(SUBJECTS(i)), '_b', num2str(j), '_raw.mat']);
        save(SAVE_PATH_RAW, 'eye', 'unity', 'eeg')
            
        disp('saved new raw dataset for:')
        disp(['subject: ', num2str(SUBJECTS(i))])
        disp(['block: ', num2str(j)])
        
    end
end

disp('done');