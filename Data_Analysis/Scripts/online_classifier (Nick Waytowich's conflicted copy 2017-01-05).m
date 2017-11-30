% This script performs all the online processing for the VR NEDE
% Experiment.
% If you do not have all the live streams coming in, turn on SIMULATOR_MODE

clc; clear all; close all;

%% Settings
SIMULATOR_MODE = true;
SIMULATION_DURATION = 30; % sec
RANDOM_CLASSIFICATION = true;

%% Load Data
if SIMULATOR_MODE
    load('sample_data.mat');
end

%% Constants

% SMI_pixels is the number of pixels in the y direction that the SMI HMD
% eyetracker can span
smi_pixels_y = 1010;

% field of view of the oculus in degrees (Unity lists the FOV value).
oculus_fov = 106.188;

% horizontal pixels in the oculus. found empirically.
oculus_pixels_x = 1915;

% Use 3 degrees as the permitted discrepency between the eye's point of 
% regard and the billboards border. ie if the POR falls within 3 degrees of
% the boundary of a billboard, it is considered that the subject is fixated
% on the billboard.
allowedDiscrepency = 3 * oculus_pixels_x / oculus_fov; % in pixels

block_duration = 120; % seconds

%% Initialize Data Storage Variables
if SIMULATOR_MODE
    freq_eye = size(eye.time_stamps, 2)/(eye.time_stamps(end) - eye.time_stamps(1));
    freq_unity = size(unity.time_stamps, 2)/(unity.time_stamps(end) - unity.time_stamps(1));
    freq_eeg = size(eeg.time_stamps, 2)/(eeg.time_stamps(end) - eeg.time_stamps(1));
else
    freq_eye = 60;
    freq_unity = 75;
    freq_eeg = 2048;
end

% eye_data is a 37xtime array
%   2) PORx
%   3) PORy
%   23) left pupil radius
%   37) right pupil radius
eye_data = zeros(37, floor(block_duration * freq_eye));
eye_ts = zeros(1, floor(block_duration * freq_eye));

% unity_data is a 15xtime array
%   1) x-position of left edge of billboard (oculus pixels)
%   2) y-position of bottom edge of billboard (oculus pixels)
%   3) billboard width (oculus pixels)
%   4) billboard height (oculus pixels)
%   5) targets = 1; distractors = 2;
%   6) object category (car, schooner, laptop, piano)
%   7) object id (unique to each billboard. can be 0.)
%   8) Oculus Rotation around x-axis
%   9) Oculus Rotation around y-axis
%   10) Oculus Rotation around z-axis
%   11) Car Rotation around x-axis
%   12) Car Rotation around y-axis
%   13) Car Rotation around z-axis
%   14) User button press
%   15) Brake lights on
unity_data = zeros(15, floor(block_duration * freq_unity));
unity_ts = zeros(1, floor(block_duration * freq_unity));

eeg_data = zeros(65, floor(block_duration * freq_eeg));
eeg_ts = zeros(1, floor(block_duration * freq_eeg));

% is the eye POR fixated within the bounding box of a billboard
isFixated = zeros(1, floor(block_duration * freq_eye));

% the boarders of the onscreen billboard in pixels in oculus space. In
% eye-time because we update it every eye-frame to compare the eyeposition
% to the billboard position.
left_border = zeros(1, floor(block_duration * freq_eye));
right_border = zeros(1, floor(block_duration * freq_eye));

billboard_onscreen = zeros(1, floor(block_duration * freq_unity));
billboard_onscreen_eye_frames = zeros(1, floor(block_duration * freq_eye));
billboard_appeared = [];
billboard_fixated_upon = [];
billboard_epoched = [];

fixations.start_times = zeros(1,20);
fixations.stop_times = zeros(1,20);
fixations.stop_frames_eye = zeros(1,20);
fixations.start_frame_eye = zeros(1,20);
fixations.start_frame_unity = zeros(1,20);
fixations.start_frame_eeg = zeros(1,20);
dwell_times = zeros(1,20);

epoch.start_frame_eeg = zeros(1,20);
epoch.stop_frame_eeg = zeros(1,20);

