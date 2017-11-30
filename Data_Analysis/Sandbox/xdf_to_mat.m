% This file converts from single blocks of xdf to single block .mat files
% The .mat contains the following fields:
%   eeg - time_series has 65 rows
%   eye - time_series has 37 rows
%   unity - time series has 15 rows


clear; clc; close all;

%% Subject specific info
subject_ID = '3'; %the subject id to be stored in the EEG struct
nBlocks = 1;
save_on = true; %save the data at the end of this run in a 'prep_stage_1' file

%%
for i = 1%19:nBlocks
    clear eeg
    clear eye
    clear unity
    clear y
    
    load_path = fullfile('Data', ['subject_', num2str(subject_ID)], ['raw_0', num2str(i) '.xdf']);
    save_path = fullfile('Data', ['subject_', num2str(subject_ID)], ['s', num2str(subject_ID), '_b', num2str(i), '_raw.mat']);

    y = load_xdf(load_path);

    for j = 1:length(y) %for all data streams
        if strcmp(y{j}.info.name, 'NEDE_Stream') % Unity stream
            unity.time_series = y{j}.time_series;
            unity.time_stamps = y{j}.time_stamps;
        end
        if strcmp(y{j}.info.name, 'iViewNG_HMD') % eye stream
            eye.time_series = y{j}.time_series;
            eye.time_stamps = y{j}.time_stamps;
        end
        if strcmp(y{j}.info.name, 'BioSemi') %EEG stream
            eeg.time_series = y{j}.time_series(1:65,:);
            eeg.time_stamps = y{j}.time_stamps;
        end
    end

    %% Save Data
    if save_on
        save(save_path, 'eeg', 'unity', 'eye');
        disp(['saved block ' num2str(i)])
    end
end
disp('done')