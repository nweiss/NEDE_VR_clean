% Find the subject specific parameters for the classifier

clear all; clc; close all;

SUBJECT_ID = '01';
TRAINING_BLOCK = '01';
LOAD_DATA_PATH = fullfile('Data', ['subject_' SUBJECT_ID], ['block_' BLOCK]); %the path to where the raw data is stored.
load(LOAD_DATA_PATH);

