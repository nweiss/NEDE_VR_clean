clear all; close all; clc;

%% Pupil Dilation and Head Rotation
disp('Pupil Dilation & Head Rotation')

a = [(1:10); (11:20); (21:30)];
b = reshape(a, 1,10,3);
c = permute(a, [3, 2, 1]);

ind_time = 3;
ind_trial = 2;
disp(['B: is ' num2str(a(ind_trial,ind_time)) ' same as ' num2str(b(1,ind_time,ind_trial))]);
disp(['C: is ' num2str(a(ind_trial,ind_time)) ' same as ' num2str(c(1,ind_time,ind_trial))]);
disp('')

%% Dwell Time
disp('Dwell Time')

d = (1:10);
e = permute(d, [3,1,2]);

ind_trial = 3;
disp(['is ' num2str(d(1,ind_trial)) ' same as ' num2str(e(1,1,ind_trial))]);
