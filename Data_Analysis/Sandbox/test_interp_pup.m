% Test the interpPup function for the interpolation of the pupil
clear all; clc; close all;

function_path = fullfile('..','Functions');
addpath(function_path);

% Artificially create pupil_vec
n = 241;
x = linspace(1,50,n);
pupil_vec = 1.7+.25*rand(1,n)+.25*sin(x);

% Artifitially insert blinks
pupil_vec(1:10) = ones(1,10);
pupil_vec(101:110) = ones(1,10);
pupil_vec(201:210) = 3*ones(1,10);
pupil_vec(n-9:n) = 3*ones(1,10);

pupil_interp = interpBlinks(pupil_vec);

figure
plot(pupil_vec)
hold on
plot(pupil_interp)
legend('raw', 'interpolated')
ylim([0,3.5])
title('interpolation during blinks')