close all; clc; clear all;
% Settings

DATA_VERSION_NO = '4'; % version of the stored data
SUBJ = 6;
ylim = [-40,40];

DIR = fullfile('..','..','NEDE_Online');
addpath(genpath(DIR));

LOAD_PATH = fullfile('..','Data',['training_v',DATA_VERSION_NO],'training_data.mat');
load(LOAD_PATH);

% For data version 4: Update the format of the data so each subject has its own cell array
if strcmp(DATA_VERSION_NO, '4')
    [billboard_cat,block,dwell_times,EEG,head_rotation,pupil,stimulus_type,subject,target_category] = array2cell(billboard_cat,block,dwell_times,EEG,head_rotation,pupil,stimulus_type,subject,target_category);
end

% Update the stimulus type so that (0=distractor,1=target)
nTrials = nan(max(SUBJ),1);
for i = 1:8
    nTrials(i) = numel(billboard_cat{i});
    targInd = stimulus_type{i}==1;
    distInd = stimulus_type{i}==2;
    nTarg = sum(targInd);
    nDist = sum(distInd);
    stimulus_type{i} = nan(nTrials(i),1);
    stimulus_type{i}(targInd) = ones(nTarg,1);
    stimulus_type{i}(distInd) = zeros(nDist,1);
end
eeg = EEG;
%%

EEGTarg = pop_importdata('setname','targets','data',eeg{SUBJ}(:,:,stimulus_type{SUBJ}==1), 'chanlocs','biosemi_64.ced','xmin',-.5,'srate',256);
EEGDist = pop_importdata('setname','distractors','data',eeg{SUBJ}(:,:,stimulus_type{SUBJ}==0), 'chanlocs','biosemi_64.ced','xmin',-.5,'srate',256);
ALLEEG = [EEGTarg, EEGDist];
pop_comperp(ALLEEG,1,1,2,'ylim',ylim,'title','Targets-Distractors','addavg','on','subavg','on');%'addavg','on','subavg','on','diffavg','on');

disp('Done!')