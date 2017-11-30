clear all; close all; clc;

testingData = (1:20)';
trainingData = linspace(1,20,100)';
trainingTruth = [zeros(50,1); ones(50,1)];

[~,~,~,~,coeff] = classify(testingData,trainingData,trainingTruth);
wCell{foldNum}(:,iWin,jFold) = coeff(2).linear;