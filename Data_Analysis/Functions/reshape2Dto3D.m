function [threeDimEEG] = reshape3Dto2D(twoDimEEG, nSamples)

% Convert from 2D EEG format to 3D
% INPUT:
% - twoDimEEG is EEG data in the format channels x (time x epochs). If there 
%   are S samples in an epoch, the data is formated such that the first S
%   columns belong to the 1st epoch, the second S columns belong to the
%   second epoch...
% - nSamples is the number of samples in a single epoch for a single
% channel
%
% OUTPUT:
% - threeDimEEG: EEG data in the format channels x time x epochs

nEpoch = size(twoDimEEG,2)/nSamples;
nChan = size(twoDimEEG,1);

threeDimEEG = zeros(nChan,nSamples,nEpoch);

counter1 = 1;
counter2 = nSamples;
for i = 1:nEpoch
    threeDimEEG(:,:,i) = twoDimEEG(:,counter1:counter2);
    counter1 = counter1 + nSamples;
    counter2 = counter2 + nSamples;
end