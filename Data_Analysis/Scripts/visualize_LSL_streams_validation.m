% visualize LSL streams
clc; close all; clear;
addpath(fullfile('..','MATLAB Viewer'));

tmp = get(0, 'screensize');
screen_width = tmp(3);
screen_height = tmp(4);

% Point Of Regard 
vis_stream('StreamName', 'iViewNG_HMD', 'DataScale', .5, 'ChannelRange', [10,24], 'TimeRange', 10, 'Position', [screen_width/2 + 15, 50, screen_width/2 - 25, screen_height/2]);

% Boundaries of Billboard
vis_stream('StreamName', 'NEDE_Stream', 'DataScale', 150, 'ChannelRange', [1,3], 'TimeRange', 10, 'Position', [1000, 50, 500, 300]);
