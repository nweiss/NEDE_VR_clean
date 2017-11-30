function [ICs_from_HR, cov_HRpos_IC_zscore, cov_HRvel_IC_zscore, cov_HRacc_IC_zscore] = findICsFromRotation(EEG_ICs, headRotation, thresh)

% thresh - Threshold for correlation between an independant component and the head rotation over which to reject an independant component (in Z score)
% ICs_from_HR - the independant components that are correlated with the
% head rotation abouve the threshold thresh

nComps = size(EEG_ICs,1);

% Find the velocity and acceleration of the head rotation
HR_vel = [0, diff(headRotation,1,2)];
HR_acc = [0, 0, diff(headRotation,2,2)];

% smooth the HR data
HR_vel = smooth(HR_vel',10)';
HR_acc = smooth(HR_acc',20)';

% Scale the Pos, Vel, and Acc
stdPos = std(reshape(headRotation,1,[]),'omitnan');
stdVel = std(reshape(HR_vel,1,[]),'omitnan');
stdAcc = std(reshape(HR_acc,1,[]),'omitnan');    
HR_pos = headRotation/stdPos;
HR_vel = HR_vel/stdVel;
HR_acc = HR_acc/stdAcc;

% Concatenate the headrotation epochs onto the EEG
tmp1 = shiftdim(HR_pos',-1);
tmp2 = shiftdim(HR_vel',-1);
tmp3 = shiftdim(HR_acc',-1);
EEGandHR = cat(1,EEG_ICs,tmp1,tmp2,tmp3);

covmat = abs(cov(EEGandHR'));
cov_HRpos_IC_zscore = zscore(abs(covmat(nComps+1,1:nComps)));
cov_HRvel_IC_zscore = zscore(abs(covmat(nComps+2,1:nComps)));
cov_HRacc_IC_zscore = zscore(abs(covmat(nComps+3,1:nComps)));

figure
plot([cov_HRpos_IC_zscore', cov_HRvel_IC_zscore', cov_HRacc_IC_zscore'],'.')
hold on
plot([1,nComps],[thresh,thresh], '--')
title('Correlation of ICs to head-rotation')
legend('position','velocity','acceleration','threshold')
xlabel('Independant Component Num')
ylabel('Z-score')

ICs_from_HRpos = find(cov_HRpos_IC_zscore > thresh);
ICs_from_HRvel = find(cov_HRvel_IC_zscore > thresh);
ICs_from_HRacc = find(cov_HRacc_IC_zscore > thresh);

tmp = union(ICs_from_HRpos, ICs_from_HRvel);
ICs_from_HR = union(tmp, ICs_from_HRacc);
