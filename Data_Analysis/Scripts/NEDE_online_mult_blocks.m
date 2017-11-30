% This script performs all the online processing for the VR NEDE
% Experiment.
clc; clear all; close all;

%% Settings
% Specify which systems are connected
PYTHON = false;
UNITY = true;
EEG_EYE = true;
SIMULATION_DURATION = 120; % seconds. Only used in 'matlab' mode. Simulation dataset is 113s.
SAVE_RAW_DATA = false;
SAVE_EPOCHED_DATA = false;
MARKER_STREAM = false;
PLOTS = false;

SUBJECT_ID = '8';
BLOCK = '1';

%% Settings Error Check
% Check for valid MODE
if ~(strcmp(MODE, 'matlab') || strcmp(MODE, 'matlab+unity') || strcmp(MODE, 'matlab+unity+inputstreams'))
    error('Invalid entry for MODE. Valid entries are: "matlab", "matlab+unity", or "matlab+unity+inputstreams"')
end
disp(['MODE: ' MODE])

if EEG_EYE && ~UNITY
    error('Invalid settings. To run with EEG and EYE inputs, UNITY must be running.')
end
%% Load Data for Simulation
if strcmp(MODE, 'matlab')
    LOAD_PATH = fullfile('..','Data','raw_mat', ['subject_', SUBJECT_ID], ['s', SUBJECT_ID, '_b', BLOCK, '_raw.mat']);
    load(LOAD_PATH);
end

%% Constants
smi_pixels_y = 1010; % Number of pixels in the y direction that the SMI HMD eyetracker spans
oculus_fov = 106.188; % Field of view of the oculus in degrees (Unity lists the FOV value).
oculus_pixels_x = 1915; % Number of pixels in the x direction in the oculus. found empirically comparing oculus to SMI.

% Permitted discrepency between the eye's point of regard and the billboards border while eye considered fixated
allowedDiscrepency = 3 * oculus_pixels_x / oculus_fov; % in pixels

% Upper limit of block duration. Used to construct empty matrices to be
% filled as data is streamed in.
block_duration = 140; % seconds. This is padded to allow room between when you start matlab and unity.
trials_per_block = 20;

freq_eye = 60;
freq_unity = 75;
freq_eeg = 2048;

%% Create the Filters
% High Pass Filter for EEG
Fstop = .5;         % Stopband Frequency
Fpass = 3;           % Passband Frequency
Astop = 60;          % Stopband Attenuation (dB)
Apass = 1;           % Passband Ripple (dB)
match = 'passband';  % Band to match exactly

h_hp  = fdesign.highpass(Fstop, Fpass, Astop, Apass, 2048);
Hd_hp = design(h_hp, 'cheby2', 'MatchExactly', match);
%fvtool(Hd_hp)

% Low Pass Filter for EEG
Fpass = 50;          % Passband Frequency
Fstop = 55;          % Stopband Frequency
Apass = 1;           % Passband Ripple (dB)
Astop = 60;          % Stopband Attenuation (dB)
match = 'stopband';  % Band to match exactly

h_lp  = fdesign.lowpass(Fpass, Fstop, Apass, Astop, freq_eeg);
Hd_lp = design(h_lp, 'cheby2', 'MatchExactly', match);
%fvtool(Hd_lp)

% Low Pass Filter for pupil data
Fpass = 3;          % Passband Frequency
Fstop = 6;          % Stopband Frequency
Apass = 1;           % Passband Ripple (dB)
Astop = 60;          % Stopband Attenuation (dB)
match = 'stopband';  % Band to match exactly

h_lp_pupil  = fdesign.lowpass(Fpass, Fstop, Apass, Astop, freq_eye);
Hd_lp_pupil = design(h_lp_pupil, 'cheby2', 'MatchExactly', match);
%fvtool(Hd_lp_pupil)

%% Instantiate the Data Streams
% Load the LSL libraries
if strcmp(MODE, 'matlab+unity') || strcmp(MODE, 'matlab+unity+inputstreams') || UNITY
    % Instantiate the library
    addpath(fullfile('..','liblsl-Matlab'));
    addpath('..','dependancies')
    lib = lsl_loadlib();
end

% % Create outlet stream to unity
% if strcmp(MODE, 'matlab+unity') || strcmp(MODE, 'matlab+unity+inputstreams')
%     % create an outlet
%     info = lsl_streaminfo(lib, 'NEDE_Stream_Response', 'Markers', 3, 0,'cf_float32','sdfwerr32432');
%     outlet = lsl_outlet(info);
%     disp('Opened outlet: NEDE_Stream_Response');
% end

