clear all; clc; close all;

%% SETTINGS
DATA_VERSION_NO = '6';
SUBJECT = 11;

%% PATHS
ERROR_BAR_PATH = fullfile('..', 'dependancies', 'shadedErrorBar');
addpath(ERROR_BAR_PATH);

%% LOAD DATA


%% EEG plot
electrode = 38;
g = mean(EEG_agg(electrode,:,stimulus_type_agg == 1),3);
h = std(EEG_agg(electrode,:,stimulus_type_agg == 1),[],3);
h = h ./ sqrt(sum(stimulus_type_agg == 1));
i = mean(EEG_agg(electrode,:,stimulus_type_agg == 2),3);
j = std(EEG_agg(electrode,:,stimulus_type_agg == 2),[],3);
j = j ./ sqrt(sum(stimulus_type_agg == 2));

figure
subplot(3,2,1)
H1 = shadedErrorBar(linspace(-500, 1000, length(g)),g, h);
hold on
H2 = shadedErrorBar(linspace(-500, 1000, length(g)),i, j);
legend([H1.mainLine, H2.mainLine], 'targets', 'distractors', 'Location', 'SouthWest')
title('Electrode Fz')
xlabel('Time (ms)')
ylabel('Microvolts')

electrode = 48;
g = mean(EEG_agg(electrode,:,stimulus_type_agg == 1),3);
h = std(EEG_agg(electrode,:,stimulus_type_agg == 1),[],3);
h = h ./ sqrt(sum(stimulus_type_agg == 1));
i = mean(EEG_agg(electrode,:,stimulus_type_agg == 2),3);
j = std(EEG_agg(electrode,:,stimulus_type_agg == 2),[],3);
j = j ./ sqrt(sum(stimulus_type_agg == 2));

subplot(3,2,3)
H3 = shadedErrorBar(linspace(-500, 1000, length(g)),g, h, 'r');
hold on
H4 = shadedErrorBar(linspace(-500, 1000, length(g)),i, j, 'b');
title('Electrode Cz')
xlabel('Time (ms)')
ylabel('Microvolts')
legend([H3.mainLine, H4.mainLine], 'targets', 'distractors','Location', 'SouthWest')


electrode = 31;
g = mean(EEG_agg(electrode,:,stimulus_type_agg == 1),3);
h = std(EEG_agg(electrode,:,stimulus_type_agg == 1),[],3);
h = h ./ sqrt(sum(stimulus_type_agg == 1));
i = mean(EEG_agg(electrode,:,stimulus_type_agg == 2),3);
j = std(EEG_agg(electrode,:,stimulus_type_agg == 2),[],3);
j = j ./ sqrt(sum(stimulus_type_agg == 2));

subplot(3,2,5)
H5 = shadedErrorBar(linspace(-500, 1000, length(g)),g, h, 'r');
hold on
H6 = shadedErrorBar(linspace(-500, 1000, length(g)),i, j, 'b');
title('Electrode Pz')
xlabel('Time (ms)')
ylabel('Microvolts')
legend([H5.mainLine, H6.mainLine], 'targets', 'distractors', 'Location', 'SouthWest')


%% Plots
% Pupil plot
a = mean(10*pupil_agg(stimulus_type_agg == 1,:),1);
b = std(10*pupil_agg(stimulus_type_agg == 1,:),1);
b = b./ sqrt(sum(stimulus_type_agg == 1));
c = mean(10*pupil_agg(stimulus_type_agg == 2,:),1);
d = std(10*pupil_agg(stimulus_type_agg == 2,:),1);
d = d./ sqrt(sum(stimulus_type_agg == 2));

%figure
subplot(3,2,2)
H7 = shadedErrorBar(linspace(-1000,3000,length(a)),a, b, 'r');
hold on
H8 = shadedErrorBar(linspace(-1000,3000,length(a)),c, d, 'b');
legend([H7.mainLine, H8.mainLine], 'targets', 'distractors', 'Location', 'SouthWest')
title('Pupil Dilation')
xlabel('Time (ms)')
ylabel('Area as Percentage of Subject Mean')

%%
% dwell time plot
nTargets = sum(stimulus_type_agg == 1);
nDistractors = sum(stimulus_type_agg == 2);
dt_graph_targets = zeros(1,1500);
dt_graph_distractors = zeros(1,1500);
for i = 1:1500 % cycle through 1500 ms
    for j = 1:length(stimulus_type_agg)
       if stimulus_type_agg(j) == 1
           if dwell_times_agg(j) >= i/1000
                dt_graph_targets(i) = dt_graph_targets(i)+1;
           end
       end
       if stimulus_type_agg(j) == 2
           if dwell_times_agg(j) >= i/1000
                dt_graph_distractors(i) = dt_graph_distractors(i)+1;
           end
       end
   end
end

dt_graph_targets = dt_graph_targets./nTargets;
dt_graph_distractors = dt_graph_distractors./nDistractors;

%figure(4)
subplot(3,2,6)
plot(1:1500, dt_graph_targets, 'r', 1:1500, dt_graph_distractors, 'b')
title('Dwell Times')
xlabel('Time (ms)')
ylabel('Fraction of Trials with Dwell Time > t')
legend('Targets','Distractors', 'Location', 'SouthWest')

%% Head Rotation
l = mean(abs(head_rotation_agg(stimulus_type_agg == 1,:)),1);
m = std(abs(head_rotation_agg(stimulus_type_agg == 1,:)),1);
m = m ./ sqrt(sum(stimulus_type_agg == 1));
n = mean(abs(head_rotation_agg(stimulus_type_agg == 2,:)),1);
o = std(abs(head_rotation_agg(stimulus_type_agg == 2,:)),1);
o = o ./ sqrt(sum(stimulus_type_agg == 2));

%figure
subplot(3,2,4)
H9 = shadedErrorBar(linspace(-500,1500,length(l)),l, m, 'r');
hold on
H10 = shadedErrorBar(linspace(-500,1500,length(n)),n, o, 'b');
legend([H9.mainLine, H10.mainLine],'targets', 'distractors', 'Location', 'NorthWest')
title('Head Rotation')
ylabel('|degrees|')
xlabel('Time (ms)')

EEG = EEG_agg;
head_rotation = head_rotation_agg;
pupil = pupil_agg;
stimulus_type = stimulus_type_agg;
dwell_times = dwell_times_agg;
billboard_cat = billboard_cat_agg;
target_category = target_category_agg;

set(gcf,'Color','w');
