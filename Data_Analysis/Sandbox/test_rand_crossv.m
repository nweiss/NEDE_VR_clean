% test setCrossValidationStruct to randomize the trials before running the
% crossvalidation

clear all; close all; clc;
FILEPATH = fullfile('..','Jangraw Functions','LogReg');
addpath(FILEPATH);

nTrials = 499;
cvmode = '10fold';

cv = setCrossValidationStruct2(cvmode,nTrials);

nointersect = nan(10,1);
for i = 1:10
    intersection = intersect(cv.incTrials{i},cv.outTrials{i});
    if isempty(intersection)
        nointersect(i) = 1;
    else
        nointersect(i) = 0;
    end
end

disp('done')