function [fracUnseen, fracRejected] = GetTrialRejectionRates(subjects,sessions_cell)

% Created 8/23/13i by DJ.

nSubjects = numel(subjects);

[nObjects, nSeen, fracUnseen, nRejected, fracRejected] = deal(nan(1,nSubjects));

for i=1:nSubjects;
    fprintf('--- Subject %d/%d ---\n',i,numel(subjects));
    load(sprintf('ALLEEG%d_NoeogEpochedIcaCropped.mat',subjects(i))); % ALLEEG
    nObjects(i) = numel(sessions_cell{i})*20;
    nSeen(i) = length(ALLEEG(1).etc.rejectepoch);
    fracUnseen(i) = (nObjects(i)-nSeen(i))/nObjects(i);
    nRejected(i) = sum(ALLEEG(1).etc.rejectepoch);
    fracRejected(i) = nRejected(i)/nSeen(i);
    fprintf('%d/%d = %g objects not seen\n',nObjects(i)-nSeen(i),nObjects(i),fracUnseen(i));
    fprintf('%d/%d = %g seen objects rejected\n',nRejected(i),nSeen(i),fracRejected(i));
end

%% Averages
fprintf('On average, %g%% of objects were not fixated\n',mean(fracUnseen)*100);
fprintf('On average, %g%% of trials were rejected for artifacts\n',mean(fracRejected)*100);