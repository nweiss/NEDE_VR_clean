% This script takes in data from the VR NEDE experiment a set of continuous 
% .mat files. It puts out epoched data. 
% 05/26/2017

clc; clear all; close all;

%% Settings
SIMULATION_DURATION = 120; % seconds. Only used in 'matlab' mode. Simulation dataset is 113s.
SAVE_EPOCHED_DATA = true;
VERSION = '4'; % version name for the saved data
BLOCKS = [13, 9, 1, 13, 16, 33, 23, 42];

% Load the subject means of all the pupil radii
LOAD_PUPIL_PATH = fullfile('Data', 'epoched_v4', 'parameters', 'pupil_means.mat');
load(LOAD_PUPIL_PATH);

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

% Upper limit of block duration. Used to construct empty matrices to be
% filled as data is streamed in.
block_duration = 140; % seconds. This is padded to allow room between when you start matlab and unity.
trials_per_block = 20;

% frequencies
freq_eye = 60;
freq_unity = 75;
freq_eeg = 2048;

n_chan = 64;

%% Create the Filters
% High Pass Filter for EEG
Fstop = .5;         % Stopband Frequency
Fpass = 1;           % Passband Frequency
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

%% Loop through each block of each subject
for SUBJECT_IND = [1, 2, 4, 5, 6, 7, 8]
    SUBJECT_ID = num2str(SUBJECT_IND);
    for BLOCK_IND = 1:BLOCKS(SUBJECT_IND)
        BLOCK = num2str(BLOCK_IND);
        clear EEG

        %% Load Data
        LOAD_PATH = fullfile('Data', 'raw_mat', ['subject_', SUBJECT_ID], ['s', SUBJECT_ID, '_b', BLOCK, '_raw.mat']);
        load(LOAD_PATH);

        %% Initialize Data Storage Variables
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
        unity_data = zeros(15, floor(block_duration * freq_unity));
        unity_ts = zeros(1, floor(block_duration * freq_unity));

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

        Pupil.left = zeros(1, round(freq_eye * block_duration) + 1);
        Pupil.right = zeros(1, round(freq_eye * block_duration) + 1);
        Pupil.avg = zeros(1, round(freq_eye * block_duration) + 1);
        Pupil.isBlink = zeros(1, round(freq_eye * block_duration) + 1);
        Pupil.isBlink_padded = zeros(1, round(freq_eye * block_duration) + 1);
        Pupil.processed = zeros(trials_per_block, round(freq_eye * 4) + 1);
        Pupil.area = zeros(1, round(freq_eye * block_duration) + 1);
        Pupil.filtered = zeros(1, round(freq_eye * block_duration) + 1);
        Pupil.pct_of_mean = zeros(1, round(freq_eye * block_duration) + 1);
        Pupil.baseline = 0;

        eeg_data = zeros(64, floor(block_duration * freq_eeg));
        eeg_ts = zeros(1, floor(block_duration) * freq_eeg);
        EEG.epoch = zeros(64, round(freq_eeg * 1.5) + 1);
        EEG.baseline = zeros(64, 1);
        EEG.filtered = zeros(64, round(freq_eeg * 1.5) + 1);
        EEG.downsampled = zeros(64, floor(size(EEG.filtered, 2)/8)+1);
        EEG.processed = zeros(64, size(EEG.downsampled, 2), trials_per_block);
        EEG.time_epoch = linspace(-500, 1000, size(EEG.downsampled, 2));


        %% Offline EEG filtering:
        eeg.time_series = double(eeg.time_series);
        eeg.time_series = filtfilt(Hd_hp.sosMatrix, Hd_hp.ScaleValues, eeg.time_series')';
        eeg.time_series = filtfilt(Hd_lp.sosMatrix, Hd_lp.ScaleValues, eeg.time_series')';

        % CAR spacial filter
        % tmp1 = mean(eeg.time_series(2:end,:), 1);
        % tmp2 = repmat(tmp1, [65,1]);
        % eeg.time_series = eeg.time_series - tmp2;
        
        %% Offline pupil filtering
        % Use the average of the left and right pupil\
        Pupil.left = eye.time_series(23,:);
        Pupil.right = eye.time_series(37,:);
        Pupil.avg = mean([Pupil.left; Pupil.right], 1);
        Pupil.interpolated = Pupil.avg; 

        % Remove blinks
        Pupil.isBlink = Pupil.avg < 1.5 | Pupil.avg > 2.25;

        %pad the blink data so that anything within five frames of a blink is
        %considered a blink too
        % look three frames to the right of each data point
        Pupil.isBlink_padded = zeros(1, size(Pupil.isBlink, 2));

        for i = 1:size(Pupil.isBlink, 2) - 5
            if sum(Pupil.isBlink(i:i+5)) >= 1
                Pupil.isBlink_padded(i) = 1;
            end
        end
        % look five frames to the left of each data point
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
            for i = 1:nBlinks
                if blink_starts(i) == 1
                    Pupil.interpolated(blink_starts(1):blink_stops(1)) = Pupil.avg(blink_stops(1))*ones(1,blink_stops(1));
                elseif blink_stops(i) == size(Pupil.isBlink,2)
                    Pupil.interpolated(blink_starts(end):blink_stops(end)) = Pupil.avg(blink_starts(end))*ones(1,blink_stops(end)-blink_starts(end)+1);
                else                    
                    Pupil.interpolated(blink_starts(i):blink_stops(i)) = linspace(Pupil.avg(blink_starts(i)), Pupil.avg(blink_stops(i)), blink_stops(i)-blink_starts(i)+1);
                end
            end
        end
        
        % Lowpass filter the pupil data
        Pupil.filtered = filtfilt(Hd_lp_pupil.sosMatrix, Hd_lp_pupil.ScaleValues, Pupil.interpolated);
        Pupil.area = pi * Pupil.filtered.^2;
        Pupil.area_means = pi * pupil_rad_subject_means.^2;
        Pupil.pct_of_mean = 100 .* (Pupil.area ./ Pupil.area_means(SUBJECT_IND));

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

        batch_eeg_start = 1; % the start-frame of the given block of eeg data to be streamed. Start at 2 to match indexing of other streams.
        batch_eeg_end = round(freq_eeg)+1; % the end-frame of the given block of eeg data to be streamed
        prev_sec = 0;
        max_frame_eye = size(eye.time_series, 2);
        max_frame_unity = size(unity.time_series, 2);
        max_frame_eeg = size(eeg.time_series, 2);
        start_time = eye.time_stamps(1);

        tic
        while true
            timer = toc;
            % Limit the simulation to SIMULATION_DURATION
            % Use time in 'matlab' mode to load each stream at the appropriate
            % frequency.
            time = timer + start_time;
            if timer > SIMULATION_DURATION;
                break
            end

           % These allow you to keep track of whether each stream was updated on a
           % given loop of Matlab
           update_eye = false;
           update_unity = false;
           update_eeg = false;

           %% Simulate the data streams in real time
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
                    Pupil.epoched = Pupil.pct_of_mean(Fixation.start_frame_eye(counter_epoch) - round(freq_eye) : Fixation.start_frame_eye(counter_epoch) + 3 * round(freq_eye));
                    
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
                    
                    % Baseline the pupil data to the first 200 ms (t = -1000 to - 800 ms)
                    Pupil.baseline = mean(Pupil.epoched(1:floor(freq_eye * 1)));
                    Pupil.processed(counter_epoch,:) = Pupil.epoched - Pupil.baseline;

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
                    % For online filtering, filter the epoch
                    %EEG.filtered = filtfilt(Hd_hp.sosMatrix, Hd_hp.ScaleValues, EEG.epoch')';
                    %EEG.filtered = filtfilt(Hd_lp.sosMatrix, Hd_lp.ScaleValues, EEG.filtered')';

                    % for offline filtering (prior to epoching):
                    EEG.filtered = EEG.epoch;

                    EEG.downsampled = downsample(EEG.filtered', 8)';
                    EEG.baseline = mean(EEG.downsampled(:, 1:floor(256*.2)), 2);
                    for i = 1:n_chan
                        EEG.processed(i,:,counter_epoch) = EEG.downsampled(i,:) - EEG.baseline(i);  
                    end      
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

        start_time = eye_ts(1);

        %     plot(unity_ts(1:n_unity_frames)-start_time, unity_data(1, 1:n_unity_frames))
        %     hold on
        %     plot(unity_ts(1:n_unity_frames)-start_time, unity_data(1, 1:n_unity_frames) + unity_data(3, 1:n_unity_frames))
        %     hold on
        %     plot(eye_ts(1:n_eye_frames)-start_time, eye_data(2,1:n_eye_frames))
        %     hold on
        %     plot(eye_ts(1:n_eye_frames)-start_time, 500*isFixated(1:n_eye_frames), '.')
        %     title('Eye Position vs Billboard Position')
        %     xlabel('time')
        %     ylabel('horizontal pixels')
        %     legend('billboard left border','billboard right border','eye POR','isFixated')
        %     figure
        %     for i = 1:counter_epoch-1
        %         plot(Pupil.processed(i,:))
        %         hold on
        %     end
        %     title('Pupil dilation for all trials')

        %% Save Data
        
        % Create a vector of the target category for the entire block
        % (ie a value of 1 indicates that the target for this block is cars. 4 possible entries.)
        tmp = find(unity_data(5,:) == 1, 1, 'first');
        if ~isempty(tmp)
            target_category = unity_data(6,tmp)*ones(1, trials_per_block);
        end
        % if no targets appeared in a block
        if isempty(tmp)
            tmp2 = unique(unity_data(6,:));
            for i = 1:4
                if sum(tmp2 == i) == 0
                    target_category = i*ones(1, trials_per_block);
                end
            end
        end

        if SAVE_EPOCHED_DATA
            % Create directory if it does not already exist
            SAVE_FOLDER = fullfile('Data', ['epoched_v', VERSION], ['subject_', SUBJECT_ID]);
            if exist(SAVE_FOLDER) ~= 7
                mkdir(SAVE_FOLDER)
            end
            
            % Delete trials that were missed
            trials_missed = Billboard.stimulus_type == 0;
            EEG.processed(:,:,trials_missed) = [];
            Pupil.processed(trials_missed,:) = [];
            dwell_times(trials_missed) = [];
            head_rotation(trials_missed,:) = [];
            Billboard.stimulus_type(trials_missed) = [];
            Billboard.category(trials_missed) = [];
            target_category(trials_missed) = [];

            EEG = EEG.processed;
            pupil = Pupil.processed;
            stimulus_type = Billboard.stimulus_type;
            billboard_cat = Billboard.category;
            SAVE_PATH_EPOCHED = fullfile('Data', ['epoched_v' VERSION], ['subject_' SUBJECT_ID], ['s', SUBJECT_ID,'_b' BLOCK, '_epoched.mat']); %the path to where the raw data is stored.
            save(SAVE_PATH_EPOCHED,'EEG','pupil','dwell_times','stimulus_type', 'head_rotation', 'billboard_cat', 'target_category');
            disp('saved epoched data!')
        end
        disp(['epochs found: ', num2str(length(Billboard.id))])
        disp(['subject ', SUBJECT_ID, 'block ', BLOCK, ' complete'])
    end
end
disp('done')

% EEG_tmp = EEG.processed;
% eeglab
% EEGlab = pop_importdata('data', 'EEG_tmp', 'srate', 256)
% pop_spectopo(EEGlab)

