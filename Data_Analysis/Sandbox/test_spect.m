clear all; clc; close all;
load('Data/subject_6/s6_b1_epoched.mat')
EEG_tmp = EEG;

eeglab
EEG = pop_importdata('data', 'EEG_tmp', 'srate', 256)
pop_spectopo(EEG)