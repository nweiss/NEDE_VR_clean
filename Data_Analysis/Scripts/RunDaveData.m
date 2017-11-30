clear all; clc; close all;

DIR = fullfile('..','..','NEDE_Online');
addpath(genpath(DIR));
filepath = fullfile('..','Jangraw Data', '2013-03-28-Pilot-S23', 'ALLEEG23_NoeogEpochedIcaCropped.mat');
load(filepath);

EEG = cat(3, ALLEEG(1).icaact, ALLEEG(2).icaact);
truth = cat(1, zeros(ALLEEG(1).trials,1), ones(ALLEEG(2).trials,1));
cvmode = '10fold';

sf = ALLEEG(1).srate;
trainingwindowlength = .1 * sf;
trainingwindowoffset = (sf*1.1:trainingwindowlength:sf*2-trainingwindowlength);
[y, w, v, fwdModel, y_level1, Az] = RunHybridHdcaClassifier(EEG, truth, trainingwindowlength, trainingwindowoffset, cvmode);

