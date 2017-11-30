function [billboard_cat,block,dwell_times,EEG,head_rotation,pupil,...
    stimulus_type,target_category]...
    = shuffleTrials(randSeed,billboard_cat,block,dwell_times,EEG,...
    head_rotation,pupil,stimulus_type,target_category)

% Shuffle the data prior to classifying it. This script takes in all of the
% data, shuffles it along the dimension of trials and then returns it.

nTrials = length(billboard_cat);

% Set the random permutation
rng(randSeed);
shuffleMap = randperm(nTrials);

billboard_cat = billboard_cat(shuffleMap);
block = block(shuffleMap);
dwell_times = dwell_times(shuffleMap);
EEG = EEG(:,:,shuffleMap);
head_rotation = head_rotation(shuffleMap,:);
pupil = pupil(shuffleMap,:);
stimulus_type = stimulus_type(shuffleMap);
target_category = target_category(shuffleMap);