%Create outlet stream to python
if PYTHON
    info = lsl_streaminfo(lib,'Matlab','data_epochs',66,0,'cf_float32', 'Matlab2015a');
    outlet = lsl_outlet(info, 385, 385);
    disp('Opened outlet: Matlab');
end

if MARKER_STREAM
    info = lsl_streaminfo(lib,'FixationOnsetMarkers','Markers',1,0,'cf_string','Matlab2015a');
    outlet_markers = lsl_outlet(info);
    disp('Markers outlet created')
end

% Create EEG and Eye input streams
if strcmp(MODE, 'matlab+unity+inputstreams')
    result_eye = {};
    while isempty(result_eye) 
        result_eye = lsl_resolve_byprop(lib,'name','iViewNG_HMD'); 
        disp('Waiting for: EYE stream');
    end
    
    result_eeg = {};
    while isempty(result_eeg) 
        result_eeg = lsl_resolve_byprop(lib,'name','BioSemi'); 
        disp('Waiting for: EEG stream');
    end

    % create inlets
    inlet_eye = lsl_inlet(result_eye{1});
    disp('Opened inlet: EYE');

    inlet_eeg = lsl_inlet(result_eeg{1});
    disp('Opened inlet: EEG');
end

% Create Unity input stream
if strcmp(MODE, 'matlab+unity') || strcmp(MODE, 'matlab+unity+inputstreams')
    % resolve streams
    result_unity = {};
    while isempty(result_unity) 
        result_unity = lsl_resolve_byprop(lib,'name','NEDE_Stream'); 
        disp('Waiting for: UNITY stream');
    end    
    inlet_unity = lsl_inlet(result_unity{1});
    disp('Opened inlet: Unity');
end
disp('***All streams resolved***');

