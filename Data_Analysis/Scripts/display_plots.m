% This script displays some plots of the raw data
clear all; clc; close all;

SUBJECTS = [2];
DATA_VERSION_NO = '4';

% Delete trials with extreme head rotation values. This happens occasionaly
% on the last stimulus of a block if the game exits before the end of the
% epoch.
DELETE_EXT_HEAD_ROT = true;  

% Delete trials that include an EEG value over a certain threshold. Happens
% with bad electrodes.
DELETE_EXT_EEG = true;
threshold = 750;

ERROR_BAR_PATH = fullfile('..', 'dependancies', 'shadedErrorBar');
addpath(ERROR_BAR_PATH);

LOAD_PATH = fullfile('..','Data',['training_v',DATA_VERSION_NO],'training_data.mat');
load(LOAD_PATH);
head_rotation = abs(head_rotation);

nTrials_init = numel(billboard_cat);

%% Select Subject's Data
mask = nan(nTrials_init,length(SUBJECTS));
for i = 1:length(SUBJECTS)
    mask(:,i) = subject == SUBJECTS(i);
end
mask = any(mask,2);
dwell_times = dwell_times(mask);
EEG = EEG(:,:,mask);
head_rotation = head_rotation(mask,:);
pupil = pupil(mask,:);
stimulus_type = stimulus_type(mask);
billboard_cat = billboard_cat(mask);
target_category = target_category(mask);
subject = subject(mask);
block = block(mask);

total_trials = numel(billboard_cat);
disp(['Total Trials: ' num2str(total_trials)])

%% Delete Trials with extreme head rotation values
% on the last trial of a given block, occassionally, the last 300 ms or so
% are cut off resulting in a head rotation of -180
ext_head_rotation = find(max(head_rotation,[],2) > 170);
disp(['Trials with extreme head rotation values: ' num2str(length(ext_head_rotation))])

if DELETE_EXT_HEAD_ROT
    dwell_times(ext_head_rotation) = [];
    EEG(:,:,ext_head_rotation) = [];
    head_rotation(ext_head_rotation,:) = [];
    pupil(ext_head_rotation,:) = [];
    stimulus_type(ext_head_rotation) = [];
    billboard_cat(ext_head_rotation) = [];
    target_category(ext_head_rotation) = [];
    subject(ext_head_rotation) = [];
    block(ext_head_rotation) = [];
end
disp(['Trials after pruning extreme head rotations: ' num2str(length(stimulus_type))])

%% Delete Trials with Really Extreme EEG Values

% Look at the channel spectra prior to deleting trials with extreme EEG values 
% eeglab
% EEGlab = pop_importdata('data', 'EEG_agg', 'srate', 256)
% pop_spectopo(EEGlab)

% Delete trials that contain extreme EEG values
maxima = max(max(EEG, [], 2),[],1);
maxima = reshape(maxima, [size(maxima, 3), 1]);
minima = min(min(EEG, [], 2),[],1);
minima = reshape(minima, [size(minima, 3), 1]);

extreme_eeg = find((maxima > threshold) | (minima < -threshold));
if DELETE_EXT_EEG
    dwell_times(extreme_eeg) = [];
    EEG(:,:,extreme_eeg) = [];
    head_rotation(extreme_eeg,:) = [];
    pupil(extreme_eeg,:) = [];
    stimulus_type(extreme_eeg) = [];
    billboard_cat(extreme_eeg) = [];
    target_category(extreme_eeg) = [];
    subject(extreme_eeg) = [];
    block(extreme_eeg) = [];

%     figure
%     plot(maxima)
%     hold on
%     plot(minima)
%     title('maxima and minima of EEG')
end

disp(['Trials with extreme eeg values: ' num2str(length(extreme_eeg))])
disp(['Trials after pruning extreme EEG: ' num2str(length(stimulus_type))])
disp(['Fraction of trials pruned: ' num2str(1-length(stimulus_type)/total_trials)])

% Look at the channel spectra after deleting trials with extreme EEG values 
% eeglab
% EEGlab = pop_importdata('data', 'EEG_agg', 'srate', 256)
% pop_spectopo(EEGlab)
% pop_spectopo(EEGlab, 1, [0, 1500], 'EEG')


%% EEG plot
EEG_targ_means = mean(EEG(:,:,stimulus_type == 1),3);
EEG_targ_std = std(EEG(:,:,stimulus_type == 1),[],3);
EEG_targ_stder = EEG_targ_std./sqrt(sum(stimulus_type == 1));
EEG_dist_means = mean(EEG(:,:,stimulus_type == 2),3);
EEG_dist_std = std(EEG(:,:,stimulus_type == 2),[],3);
EEG_dist_stder = EEG_dist_std./sqrt(sum(stimulus_type == 2));

