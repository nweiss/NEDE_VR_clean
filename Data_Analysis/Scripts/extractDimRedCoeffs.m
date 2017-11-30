% This script takes the raw data and creates continuous_v6
clear all; clc; close all;

%% Settings
SUBJECT = 13;
nBLOCKS = 40;
REM_BAD_CHANS = true;
BAD_CHAN_THRESH = 5; % Threshold for identifying bad channels. In Standard Deviations.
REM_COMPS_FROM_ROTATION = true;
thresh = 2; % Threshold for correlation between IC and rotation over which to remove component. In Z-score.
SAVE_ON = true;

%% Constants
freq_eeg = 2048;

%% Initialize Variables
blockFrames = zeros(nBLOCKS, 2);
EEG = struct;
EEG.agg = []; % Aggregate the data from across blocks into these variables
headRotationAgg = [];

%% Set Paths
dependancy_path = fullfile('..','Dependancies');
addpath(dependancy_path);
function_path = fullfile('..','Functions');
addpath(function_path);

%% Create Filters
% High Pass Filter for EEG
Fstop = .5;         % Stopband Frequency
Fpass = 3;           % Passband Frequency
Astop = 60;          % Stopband Attenuation (dB)
Apass = 1;           % Passband Ripple (dB)
match = 'passband';  % Band to match exactly
h_hp  = fdesign.highpass(Fstop, Fpass, Astop, Apass, 2048);
Hd_hp = design(h_hp, 'cheby2', 'MatchExactly', match);
%fvtool(Hd_hp)

% Low Pass Filter for EEG
Fpass = 50;          % Passband Frequency
Fstop = 55;          % Stopband Frequency
Apass = 1;           % Passband Ripple (dB)
Astop = 60;          % Stopband Attenuation (dB)
match = 'stopband';  % Band to match exactly
h_lp  = fdesign.lowpass(Fpass, Fstop, Apass, Astop, freq_eeg);
Hd_lp = design(h_lp, 'cheby2', 'MatchExactly', match);
%fvtool(Hd_lp)

%% Run Processing Pipeline
% Collect all the blocks into a single variable
for BLOCK = 1:nBLOCKS
    % Load Data
    load_path = fullfile('..','..','..','Dropbox','NEDE_Dropbox','Data',...
        'raw_mat',['subject_',num2str(SUBJECT)],...
        ['s',num2str(SUBJECT),'_b',num2str(BLOCK),'_raw.mat']);
    load(load_path);
    
    % Filter
    EEG.hp = filter(Hd_hp, eeg.time_series(2:65,:)')';
    EEG.filtered = filter(Hd_lp, EEG.hp')';
       
    % Trim off any EEG data prior to the first unity time-stamp or after
    EEGFramesToKeep = (eeg.time_stamps > unity.time_stamps(1)) & ...
        (eeg.time_stamps < unity.time_stamps(end));
    EEG.trimmed = EEG.filtered(:,EEGFramesToKeep);
    eegTimeStampsTrimmed = eeg.time_stamps(EEGFramesToKeep);
    
    % Interpolate the head rotation at the points of the EEG timestamps
    headRotation = processHeadRotation(unity.time_series(9,:),unity.time_series(12,:));
    headRotationUpsampled = interp1(unity.time_stamps,headRotation,eegTimeStampsTrimmed);
    
    % Downsample
    EEG.downsampled = downsample(EEG.trimmed',8)';
    headRotation = downsample(headRotationUpsampled',8)';
        
    % Concatenate into a single continuous set of EEG
    blockFrames(BLOCK,1) = size(EEG.agg,2)+1;
    EEG.agg = [EEG.agg, EEG.downsampled];
    headRotationAgg = [headRotationAgg, headRotation];
    blockFrames(BLOCK,2) = size(EEG.agg,2);

end
disp('Finished compiling EEG data')

% Import data to EEGLab
tmp1 = EEG.agg; % Import tmp1 into EEGLab. EEG data cannot be in a struct.
tmp2 = fullfile('..','Dependancies','biosemi_64.ced');
EEGlab = pop_importdata('data','tmp1','srate',256,'chanlocs',tmp2);

% Identify and zero out bad channels
if REM_BAD_CHANS
    [~,badChanInd,measure,com] = pop_rejchan(EEGlab,'threshold',BAD_CHAN_THRESH,'norm','on');
    EEGlab.data(badChanInd,:) = zeros(length(badChanInd),EEGlab.pnts);
end
    
% Find PCA_coeff and clean with PCA
[pca_coeff,pca_score,latent] = pca(EEGlab.data','NumComponents',20);
tmp = pca_coeff' * EEGlab.data;
EEGlab.data = pca_coeff * tmp;

% Find ICAweights and ICAsphere
EEGlab = pop_runica(EEGlab,'icatype','runica');
% Find the component activations. Code borrowed from:
% https://sccn.ucsd.edu/pipermail/eeglablist/2013/006954.html
EEGlab.icaact = (EEGlab.icaweights*EEGlab.icasphere)*EEGlab.data(EEGlab.icachansind,:);

% Find the independant components that correlate to head rotation
if REM_COMPS_FROM_ROTATION
    % CHANGE THE EEG TO EEGlab.icaact. This was only for development
    % version.
    [ICs_from_HR,cov_HRpos_IC_zscore, cov_HRvel_IC_zscore, cov_HRacc_IC_zscore] = findICsFromRotation(EEGlab.icaact, headRotationAgg, thresh);
end

if SAVE_ON
    icaweights = EEGlab.icaweights;
    icasphere = EEGlab.icasphere;
    save_path = fullfile('..','..','..','Dropbox','NEDE_Dropbox','Data',...
        'dim_red_params',['s',num2str(SUBJECT),'_dimredparams.mat']);
    save(save_path,'pca_coeff','icaweights','icasphere','badChanInd','ICs_from_HR','cov_HRpos_IC_zscore', 'cov_HRvel_IC_zscore', 'cov_HRacc_IC_zscore');
    
end

disp('Done')