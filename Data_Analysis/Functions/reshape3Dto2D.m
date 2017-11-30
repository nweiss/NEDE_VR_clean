function [twoDimEEG] = reshape3Dto2D(threeDimEEG)

% Convert from 3D EEG format to 2D
% INPUT:
% - threeDimEEG: EEG data in the format channels x time x epochs
%
% OUTPUT:
% - twoDimEEG: EEG data in the format channels x (time x epochs). If there 
%   are S samples in an epoch, the data is formated such that the first S
%   columns belong to the 1st epoch, the second S columns belong to the
%   second epoch...

nEpoch = size(threeDimEEG,3);
nSamples = size(threeDimEEG,2);
nChan = size(threeDimEEG,1);

twoDimEEG = zeros(nChan,nSamples*nEpoch);

counter1 = 1;
counter2 = nSamples;
for i = 1:nEpoch
    twoDimEEG(:,counter1:counter2) = threeDimEEG(:,:,i);
    counter1 = counter1 + nSamples;
    counter2 = counter2 + nSamples;
end