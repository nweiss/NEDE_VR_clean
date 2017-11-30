% TEMP_CheckDwellTimeResults
%
% Perform various checks on the results of TEMP_ClassifyWithDwellTime.
%
% Created 5/30/13 by DJ.

%% Find # targets that made the cutoff?
% R = R_9bin_top10;
for i=1:9;
    [~,order] = sort(R(i).y,'descend');
    subplot(3,3,i); cla; hold on;
    plot(cumsum(R(i).truth(order))./(1:numel(R(i).truth)));
    cutoff = mean(R(i).y) + 1*std(R(i).y);
    nAbove = sum(R(i).y>cutoff);
%     nAbove = numel(R(i).y)/4;
    plot([nAbove nAbove], [0 1],'m--');
    plot(get(gca,'xlim'), [.25 .25],'k--');
    fracTargets = nAbove/numel(R(i).y)
end

%% Plot y values from dwell only vs. eeg only (trial-by-trial scatter plot)
R = R_9bin;
option = 'scatter';
for i=1:9;
    [~,order] = sort(R(i).y,'descend');
    subplot(3,3,i); cla; hold on;
    switch option
        case 'scatter'
        if numel(R(i).truth)==numel(truth_dwell{i})            
            scatter(R(i).y(R(i).truth==0),y_dwell{i}(~truth_dwell{i}),'b.');
            scatter(R(i).y(R(i).truth~=0),y_dwell{i}(truth_dwell{i}),'r.');
        end
        case 'mean'
        meanie(1,1) = mean(R(i).y(R(i).truth==0));        
        meanie(2,1) = mean(R(i).y(R(i).truth~=0));
        meanie(1,2) = mean(y_dwell{i}(~truth_dwell{i}));
        meanie(2,2) = mean(y_dwell{i}(truth_dwell{i}));
        stdie(1,1) = std(R(i).y(R(i).truth==0));        
        stdie(2,1) = std(R(i).y(R(i).truth~=0));
        stdie(1,2) = std(y_dwell{i}(~truth_dwell{i}));
        stdie(2,2) = std(y_dwell{i}(truth_dwell{i}));
        scatter(mean(R(i).y(R(i).truth==0)),mean(y_dwell{i}(~truth_dwell{i})),'b.');        
        rectangle('Position',[meanie(1,1)-0.5*stdie(1,1), meanie(1,2)-0.5*stdie(1,2), stdie(1,1), stdie(1,2)], ...
            'EdgeColor','b');
                scatter(mean(R(i).y(R(i).truth~=0)),mean(y_dwell{i}(truth_dwell{i})),'r.');
        rectangle('Position',[meanie(2,1)-0.5*stdie(2,1), meanie(2,2)-0.5*stdie(2,2), stdie(2,1), stdie(2,2)], ...
            'EdgeColor','r');        
    end
    title(sprintf('S%d',subjects(i)));
    xlabel('y_{EEG}');
    ylabel('y_{eye}');
    if i==1
        legend('target mean +/- std/2', 'distractor mean +/- std/2')
    end
end

%% Check for weight consistency across inner folds
iBin = 4;
for i=1:9 % outer fold
    wts = squeeze(R(1).w(:,iBin,:,i));
    subplot(3,3,i);
    imagesc(wts);
    xlabel('inner folds')
    ylabel('ICs')
end