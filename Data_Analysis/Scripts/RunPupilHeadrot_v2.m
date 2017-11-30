function [y, y_level1] = RunPupilHeadrot(data, truth, trainingwindowlength, trainingwindowoffset, cvmode)

% Process the pupil dilation or head rotation data from the NEDE
% experiment. These two data streams can be processed with a single script
% because they have similar dimensionality.
%
% INPUTS: 
% - data
% - truth
% 
% OUTPUTS:
% y
% - y_level1
%
% created 06/20/2017 by Neil Weiss

% Initialize Variables
nWindows = numel(trainingwindowoffset);
nSamples = size(data, 2);
nTrials = numel(truth);
cv = setCrossValidationStruct(cvmode,nTrials);
nFolds = cv.numFolds;
truth = truth-1;
y_level1 = nan(nTrials, nWindows);
sampleTruth = repmat(reshape(truth,[1 1 nTrials]),[1 nSamples 1]);

% Find the within-bin means
withinbin_mean = nan(nTrials, nWindows);
for iWin = 1:nWindows
    isInWin = trainingwindowoffset(iWin) + (1:trainingwindowlength);
    withinbin_mean(:,iWin) = mean(data(:,isInWin), 2);
end

% Perform FLD to find y_level1. To do this, do a cross-validation and keep
% the interest scores from the test set of each fold. These interest scores
% are y_level1.
for foldNum=1:nFolds       
    foldTrainingData = data(:,:,cv.incTrials{foldNum});
    foldTestingData = data(:,:,cv.valTrials{foldNum});
    foldTrainingTruth = sampleTruth(:,:,cv.incTrials{foldNum}); 
    
    [~,~,~,~,coeff] = classify(withinbin_mean, truth, [0,1]);
end

y = 1;
y_level1 = 2;