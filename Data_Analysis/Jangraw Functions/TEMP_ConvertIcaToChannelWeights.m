% TEMP_ConvertIcaToChannelWeights
%
% Check if the weights on IC's can be projected back onto channels.
%
% Created 5/30/13 by DJ for one-time use.

i = 9;
load(sprintf('ALLEEG%d_eyeposcorrected.mat',subjects(i))); % ALLEEG
y = loadBehaviorData(subjects(i),sessions_cell{i},'3DS');

bintimes = 100:100:1000; % in ms
binwidth = 100; % in ms
w = zeros(ALLEEG(1).nbchan,size(R(i).w,2),size(R(i).w,3));
for j=1:10
    w(:,:,j) = (R(i).w(:,:,j)' * ALLEEG(1).icaweights * ALLEEG(1).icasphere)';
end

% Plot channel weights
figure;
PlotScalpMaps(cat(3,mean(w,3),var(w,[],3)),ALLEEG(1).chanlocs,[],bintimes+binwidth/2,{'Mean','Variance'});