figure
subplot(3,2,1)
electrode = 38;
H1 = shadedErrorBar(linspace(-500, 1000, size(EEG_targ_means,2)),EEG_targ_means(electrode,:,:), EEG_targ_stder(electrode,:,:), 'r');
hold on
H2 = shadedErrorBar(linspace(-500, 1000,size(EEG_dist_means,2)),EEG_dist_means(electrode,:,:), EEG_dist_stder(electrode,:,:),  'b');
legend([H1.mainLine, H2.mainLine], 'targets', 'distractors', 'Location', 'SouthWest')
title('Electrode Fz')
xlabel('Time (ms)')
ylabel('Microvolts')

subplot(3,2,3)
electrode = 48;
H1 = shadedErrorBar(linspace(-500, 1000, size(EEG_targ_means,2)),EEG_targ_means(electrode,:,:), EEG_targ_stder(electrode,:,:), 'r');
hold on
H2 = shadedErrorBar(linspace(-500, 1000,size(EEG_dist_means,2)),EEG_dist_means(electrode,:,:), EEG_dist_stder(electrode,:,:),  'b');
legend([H1.mainLine, H2.mainLine], 'targets', 'distractors', 'Location', 'SouthWest')
title('Electrode Cz')
xlabel('Time (ms)')
ylabel('Microvolts')

subplot(3,2,5)
electrode = 31;
H1 = shadedErrorBar(linspace(-500, 1000, size(EEG_targ_means,2)),EEG_targ_means(electrode,:,:), EEG_targ_stder(electrode,:,:), 'r');
hold on
H2 = shadedErrorBar(linspace(-500, 1000,size(EEG_dist_means,2)),EEG_dist_means(electrode,:,:), EEG_dist_stder(electrode,:,:),  'b');
legend([H1.mainLine, H2.mainLine], 'targets', 'distractors', 'Location', 'SouthWest')
title('Electrode Pz')
xlabel('Time (ms)')
ylabel('Microvolts')

%% Pupil plot
pupil_targ_means = mean(pupil(stimulus_type == 1,:),1);
pupil_targ_std = std(pupil(stimulus_type == 1,:),[],1);
pupil_targ_stder = pupil_targ_std./sqrt(sum(stimulus_type == 1));
pupil_dist_means = mean(pupil(stimulus_type == 2,:),1);
pupil_dist_std = std(pupil(stimulus_type == 2,:),[],1);
pupil_dist_stder = pupil_dist_std./sqrt(sum(stimulus_type == 2));

%figure
subplot(3,2,2)
H7 = shadedErrorBar(linspace(-1000,3000,size(pupil_targ_means,2)),pupil_targ_means, pupil_targ_stder, 'r');
hold on
H8 = shadedErrorBar(linspace(-1000,3000,size(pupil_targ_means,2)),pupil_dist_means, pupil_dist_stder, 'b');
legend([H7.mainLine, H8.mainLine], 'targets', 'distractors', 'Location', 'SouthWest')
title('Pupil Dilation')
xlabel('Time (ms)')
ylabel('Area as Percentage of Subject Mean')

%% Head Rotation
hr_targ_mean = mean(head_rotation(stimulus_type == 1,:),1);
hr_targ_std = std(head_rotation(stimulus_type == 1,:),[],1);
hr_targ_stder = hr_targ_std./sqrt(sum(stimulus_type == 1));
hr_dist_mean = mean(head_rotation(stimulus_type == 2,:),1);
hr_dist_std = std(head_rotation(stimulus_type == 2,:),[],1);
hr_dist_stder = hr_dist_std./sqrt(sum(stimulus_type == 2));

%figure
subplot(3,2,4)
H9 = shadedErrorBar(linspace(-500,1500,size(head_rotation,2)),hr_targ_mean, hr_targ_stder, 'r');
hold on
H10 = shadedErrorBar(linspace(-500,1500,size(head_rotation,2)),hr_dist_mean,hr_dist_stder, 'b');
legend([H9.mainLine, H10.mainLine],'targets', 'distractors', 'Location', 'NorthWest')
title('Head Rotation')
ylabel('|degrees|')
xlabel('Time (ms)')

%% dwell time plot
nTargets = sum(stimulus_type == 1);
nDistractors = sum(stimulus_type == 2);
dt_graph_targets = zeros(1,1500);
dt_graph_distractors = zeros(1,1500);
for i = 1:1500 % cycle through 1500 ms
    for j = 1:length(stimulus_type)
       if stimulus_type(j) == 1
           if dwell_times(j) >= i/1000
                dt_graph_targets(i) = dt_graph_targets(i)+1;
           end
       end
       if stimulus_type(j) == 2
           if dwell_times(j) >= i/1000
                dt_graph_distractors(i) = dt_graph_distractors(i)+1;
           end
       end
   end
end

dt_graph_targets = dt_graph_targets./nTargets;
dt_graph_distractors = dt_graph_distractors./nDistractors;

subplot(3,2,6)
plot(1:1500, dt_graph_targets, 'r', 1:1500, dt_graph_distractors, 'b')
title('Dwell Times')
xlabel('Time (ms)')
ylabel('Fraction of Trials with Dwell Time > t')
legend('Targets','Distractors', 'Location', 'SouthWest')

set(gcf,'Color','w');