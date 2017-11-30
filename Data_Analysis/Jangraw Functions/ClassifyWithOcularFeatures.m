function [Az,v] = ClassifyWithOcularFeatures(truth,features)

% Created 8/13/13 by DJ.
% Updated 8/28/13 by DJ - added v output

% set up
samplesWindowLength = [];
samplesWindowStart = [];
cvmode = '10fold';
fwdModelData = [];
nSubjects = numel(truth);
v = cell(1,nSubjects);
Az = nan(1,nSubjects);
% run
for iSubj=1:numel(truth)    
    dwellFeature = features{iSubj};
    data = zeros(1,1,size(dwellFeature,1));
    [y, ~, v{iSubj}] = Run2LevelClassifier_nested(data,truth{iSubj},samplesWindowLength,samplesWindowStart,cvmode,dwellFeature,fwdModelData);
    Az(iSubj) = rocarea(y,truth{iSubj});    
end