% Outer loop
while true
    % Look for start cue from unity
    disp('Waiting for start cue from unity...');
    if strcmp(MODE, 'matlab+unity') || strcmp(MODE, 'matlab+unity+inputstreams')
        while true
            [a, b] = inlet_unity.pull_sample(0);
            if ~isempty(a)
                if a(end) == 1
                    disp('Start cue from Unity received!')
                    break
                end
            end
        end
    end

    % Initialize Data Storage Variables
    % eye_data is a 37xtime array
    %   2) PORx
    %   3) PORy
    %   23) left pupil radius
    %   37) right pupil radius
    eye_data = zeros(37, floor(block_duration * freq_eye));
    eye_ts = zeros(1, floor(block_duration * freq_eye));

    % unity_data is a 16xtime array
    %   1) x-position of left edge of billboard (oculus pixels)
    %   2) y-position of bottom edge of billboard (oculus pixels)
    %   3) billboard width (oculus pixels)
    %   4) billboard height (oculus pixels)
    %   5) Stimulus type: targets = 1; distractors = 2;
    %   6) object category (car, schooner, laptop, piano)
    %   7) object id (unique to each billboard. can be 0.)
    %   8) Oculus Rotation around x-axis
    %   9) Oculus Rotation around y-axis (horizontal turn of the head)
    %   10) Oculus Rotation around z-axis
    %   11) Car Rotation around x-axis
    %   12) Car Rotation around y-axis (horizontal turn of the car)
    %   13) Car Rotation around z-axis
    %   14) User button press
    %   15) Brake lights on
    %   16) Block start/end flag (1 for block start, 2 for block end)

    unity_data = nan(16, floor(block_duration * freq_unity));
    unity_ts = nan(1, floor(block_duration * freq_unity));

    % is the eye POR fixated within the bounding box of a billboard
    isFixated = zeros(1, floor(block_duration * freq_eye));

    % the boarders of the onscreen billboard in pixels in oculus space. In
    % eye-time because we update it every eye-frame to compare the eyeposition
    % to the billboard position.
    left_border = zeros(1, ceil(block_duration * freq_eye));
    right_border = zeros(1, ceil(block_duration * freq_eye));

    Billboard.isOnscreen = zeros(1, floor(block_duration * freq_unity));
    Billboard.id_eye_frames = zeros(1, floor(block_duration * freq_eye));
    Billboard.id_unity_frames = zeros(1, floor(block_duration * freq_unity));
    Billboard.id = []; % Records the ids as they come on screen
    Billboard.fixated_upon = []; % Records the ids as they are fixated upon
    Billboard.epoched = []; % Records the ids as they are epoched
    Billboard.stimulus_type = zeros(1, trials_per_block);
    Billboard.category = zeros(1, trials_per_block);

    Fixation.start_times = zeros(1,trials_per_block);
    Fixation.stop_times = zeros(1,trials_per_block);
    Fixation.stop_frames_eye = zeros(1,trials_per_block);
    Fixation.start_frame_eye = zeros(1,trials_per_block);
    Fixation.start_frame_unity = zeros(1,trials_per_block);
    Fixation.start_frame_eeg = zeros(1,trials_per_block);

    dwell_times = zeros(1,trials_per_block);
    head_rotation = zeros(trials_per_block, round(freq_unity*2)+2);

    Epoch.start_frame_eeg = zeros(1,trials_per_block);
    Epoch.stop_frame_eeg = zeros(1,trials_per_block);
    Epoch.complete = zeros(66,385);

    Pupil.left = zeros(1, round(freq_eye * 4) + 1);
    Pupil.right = zeros(1, round(freq_eye * 4) + 1);
    Pupil.avg = zeros(1, round(freq_eye * 4) + 1);
    Pupil.isBlink = zeros(1, round(freq_eye * 4) + 1);
    Pupil.isBlink_padded = zeros(1, round(freq_eye * 4) + 1);
    Pupil.processed = zeros(trials_per_block, round(freq_eye * 4) + 1);
    Pupil.baseline = 0;

    eeg_data = zeros(64, floor(block_duration * freq_eeg));
    eeg_ts = zeros(1, floor(block_duration) * freq_eeg);
    EEG.epoch = zeros(64, round(freq_eeg * 1.5) + 1);
    EEG.baseline = zeros(64, 1);
    EEG.filtered = zeros(64, round(freq_eeg * 1.5) + 1);
    EEG.downsampled = zeros(64, floor(size(EEG.filtered, 2)/8)+1);
    EEG.processed = zeros(64, size(EEG.downsampled, 2), trials_per_block);
    EEG.time_epoch = linspace(-500, 1000, size(EEG.downsampled, 2));

    n_chan = 64;

    %% Main Loop
    % The counters run in a non-traditional way. counter_matlab counts the
    % number of times through the large while loop. In each run through
    % that loop, we check to see if there has been an update to each of the
    % unity, eye-tracking, and eeg input streams. If there has, we update the
    % appropriate counter and save the data using the counter as an index. In
    % order for the counter to be the correct index in the data processing loops, we
    % update the counter at the start of the loop, prior to saving the data. We
    % start the counters at 1 and have separate markers to track when we are
    % still on the first frame of each stream in order to allow us to avoid
    % initializing the counters at 0 and having an "if" statement for every
    % time we use a counter as an index to prevent it from indexing into 0.
    counter_matlab = 1;
    counter_billboard = 1;
    counter_epoch = 1;
    counter_eye = 1;
    counter_unity = 1;

    first_frame_unity = true;
    first_frame_eye = true;
    first_frame_eeg = true;

    if strcmp(MODE, 'matlab')
        batch_eeg_start = 1; % the start-frame of the given block of eeg data to be streamed. Start at 2 to match indexing of other streams.
        batch_eeg_end = round(freq_eeg)+1; % the end-frame of the given block of eeg data to be streamed
        prev_sec = 0;
        max_frame_eye = size(eye.time_series, 2);
        max_frame_unity = size(unity.time_series, 2);
        max_frame_eeg = size(eeg.time_series, 2);
        start_time = eye.time_stamps(1);
    end

    if strcmp(MODE, 'matlab+unity') || strcmp(MODE, 'matlab+unity+inputstreams')
        counter_eeg = 1;
    end

    tic
    while true
        timer = toc;
        % Limit the simulation to SIMULATION_DURATION
        if strcmp(MODE, 'matlab')
            % Use time in 'matlab' mode to load each stream at the appropriate
            % frequency.
            time = timer + start_time;
            if timer > SIMULATION_DURATION;
                break
            end
        end

       % These allow you to keep track of whether each stream was updated on a
       % given loop of Matlab
       update_eye = false;
       update_unity = false;
       update_eeg = false;

       %% Simulate the data streams in real time
       if strcmp(MODE, 'matlab')
           % Simulate frame-by-frame stream of eye data
           if counter_eye < max_frame_eye
               if time > eye.time_stamps(counter_eye)
                   if counter_eye <= max_frame_eye
                       update_eye = true;
                       if ~first_frame_eye
                           counter_eye = counter_eye + 1;
                       end
                       if first_frame_eye
                            first_frame_eye = false;
                       end
                       % eye_data([2,3,23,37], counter_eye) = eye.time_series(:,counter_eye);
                       eye_data(:, counter_eye) = eye.time_series(:,counter_eye);
                       eye_ts(counter_eye) = eye.time_stamps(counter_eye);
                   end
               end
           end

           % Simulate frame-by-frame stream of unity data
           if counter_unity < max_frame_unity
               if time > unity.time_stamps(counter_unity)
                   if counter_unity <= max_frame_unity
                       update_unity = true;
                       if ~first_frame_unity
                           counter_unity = counter_unity + 1;
                       end
                       if first_frame_unity
                           first_frame_unity = false;
                       end
                       unity_data(:, counter_unity) = unity.time_series(:,counter_unity);
                       unity_ts(counter_unity) = unity.time_stamps(counter_unity);
                   end
               end
           end

           % Simulate stream of EEG data in 1 second batches
           if floor(timer) ~= prev_sec % if a second has elapsed
               if batch_eeg_end <= max_frame_eeg
                    update_eeg = true;
                    eeg_data(:, batch_eeg_start:batch_eeg_end) = eeg.time_series(2:65,batch_eeg_start:batch_eeg_end);
                    eeg_ts(batch_eeg_start:batch_eeg_end) = eeg.time_stamps(batch_eeg_start:batch_eeg_end);
                    batch_eeg_start = batch_eeg_start + round(freq_eeg);
                    batch_eeg_end = batch_eeg_end + round(freq_eeg);
                    prev_sec = floor(timer);
               end
           end
       end

       %% Stream in data
       if strcmp(MODE, 'matlab+unity') || strcmp(MODE, 'matlab+unity+inputstreams')
            [a, b] = inlet_unity.pull_sample(0);
            if ~isempty(a) %if Unity has moved to a new frame
                update_unity = true;
               if ~first_frame_unity
                   counter_unity = counter_unity + 1;
               end
               if first_frame_unity
                    first_frame_unity = false;
                    disp('***Now receiving data***');
               end
                unity_data(:, counter_unity) = a;
                unity_ts(counter_unity) = b;
            end
       end
       if strcmp(MODE, 'matlab+unity+inputstreams')
           if ~first_frame_unity %only start collecting eye&eeg data once unity has started. Otherwise, you exceed the allocated space for the data streams
               [a, b] = inlet_eye.pull_sample(0);
               if ~isempty(a) %if Unity has moved to a new frame
                   update_eye = true;
                   if ~first_frame_eye
                      counter_eye = counter_eye + 1;
                   end
                   if first_frame_eye
                      first_frame_eye = false;
                   end            
                   eye_data(:,counter_eye) = a;
                   eye_ts(counter_eye) = b;
                end

            [a, b] = inlet_eeg.pull_sample(0);
            if ~isempty(a) %if Unity has moved to a new frame
                update_eeg = true;
                if ~first_frame_eeg
                   counter_eeg = counter_eeg + 1;
               end
               if first_frame_eeg
                    first_frame_eeg = false;
               end   
                eeg_data(:,counter_eeg) = a(2:65);
                eeg_ts(counter_eeg) = b;
            end
           end
       end

        % Exit loop when the cue is received from Matlab   
        if strcmp(MODE, 'matlab+unity+inputstreams')
            if unity_data(end,counter_unity) == 2;
                break
            end
        end

       %% Find Fixation Onsets
        % Basic pre-processing
        if update_unity
            Billboard.id_unity_frames(counter_unity) = unity_data(7, counter_unity);
            % create a vector that is 1 whenever the billboard is
            % onscreen and 0 otherwise. Use the width of the billboard
            % as the indicator because it will be non-zero even when
            % only a fraction of the billboard is onscreen.
            if unity_data(3, counter_unity) ~= 0
                Billboard.isOnscreen(counter_unity) = 1;
            end
        end

        if update_eye
            Billboard.id_eye_frames(counter_eye) = unity_data(7, counter_unity);
            % if there is a billboard onscreen
            if Billboard.isOnscreen(counter_unity)
                left_border(counter_eye) = unity_data(1, counter_unity) - allowedDiscrepency;
                right_border(counter_eye) = unity_data(1, counter_unity) + unity_data(3, counter_unity) + allowedDiscrepency;
            end

            % if the por is fixated on the billboard
            if eye_data(2, counter_eye) > left_border(counter_eye) && eye_data(2, counter_eye) < right_border(counter_eye)
                isFixated(counter_eye) = 1;

                % if the billboard being fixated upon is new
                if ~any(Billboard.id == unity_data(7, counter_unity));
                    % Append the new billboard id instead of filling in a 
                    % vector of zeros because the id# can be zero.
                    Billboard.id = [Billboard.id unity_data(7, counter_unity)];
                    Billboard.stimulus_type(counter_billboard) = unity_data(5, counter_unity);
                    Billboard.category(counter_billboard) = unity_data(6, counter_unity);
                end

                % for the first billboard
                if isempty(Billboard.fixated_upon)
                    Billboard.fixated_upon = unity_data(7, counter_unity);
                    Fixation.start_times(counter_billboard) = eye_ts(counter_eye);
                    Fixation.start_frame_eye(counter_billboard) = counter_eye;
                    Fixation.start_frame_unity(counter_billboard) = counter_unity;
                    counter_billboard = counter_billboard + 1;

                elseif Billboard.fixated_upon(end) ~= Billboard.id(end)
                    Billboard.fixated_upon = [Billboard.fixated_upon unity_data(7, counter_unity)];
                    Fixation.start_times(counter_billboard) = eye_ts(counter_eye);
                    Fixation.start_frame_eye(counter_billboard) = counter_eye;
                    Fixation.start_frame_unity(counter_billboard) = counter_unity;
                    counter_billboard = counter_billboard + 1;
                end
            end
       end

       %% Epoch Data
       % Once per billboard
       if size(Billboard.fixated_upon, 2) >= counter_epoch
           % wait just over three seconds for all of the pupil data to comes in
           if eye_ts(counter_eye) > Fixation.start_times(counter_epoch) + 3.1;
                % epoch the pupil data
                Pupil.left = eye_data(23, Fixation.start_frame_eye(counter_epoch) - round(freq_eye) : Fixation.start_frame_eye(counter_epoch) + 3 * round(freq_eye));
                Pupil.right = eye_data(37, Fixation.start_frame_eye(counter_epoch) - round(freq_eye) : Fixation.start_frame_eye(counter_epoch) + 3 * round(freq_eye));

                % find the dwell times
                Fixation.stop_frames_eye(counter_epoch) = find(diff(isFixated) == -1, 1, 'last');
                Fixation.stop_times(counter_epoch) = eye_ts(Fixation.stop_frames_eye(counter_epoch));
                dwell_times(counter_epoch) = Fixation.stop_times(counter_epoch) - Fixation.start_times(counter_epoch);

                % epoch the head tracking data
                oculus_rotation = unity_data(9, Fixation.start_frame_unity(counter_epoch)-round(.5*freq_unity):Fixation.start_frame_unity(counter_epoch)+round(1.5*freq_unity));
                car_rotation = unity_data(12, Fixation.start_frame_unity(counter_epoch)-round(.5*freq_unity):Fixation.start_frame_unity(counter_epoch)+round(1.5*freq_unity));

                % epoch the eeg data
                % There is a jitter in the eeg_ts such that occassionally you
                % will get two locations for where the fixation onset is. This
                % jitter is on the order of 5  milliseconds though and only 
                % occurs in about 1/100 billboards. If you get multiple values
                % for start_frame_eeg, just take the first one.
                tmp = find(diff(eeg_ts < Fixation.start_times(counter_epoch)) == -1) + 1;
                if length(tmp) == 1
                    Fixation.start_frame_eeg(counter_epoch) = tmp;
                elseif length(tmp > 1)
                    Fixation.start_frame_eeg(counter_epoch) = tmp(1);
                end
                %Fixation.start_frame_eeg(counter_epoch) = find(diff(eeg_ts < Fixation.start_times(counter_epoch)) == -1) + 1;
                Epoch.start_frame_eeg(counter_epoch) = Fixation.start_frame_eeg(counter_epoch) - round(.5 * freq_eeg);
                Epoch.stop_frame_eeg(counter_epoch) = Fixation.start_frame_eeg(counter_epoch) + round(1 * freq_eeg);
                EEG.epoch = eeg_data(:, Epoch.start_frame_eeg(counter_epoch) : Epoch.stop_frame_eeg(counter_epoch));

                %% Process Pupil Data
                % Use the average of the left and right pupil
                Pupil.avg = mean([Pupil.left; Pupil.right], 1);

                % Remove blinks
                Pupil.isBlink = Pupil.avg < 1.5 | Pupil.avg > 2.25;

                %pad the blink data so that anything within 3 frames of a blink is
                %considered a blink too
                % look three frames to the right of each data point
                Pupil.isBlink_padded = zeros(1, size(Pupil.isBlink, 2));

                for i = 1:size(Pupil.isBlink, 2) - 5
                    if sum(Pupil.isBlink(i:i+5)) >= 1
                        Pupil.isBlink_padded(i) = 1;
                    end
                end
                % look three frames to the left of each data point
                for i = 6:size(Pupil.isBlink, 2)
                    if sum(Pupil.isBlink(i-5:i)) >= 1
                        Pupil.isBlink_padded(i) = 1;
                    end
                end
                % if there is any blink on the ends, call the whole end a blink
                if sum(Pupil.isBlink(1:5)) >= 1
                    Pupil.isBlink_padded(1:5) = ones(1,5);         
                end
                if sum(Pupil.isBlink(size(Pupil.isBlink,2)-4:end)) >= 1
                    Pupil.isBlink_padded(size(Pupil.isBlink,2)-4:end) = ones(1,5);
                end

                blink_starts = find(diff(Pupil.isBlink_padded) == 1) + 1;
                blink_stops = find(diff(Pupil.isBlink_padded) == -1) + 1;
                if Pupil.isBlink_padded(1) == 1
                    blink_starts = [1, blink_starts];
                end
                if Pupil.isBlink_padded(end) == 1
                    blink_stops = [blink_stops size(Pupil.isBlink_padded, 2)];
                end
                nBlinks = size(blink_starts, 2);

                % if the first frame is within a blink, have the pupil radius
                % flat at whatever value it takes on after the blink
                if ~isempty(blink_starts)
                    if blink_starts(1) == 1
                        Pupil.avg(blink_starts(1):blink_stops(1)) = Pupil.avg(blink_stops(1))*ones(1,blink_stops(1));
                    end
                    if blink_stops(end) == size(Pupil.isBlink,2);
                        Pupil.avg(blink_starts(end):blink_stops(end)) = Pupil.avg(blink_starts(end))*ones(1,blink_stops(end)-blink_starts(end)+1);
                    end

                    for i = 1:nBlinks
                        Pupil.avg(blink_starts(i):blink_stops(i)) = linspace(Pupil.avg(blink_starts(i)), Pupil.avg(blink_stops(i)), blink_stops(i)-blink_starts(i)+1);
                    end
                end

                % Lowpass filter the pupil data
                Pupil.avg = filtfilt(Hd_lp_pupil.sosMatrix, Hd_lp_pupil.ScaleValues, Pupil.avg);

                % Baseline the pupil data to the second prior to first fixation
                Pupil.baseline = mean(Pupil.avg(1:floor(freq_eye * 1)));
                Pupil.processed(counter_epoch,:) = Pupil.avg - Pupil.baseline;

                %% Process head rotation data
                % The rotation of the oculus that is recorded is the rotation
                % relative to the rotation of the car. Correct for that.
                % if the car rotation is 0
                if max(car_rotation) < 1
                    for i = 1:length(oculus_rotation)
                        if oculus_rotation(i) > 180
                            head_rotation(counter_epoch,i) = oculus_rotation(i)-360;
                        else
                            head_rotation(counter_epoch,i) = oculus_rotation(i);
                        end
                    end
                else
                    head_rotation(counter_epoch,:) = oculus_rotation - 180;
                end

                %% Process EEG Data
                EEG.filtered = filtfilt(Hd_hp.sosMatrix, Hd_hp.ScaleValues, EEG.epoch')';
                EEG.filtered = filtfilt(Hd_lp.sosMatrix, Hd_lp.ScaleValues, EEG.filtered')';

                EEG.downsampled = downsample(EEG.filtered', 8)';
                EEG.baseline = mean(EEG.downsampled(:, 1:floor(256*.2)), 2);
                for i = 1:n_chan
                    EEG.processed(i,:,counter_epoch) = EEG.downsampled(i,:) - EEG.baseline(i);  
                end

               %% Send Epoched Data to Python
               if UNITY
                   % Package all the data from one epoch into a 65x385 matrix
                   % to be sent to Unity. The data has the following format:
                   %    1 - (1:64,1:385) is all EEG data.
                   %    2 - (65,1:150) is the head rotation
                   %    3 - (65,151:385) is zeros
                   %    3 - (66,1) is the stimulus type (1=target, 2=distractor)
                   %    4 - (66,2) is the billboard id (unique identifier in unity for finding the position of the billboard)                
                   %    5 - (66,3) is the dwell time
                   %    6 - (66,4) is the billboard category (1=car, 2=grand piano, 3=laptops, 4=schooners)
                   %    7 - (66,5:245) is the pupil dilation
                   %    8 - (66,246:385) is zeros
                   %    9 - (66,385) is the exit cue. It is 0 throughout the
                   %    main loop, but is 1 when cuing python that matlab has
                   %    finished its main loop
                   Epoch.complete = zeros(size(EEG.processed,1)+2, size(EEG.processed,2));
                   Epoch.complete(1:size(Epoch.complete,1)-2,:) = EEG.processed(:,:,counter_epoch);
                   Epoch.complete(size(Epoch.complete,1)-1,1:size(head_rotation,2)) = head_rotation(counter_epoch,:);
                   Epoch.complete(end,1) = Billboard.stimulus_type(counter_epoch);
                   Epoch.complete(end,2) = Billboard.id(counter_epoch);
                   Epoch.complete(end,3) = dwell_times(counter_epoch);
                   Epoch.complete(end,4) = Billboard.category(counter_epoch);
                   Epoch.complete(end,5:size(Pupil.processed,2)+4) = Pupil.processed(counter_epoch,:);

                   % Push data to python
                   if PYTHON
                       outlet.push_chunk(Epoch.complete);               
                       disp(['Pushed Data: BillboardID-' num2str(Billboard.id(counter_epoch))])
                   end

               end
                if MARKER_STREAM
                    outlet_markers.push_sample({'fixation_start'}, Fixation.start_times(counter_epoch));
                    if Billboard.stimulus_type(counter_epoch) == 1
                        outlet_markers.push_sample({'target'}, Fixation.start_times(counter_epoch));
                    else
                        outlet_markers.push_sample({'distractor'}, Fixation.start_times(counter_epoch));
                    end
                end

               disp(['completed epoch: ' num2str(counter_epoch)])
               counter_epoch = counter_epoch + 1;

           end
       end

       %% Classifier for 'matlab+unity' mode
       if strcmp(MODE, 'matlab+unity') && counter_unity~=1
           % Once per billboard:
           if (unity_data(7,counter_unity)==0 && unity_data(7,counter_unity-1)~=0 && ~any(Billboard.id == unity_data(7,counter_unity-1))) %if a billboard has gone out of view
                billboard_num = unity_data(7,counter_unity-1);
                if isempty(Billboard.id)
                    Billboard.id = billboard_num;
                else
                    Billboard.id = [Billboard.id billboard_num];
                end
                classification = randi(2);
                confidence = rand;
                matlab_to_unity = [billboard_num classification, confidence];
                outlet.push_sample(matlab_to_unity)
                disp('pushed to python')
                disp(['billboard number: ', num2str(billboard_num), '    classified as: ', num2str(classification), '    confidence: ', num2str(confidence)]);
            end
       end

       counter_matlab = counter_matlab + 1;
    end

    %% Close session
    % Create a vector of the target category for the entire block
    % (ie a value of 1 indicates that the target for this block is cars. 4 possible entries.)
    tmp = find(unity_data(5,:) == 1, 1, 'first');
    if ~isempty(tmp)
        target_category = unity_data(6,tmp);
    end
    % if no targets appeared in a block
    if isempty(tmp)
        tmp2 = unique(unity_data(6,:));
        for i = 1:4
            if sum(tmp2 == i) == 0
                target_category = i;
            end
        end
    end

    % Find the number of billboards and targets that were passed (but not necessarily fixated upon)
    nTargetsPassed = 0;
    Billboard.ids_passed = unique(unity_data(7,~isnan(unity_data(7,:))));
    Billboard.ids_passed(Billboard.ids_passed == -1) = [];
    nBillboardsPassed = length(Billboard.ids_passed);
    Billboard.pass_onsets = nan(nBillboardsPassed,1);
    for i = 1:nBillboardsPassed
         Billboard.pass_onsets(i) = find(unity_data(7,:) == Billboard.ids_passed(i), 1, 'first');
    end
    Billboard.nTargetsPassed = sum(unity_data(5,Billboard.pass_onsets)==1);

    % Push a chunk that cues python that the stream has ended
    if PYTHON
        tmp = zeros(size(Epoch.complete,1),size(Epoch.complete,2));
        tmp(end,end) = 1;
        tmp(end,end-1) = target_category;
        outlet.push_chunk(tmp);
    end
    % pause(1); % Give python time to pick up the exit cue before closing the stream
    % outlet.delete()
    % disp('outlet closed')

    %% Plots

    if strcmp(MODE, 'matlab') || strcmp(MODE, 'matlab+unity+inputstreams')
        timer = toc;
        disp(['Frequency of Matlab: ' num2str(counter_matlab / timer)])

        n_eye_frames = find(eye_ts == max(eye_ts));
        n_unity_frames = find(unity_ts == max(unity_ts));

        start_time = eye_ts(1);
    end

    %% figure
    if PLOTS
        plot(unity_ts(1:n_unity_frames)-start_time, unity_data(1, 1:n_unity_frames))
        hold on
        plot(unity_ts(1:n_unity_frames)-start_time, unity_data(1, 1:n_unity_frames) + unity_data(3, 1:n_unity_frames))
        hold on
        plot(eye_ts(1:n_eye_frames)-start_time, eye_data(2,1:n_eye_frames))
        hold on
        plot(eye_ts(1:n_eye_frames)-start_time, 500*isFixated(1:n_eye_frames), '.')
        title('Eye Position vs Billboard Position')
        xlabel('time')
        ylabel('horizontal pixels')
        legend('billboard left border','billboard right border','eye POR','isFixated')
    end

    %% Save Data

    % Warn the user if you are getting extreme EEG values

    max_eeg = max(max(max(EEG.processed, [], 2),[],1),[],3);
    min_eeg = min(min(min(EEG.processed, [], 2),[],1),[],3);
    if max_eeg > 300 || min_eeg < -300
        disp('WARNING: Getting extreme EEG values. Check signal.') 
    end

    if SAVE_RAW_DATA
        % Save Raw Data
        % Convert data to the storage format
        eye.time_series = eye_data;
        eye.time_stamps = eye_ts;
        unity.time_series = unity_data;
        unity.time_stamps = unity_ts;
        eeg.time_series = [zeros(1, length(eeg_ts)); eeg_data];
        eeg.time_stamps = eeg_ts;

        SAVE_PATH_RAW = fullfile('Data', ['subject_' SUBJECT_ID], ['s', SUBJECT_ID, '_b', BLOCK, '_raw.mat']);
        save(SAVE_PATH_RAW, 'eye', 'unity', 'eeg')
        disp('saved raw data!')
    end

    if SAVE_EPOCHED_DATA
    % Delete trials that were missed
        trials_missed = Billboard.stimulus_type == 0;
        EEG.processed(:,:,trials_missed) = [];
        Pupil.processed(trials_missed,:) = [];
        dwell_times(trials_missed) = [];
        head_rotation(trials_missed,:) = [];
        Billboard.stimulus_type(trials_missed) = [];
        Billboard.category(trials_missed) = [];

        EEG = EEG.processed;
        pupil = Pupil.processed;
        stimulus_type = Billboard.stimulus_type;
        billboard_cat = Billboard.category;
        target_category = target_category * ones(1,length(stimulus_type));
        SAVE_PATH_EPOCHED = fullfile('Data', ['subject_' SUBJECT_ID], ['s', SUBJECT_ID,'_b' BLOCK, '_epoched.mat']); %the path to where the raw data is stored.
        save(SAVE_PATH_EPOCHED,'EEG','pupil','dwell_times','stimulus_type', 'head_rotation', 'billboard_cat', 'target_category');
        disp('saved epoched data!')
    end
    disp(['Number of billboards that came onscreen: ', num2str(length(Billboard.ids_passed))])
    disp(['Number of targets that came onscreen: ' num2str(Billboard.nTargetsPassed)])
    disp(['Number of billboards fixated upon: ', num2str(length(Billboard.id))])
    disp(['Number of targets fixated upon: ' num2str(sum(Billboard.stimulus_type == 1))])

end
