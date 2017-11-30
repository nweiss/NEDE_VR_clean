% TEMP_PlotTargetFracPrediction
% Created 7/12/13 by DJ for one-time use.

x = 0:0.002:0.18;
y = hist(outScore,x);
cumy = cumsum(y)/sum(y);

% get 1st half (distractors only)
halfcumy = cumy(cumy<0.5);
fakesigmoid = [halfcumy, 1-fliplr(halfcumy)];
fakesigmoid = [fakesigmoid, ones(1,numel(x)-numel(fakesigmoid))];

figure;
plot(x,[cumy; fakesigmoid]');
hold on
fracDist = mean(distractors); % fraction of objects that are distractors
plot([x(1) x(end)],[fracDist fracDist],'k--');
fivepct = outScore(round(numel(outScore)*0.95));
fiftypct = median(outScore);
ninetyfivepct = 2*fiftypct-fivepct;
plot([ninetyfivepct, ninetyfivepct],[0 1],'m--');
title(sprintf('Subject %d',subject));
xlabel('Score');
ylabel('Fraction of trials');
legend('Actual trials','fake sigmoid','true target cutoff','95% score cutoff');