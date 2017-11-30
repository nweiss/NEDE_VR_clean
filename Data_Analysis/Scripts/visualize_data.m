% visualize LSL streams
clc; close all; clear;
addpath('MATLAB Viewer');

tmp = get(0, 'screensize');
screen_width = tmp(3);
screen_height = tmp(4);

% EEG
vis_stream('StreamName', 'BioSemi', 'DataScale', 20, 'ChannelRange', [1:32], 'TimeRange', 10, 'Position', [0, 50, screen_width/2, screen_height-135]);

% Pupil Dilation
vis_stream('StreamName', 'iViewNG_HMD', 'DataScale', .5, 'ChannelRange', 23, 'TimeRange', 10, 'Position', [screen_width/2 + 15, 50, screen_width/2 - 25, screen_height/2]);

% Head Rotation
%vis_stream('StreamName', 'NEDE_Stream', 'DataScale', 20, 'ChannelRange', [1:15], 'TimeRange', 10, 'Position', [1000, 50, 500, 300]);
