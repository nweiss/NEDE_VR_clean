clc; clear all; close all;
addpath('liblsl-Matlab');
addpath('dependancies')

%% instantiate the library
disp('Loading the library...');
lib = lsl_loadlib();

% create an outlet
info = lsl_streaminfo(lib, 'NEDE_Stream_Response', 'Markers', 3, 0,'cf_float32','sdfwerr32432');

outlet = lsl_outlet(info);

disp('Created NEDE_Stream_Response outlet');

% resolve a stream...
disp('Resolving an EEG stream...');
result = {};
while isempty(result) 
    result = lsl_resolve_byprop(lib,'name','NEDE_Stream'); 
    disp('Waiting for stream');
end

% create a new inlet
disp('Opening an inlet...');
inlet = lsl_inlet(result{1});

disp('Now receiving data...');
counter = 2; %start saving data in the second line so that you can compare to the previous line on the first frame
vec = zeros(9000,15);
ts = zeros(9000,1);

while true
    
    [a, b] = inlet.pull_sample(0);
    if ~isempty(a) %if Unity has moved to a new frame
        vec(counter,:) = a;
        ts(counter) = b;
        
        if vec(counter, 5) - vec(counter-1, 5) < 0 %if a billboard has gone out of view
            billboard_num = vec(counter-1, 7);
            classification = randi(2);
            confidence = rand;
            matlab_to_unity = [billboard_num classification, confidence];
            outlet.push_sample(matlab_to_unity);
            
            disp(['billboard number: ', num2str(billboard_num), '    classified as: ', num2str(classification), '    confidence: ', num2str(confidence)]);
        end
        counter = counter + 1;
    end
    
end