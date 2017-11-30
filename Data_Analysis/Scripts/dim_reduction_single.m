% Perform dimensionality reduction on EEG data.
% This script takes in already epoched data from a single subject, performs
% PCA and ICA on the EEG, and saves it to the destination file.

close all; clc; clear all;

% Settings
DATA_VERSION_NO = '3'; % version of the stored data
SAVE_ON = false;
INCLUDE_HR_ICA = true; % Append head rotation data to EEG data prior to taking ICA

SAVE_PATH = fullfile('..','Data', 'training_v5', 'training_data_neilpilot_EEG_ICs.mat');
LOAD_PATH = fullfile('..','Data',['training_v',DATA_VERSION_NO],'training_data_neil_pilot.mat');
load(LOAD_PATH);

RUN_PCA = false;


% For the neil-pilot, head-rotation contains NaN's and -180's when the game
% has already been finished. Convert the -180's to NaNs.
head_rotation(head_rotation<-100) = nan;

if RUN_PCA
    % Reshape the EEG data such that each trial is appended to the previous
    % trial along the dimension of time
    EEG_reshaped = [];
    for i = 1:size(EEG,3)
        EEG_reshaped = cat(2, EEG_reshaped, EEG(:,:,i));
    end

    % PCA
    [coeff, EEG_pcs] = pca(EEG_reshaped');
    EEG_pcs = EEG_pcs(:,1:20)'; % Keep 20 pcs

    % Put the EEG data back into its original shape
    EEG_pc_epoched = [];
    counter1 = 1;
    counter2 = size(EEG,2);
    for i = 1:size(EEG,3)
        EEG_pc_epoched = cat(3, EEG_pc_epoched, EEG_pcs(:,counter1:counter2));
        counter1 = counter1+size(EEG,2);
        counter2 = counter2+size(EEG,2);
    end
end
%%
% Append head rotation data to PCs prior to taking ICs.
if INCLUDE_HR_ICA
    % Head Rotation epoch spans -500ms to 1500ms, whereas EEG epoch spans
    % -500ms to 1000ms. Cut the HR timescale short to match the EEG time
    % scale.
    t = linspace(-500,1500,size(head_rotation,2));
    ind = t<1000;
    HR_abrev = head_rotation(:,ind);
    samplePoints = linspace(-500,1000,size(HR_abrev,2));
    queryPoints = linspace(-500,1000,size(EEG_pc_epoched,2));
    HR_pos = nan(size(HR_abrev,1),size(EEG_pc_epoched,2));
%     HR_vel = nan(size(HR_abrev,1),size(EEG_pc_epoched,2));
%     HR_acc = nan(size(HR_abrev,1),size(EEG_pc_epoched,2));
    for i = 1:size(HR_abrev,1)
        HR_pos(i,:) = interp1(samplePoints,HR_abrev(i,:),queryPoints);
    end
    dt = 1.5/size(HR_pos,2);
    HR_vel = [zeros(size(HR_pos,1),1) diff(HR_pos,1,2)];
    HR_acc = [zeros(size(HR_pos,1),2) diff(HR_pos,2,2)];
    % smooth the HR data
    for i = 1:size(HR_vel,1)
        HR_vel(i,:) = smooth(HR_vel(i,:)',10)';
        HR_acc(i,:) = smooth(HR_acc(i,:)',20)';
    end
    
   % Scale the Pos, Vel, and Acc to match the scale of the EEG
    meanAllEEG = mean(reshape(EEG_pc_epoched(1:20,:,:),1,[]));
    stdAllEEG = std(reshape(EEG_pc_epoched(1:20,:,:),1,[]));
    meanPos = mean(reshape(HR_pos,1,[]),'omitnan');
    stdPos = std(reshape(HR_pos,1,[]),'omitnan');
    meanVel = mean(reshape(HR_vel,1,[]),'omitnan');
    stdVel = std(reshape(HR_vel,1,[]),'omitnan');
    meanAcc = mean(reshape(HR_acc,1,[]),'omitnan');
    stdAcc = std(reshape(HR_acc,1,[]),'omitnan');    
    HR_pos = HR_pos/stdPos;
    HR_vel = HR_vel/stdVel;
    HR_acc = HR_acc/stdAcc;
    
    % append the HR data to the EEG data
    EEG_pc_epoched = cat(1,EEG_pc_epoched,zeros(3,size(EEG_pc_epoched,2),size(EEG_pc_epoched,3)));
    for i = 1:size(HR_pos,1)
        EEG_pc_epoched(21,:,i) = HR_pos(i,:);
        EEG_pc_epoched(22,:,i) = HR_vel(i,:);
        EEG_pc_epoched(23,:,i) = HR_acc(i,:);
    end
end

%%
% Eliminate nan's for ICA
EEG_pc_epoched(isnan(EEG_pc_epoched)) = 0;

% Run ICA
EEG_lab = pop_importdata('data', 'EEG_pc_epoched', 'dataformat', 'array');
EEG_ica = pop_runica(EEG_lab, 'icatype', 'runica');
% Find the actual component activations. Code borrowed from:
% https://sccn.ucsd.edu/pipermail/eeglablist/2013/006954.html
EEG_ica.icaact = (EEG_ica.icaweights*EEG_ica.icasphere)*EEG_ica.data(EEG_ica.icachansind,:);

% Put IC projected data back into its original shape
EEG_ic_epoched = [];
counter1 = 1;
counter2 = size(EEG,2);
for i = 1:size(EEG,3)
    EEG_ic_epoched = cat(3, EEG_ic_epoched, EEG_ica.icaact(:,counter1:counter2));
    counter1 = counter1+size(EEG,2);
    counter2 = counter2+size(EEG,2);
end

EEG = EEG_ic_epoched;

% Eliminate nans from headrotation
head_rotation(isnan(head_rotation)) = 0;

if SAVE_ON
    save(SAVE_PATH, 'EEG', 'billboard_cat', 'block', 'dwell_times', 'head_rotation', 'pupil', 'stimulus_type', 'subject', 'target_category');
    disp('Data Saved!')
end
disp('done');