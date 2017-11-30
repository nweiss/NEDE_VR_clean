
subjects = [18 19 20 22 23];
session_cell = {1:10, 2:11, 1:12, 2:14, [3 6:17]};

% subject = 18; sessions = 1:10;
% subject = 19; sessions = 2:11;
% subject = 20; sessions = 1:12;
% subject = 22; sessions = 2:14;
% subject = 23; sessions = [3 6:17];
usegridconstraints = true;
levelname = 'GridHuge.jpg';
clear R stats
for i=1:numel(subjects)
    subject = subjects(i);
    sessions = session_cell{i};
    fprintf('S%d, #[%s]\n',subject,num2str(sessions))
    load(sprintf('TEMP_ALLEEG%d',subject));
%     load(sprintf('TEMP_ALLEEG%d_old',subject));
    [~,iObjects_eeg_pt,~,~,R(i)] = RunResultsThroughTAG(subject,sessions,ALLEEG);
    [stats(i)] = CalculateImprovement(subject,sessions,levelname,iObjects_eeg_pt,usegridconstraints);
end

