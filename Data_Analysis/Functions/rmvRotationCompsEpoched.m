function [cleanedEEG,compsFromRotation] = rmvRotationCompsEpoched(EEG_ICs, headRotation)

% Remove the components of the EEG that are caused by head rotation. Use
% this function for data that is already epoched (ie a 3d EEG matrix). For
% continuous data, use rmvRotationComps.m
% 
% INPUTS:
% - EEG_ICs is the processed EEG data. Epoched EEG had the head rotation
%   appended to it. Then it was passed through ICA.
% - headRotation is the epoched head rotation level.
% OUTPUTS:
% - cleanedEEG is the EEG after removing the head rotation components
%
% Neil Weiss 08/28/2017

epoched = 0;
if numel(size(EEG_ICs)) == 2
    

nTrials = size(headRotation,1);
nComps = size(EEG_ICs,1);

% The threshold for covariance between a component and the head rotation,
% above which, that component will be rejected.
thresh = .1;

% If the EEG_ICs matrix is flattened (ie 2D rather than 3D)
% unpack it into the three dimensional form
if numel(size(EEG_ICs)) == 2
    pnts = size(EEG_ICs,2)/nTrials;
    EEG_ICs_flat = EEG_ICs;
    EEG_ICs = nan(nComps,pnts,nTrials);
    counter1 = 1;
    counter2 = pnts;
    for i = 1:nTrials
        EEG_ICs(:,:,i)=EEG_ICs_flat(:,counter1:counter2);
        counter1 = counter1 + pnts;
        counter2 = counter2 + pnts;
    end
end

% Keep only the head rotation data from within the EEG epoch
t = linspace(-500,1500,size(headRotation,2));
ind = t<1000;
HR_abrev = headRotation(:,ind);
HR_abrev(isnan(HR_abrev)) = 0;
samplePoints = linspace(-500,1000,size(HR_abrev,2));
queryPoints = linspace(-500,1000,size(EEG_ICs,2));
HR_pos = nan(nTrials,size(EEG_ICs,2));
for i = 1:nTrials
    HR_pos(i,:) = interp1(samplePoints,HR_abrev(i,:),queryPoints);
end
HR_vel = [zeros(nTrials,1) diff(HR_pos,1,2)];
HR_acc = [zeros(nTrials,2) diff(HR_pos,2,2)];

% smooth the HR data
for i = 1:size(HR_vel,1)
    HR_vel(i,:) = smooth(HR_vel(i,:)',10)';
    HR_acc(i,:) = smooth(HR_acc(i,:)',20)';
end

% Scale the Pos, Vel, and Acc
stdPos = std(reshape(HR_pos,1,[]),'omitnan');
stdVel = std(reshape(HR_vel,1,[]),'omitnan');
stdAcc = std(reshape(HR_acc,1,[]),'omitnan');    
HR_pos = HR_pos/stdPos;
HR_vel = HR_vel/stdVel;
HR_acc = HR_acc/stdAcc;

% Concatenate the headrotation epochs onto the EEG
tmp1 = shiftdim(HR_pos',-1);
tmp2 = shiftdim(HR_vel',-1);
tmp3 = shiftdim(HR_acc',-1);
EEGandHR = cat(1,EEG_ICs,tmp1,tmp2,tmp3);

% Flatten the EEGandHR matrix so that each column is a single component
EEGandHR_sq = zeros(size(EEGandHR,2)*size(EEGandHR,3),size(EEGandHR,1));
counter1 = 1;
counter2 = size(EEGandHR,2);
for i = 1:size(EEGandHR,3)
    EEGandHR_sq(counter1:counter2,:) = EEGandHR(:,:,i)';
    counter1 = counter1+size(EEGandHR,2);
    counter2 = counter2+size(EEGandHR,2);
end

covmat = abs(cov(EEGandHR_sq));
HR_pos_ICs = covmat(nComps+1,1:nComps) > thresh;
HR_vel_ICs = covmat(nComps+2,1:nComps) > thresh;
HR_acc_ICs = covmat(nComps+3,1:nComps) > thresh;
compsFromRotation = max([HR_pos_ICs;HR_vel_ICs;HR_acc_ICs],[],1);
compsFromRotation = find(compsFromRotation);

% Display heat map of the covariance matrix
% covmat(covmat>5) = 5;
% colormap('hot')
% imagesc(covmat)
% colorbar
% title('Heatmap of covarience matrix (last three channels are head rotation channels)')

% Display the covarience of the various components with the different
% rotation measures
figure
plot(covmat(1:nComps,nComps+1:nComps+3),'*')
legend('position','velocity','acceleration')
title('Covariance of Independant Components with Rotation')

disp(['Deleting ', num2str(sum(compsFromRotation)) ' components that are related to the head rotation.'])
cleanedEEG = EEGandHR(~compsFromRotation,:,:);

disp('done with func')