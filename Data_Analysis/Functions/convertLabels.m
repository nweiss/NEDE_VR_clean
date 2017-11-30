function newLabels = convertLabels(oldLabels)

% Convert labels from old format to new format
% Old format:
% - target = 1
% - distractor = 2
% 
% New format:
% - target = 1
% - distractor = 0

n = length(oldLabels);
newLabels = nan(n,1);
newLabels(oldLabels == 1) = ones(sum(oldLabels == 1),1);
newLabels(oldLabels == 2) = zeros(sum(oldLabels==2),1);
