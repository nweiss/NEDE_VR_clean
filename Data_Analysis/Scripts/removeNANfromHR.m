clear all; clc; close all;


load_path = fullfile('..','..','..','Dropbox','NEDE_Dropbox','Data','training_v6','training_data.mat');
load(load_path);

tmp = isnan(head_rotation);
head_rotation(tmp) = 0;

save_path = fullfile('..','..','..','Dropbox','NEDE_Dropbox','Data','training_v6','training_data.mat');
save(save_path,'billboard_cat','block','dwell_times','EEG','head_rotation','pupil','stimulus_type','subject','target_category')