clear all; close all; clc;
% Instantiate the library
addpath('liblsl-Matlab');
addpath('dependancies')

% instantiate the library
disp('Loading library...');
lib = lsl_loadlib();

% make a new stream outlet
disp('Creating a new streaminfo...');
info = lsl_streaminfo(lib,'Matlab','EEG',66,0,'cf_float32','sdfwerr32432');

disp('Opening an outlet...');
outlet = lsl_outlet(info);

dummy = zeros(66, 385);
exit_cue = ones(66,385);
outlet.push_chunk(dummy);

if false
    outlet.push_chunk(exit_cue);
end

disp('done')