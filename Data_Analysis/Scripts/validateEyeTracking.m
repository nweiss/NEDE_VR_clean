% visualize LSL streams
clc; close all; clear;
addpath(fullfile('..','MATLAB Viewer'));

tmp = get(0, 'screensize');
screen_width = tmp(3);
screen_height = tmp(4);

% Eye Position
vis_stream('StreamName', 'iViewNG_HMD', 'ChannelRange', 2, 'TimeRange', 10, 'Position', [500,50,500,300]);

% Billboard Boundaries
vis_stream('StreamName', 'NEDE_Stream', 'ChannelRange', 1, 'TimeRange', 10, 'Position', [1000, 50, 500, 300]);