pupil.left = zeros(1, round(freq_eye * 4) + 1);
pupil.right = zeros(1, round(freq_eye * 4) + 1);

eeg_epoch = zeros(64, round(freq_eeg * 1.5) + 1);

%% Main Loop
counter_matlab = 1;
counter_billboard = 1;
counter_epoch = 1;

if SIMULATOR_MODE
    counter_eye = 1;
    counter_unity = 1;
    batch_eeg_start = 1; % the start-frame of the given block of eeg data to be streamed
    batch_eeg_end = round(freq_eeg); % the end-frame of the given block of eeg data to be streamed
    prev_sec = 0;

    max_frame_eye = size(eye.time_series, 2);
    max_frame_unity = size(unity.time_series, 2);
    max_frame_eeg = size(eeg.time_series, 2);
    start_time = eye.time_stamps(1);
end

tic
while true
   timer = toc;
   time = timer + start_time;
   if timer > SIMULATION_DURATION;
       break
   end
   
   % These allow you to keep track of whether each stream was updated on a
   % given loop of Matlab
   eye_update = false;
   unity_update = false;
   eeg_update = false;
   
   % Simulate the data streams in real time
   if SIMULATOR_MODE
       % Simulate frame-by-frame stream of eye data
       if counter_eye <= max_frame_eye
           if time > eye.time_stamps(counter_eye) 
               if counter_eye <= max_frame_eye
                   eye_data([2,3,23,37], counter_eye) = eye.time_series(:,counter_eye);
                   eye_ts(counter_eye) = eye.time_stamps(counter_eye);
                   billboard_onscreen_eye_frames(counter_eye) = unity.time_series(7, counter_unity);
                   eye_update = true;
                   counter_eye = counter_eye + 1;
               end
           end
       end

       % Simulate frame-by-frame stream of unity data
       if counter_unity <= max_frame_unity
           if time > unity.time_stamps(counter_unity)
               if counter_unity <= max_frame_unity
                   unity_data(:, counter_unity) = unity.time_series(:,counter_unity);
                   unity_ts(counter_unity) = unity.time_stamps(counter_unity);
                   % create a vector that is 1 whenever the billboard is
                   % onscreen and 0 otherwise. Use the width of the billboard
                   % as the indicator because it will be non-zero even when
                   % only a fraction of the billboard is onscreen.
                   if unity_data(3, counter_unity) ~= 0
                      billboard_onscreen(counter_unity) = 1;
                   end
                   unity_update = true;
                   counter_unity = counter_unity + 1;
               end
           end
       end

       % Simulate stream of EEG data in 1 second batches
       if floor(timer) ~= prev_sec % if a second has elapsed
           if batch_eeg_end <= max_frame_eeg
                eeg_data(2:65, batch_eeg_start:batch_eeg_end) = eeg.time_series(:,batch_eeg_start:batch_eeg_end);
                eeg_ts(batch_eeg_start:batch_eeg_end) = eeg.time_stamps(batch_eeg_start:batch_eeg_end);
                batch_eeg_start = batch_eeg_start + round(freq_eeg);
                batch_eeg_end = batch_eeg_end + round(freq_eeg);
                prev_sec = floor(timer);
                eeg_update = true;
           end
       end
   end
   
   % Stream in data
   if ~SIMULATOR_MODE
   end
   
   %% Find Fixation Onsets
   % We have to update each of the counters in the loops above because they
   % are each going at different rates. Because of that we need to use
   % counter-1 henceforth.
   if eye_update
        if counter_unity - 1 ~= 0 % for first time through the loop 
            if billboard_onscreen(counter_unity - 1)
                left_border(counter_eye - 1) = unity_data(1, counter_unity - 1) - allowedDiscrepency;
                right_border(counter_eye - 1) = unity_data(1, counter_unity - 1) + unity_data(3, counter_unity - 1) + allowedDiscrepency;
                
                % if there is a new billboard onscreen
                if ~any(billboard_appeared == unity_data(7, counter_unity - 1));
                    % billboard_id stores the id of the billboards that have
                    % been onscreen. Append the new billboard id instead of 
                    % filling in a vector of zeros because the id# can be zero.
                    billboard_appeared = [billboard_appeared unity_data(7, counter_unity - 1)];
                end
            end
        end
        
        % if the por falls between the left and right borders it is
        % fixating
        if eye_data(2, counter_eye - 1) > left_border(counter_eye - 1) && eye_data(2, counter_eye - 1) < right_border(counter_eye - 1)
            isFixated(counter_eye - 1) = 1;
            
            % for the first billboard
            if isempty(billboard_fixated_upon)
                billboard_fixated_upon = unity_data(7, counter_unity - 1);
                fixations.start_times(counter_billboard) = eye_ts(counter_eye - 1);
                fixations.start_frame_eye(counter_billboard) = counter_eye - 1;
                fixations.start_frame_unity(counter_billboard) = counter_unity - 1;
                counter_billboard = counter_billboard + 1;
                
            elseif billboard_fixated_upon(end) ~= billboard_appeared(end)
                billboard_fixated_upon = [billboard_fixated_upon unity_data(7, counter_unity - 1)];
                fixations.start_times(counter_billboard) = eye_ts(counter_eye - 1);
                fixations.start_frame_eye(counter_billboard) = counter_eye - 1;
                fixations.start_frame_unity(counter_billboard) = counter_unity - 1;
                counter_billboard = counter_billboard + 1;
            end
        end
   end
   
   %% Epoch Data and Process Epochs
   % if a billboard has been onscreen that hasnt yet been epoched
   if size(billboard_fixated_upon, 2) >= counter_epoch
       % wait just over three seconds for all of the pupil data to comes in
       if time > fixations.start_times(counter_epoch) + 3.1;
            pupil.left = eye_data(23, fixations.start_frame_eye(counter_epoch) - round(freq_eye) : fixations.start_frame_eye(counter_epoch) + 3 * round(freq_eye));
            pupil.right = eye_data(37, fixations.start_frame_eye(counter_epoch) - round(freq_eye) : fixations.start_frame_eye(counter_epoch) + 3 * round(freq_eye));
            
            tmp = billboard_onscreen_eye_frames .* isFixated == billboard_appeared(counter_epoch);
            fixations.stop_frames_eye(counter_epoch) =  find(diff(tmp) == -1, 1, 'last');
            fixations.stop_times(counter_epoch) = eye_ts(fixations.stop_frames_eye(counter_epoch));
            dwell_times(counter_epoch) = fixations.stop_times(counter_epoch) - fixations.start_times(counter_epoch);
            
            fixations.start_frame_eeg(counter_epoch) = find(diff(eeg_ts < fixations.start_times(counter_epoch)) == -1) + 1;
            epoch.start_frame_eeg(counter_epoch) = fixations.start_frame_eeg(counter_epoch) - round(.5 * freq_eeg);
            epoch.stop_frame_eeg(counter_epoch) = fixations.start_frame_eeg(counter_epoch) + round(2 * freq_eeg);

            eeg_epoch = eeg_data(2:65, epoch.start_frame_eeg(counter_epoch) : epoch.stop_frame_eeg(counter_epoch));
            counter_epoch = counter_epoch + 1;
       end
   end
   
   counter_matlab = counter_matlab + 1;
end

%% Plots
timer = toc;
disp(['Frequency of Matlab: ' num2str(counter_matlab / timer)])

n_eye_frames = find(eye_ts == max(eye_ts));
n_unity_frames = find(unity_ts == max(unity_ts));

figure
plot(eye_ts(1:n_eye_frames), isFixated(1:n_eye_frames))
hold on
plot(unity_ts(1:n_unity_frames), unity_data(1, 1:n_unity_frames))
hold on
plot(unity_ts(1:n_unity_frames), unity_data(1, 1:n_unity_frames) + unity_data(3, 1:n_unity_frames))
hold on
plot(eye_ts(1:n_eye_frames), eye_data(2,1:n_eye_frames))
hold on
plot(eye_ts(1:n_eye_frames), 100*isFixated(1:n_eye_frames))