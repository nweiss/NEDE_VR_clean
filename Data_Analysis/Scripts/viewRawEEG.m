clear all; clc; close all;

LOAD_PATH = fullfile('..','Data','raw_mat','subject_10','s10_b4_raw.mat');
load(LOAD_PATH);

eeg.time_series(1,:) = [];
eeg.time_series = downsample(eeg.time_series',32)';
nElec = size(eeg.time_series,1);
% for i = 1:nElec;
%     eeg.time_series(i,:) = eeg.time_series(i,:) + 10*i;
% end

elec = 40;
figure
plot(eeg.time_series(elec,:))
