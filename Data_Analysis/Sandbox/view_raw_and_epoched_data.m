% View raw and epoched data

clear all; clc; close all;

DATA_VERSION_NO = '3';
BLOCK = 5;
SUBJECT = 100;

% Load epoched data
LOAD_PATH = fullfile('..', 'Data', ['epoched_v' DATA_VERSION_NO], ['subject_', num2str(SUBJECT)], ['s', num2str(SUBJECT), '_b', num2str(BLOCK), '_epoched.mat']);
load(LOAD_PATH);