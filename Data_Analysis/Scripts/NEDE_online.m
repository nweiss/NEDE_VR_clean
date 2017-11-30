% Run VR NEDE experiment
% Neil Weiss
clc; clear all; close all;

%% Settings
% Specify which systems are connected
UNITY = true;
PYTHON = false;
EEG_connected = false;
EYE_connected = false;
PCA_ICA = false;
CLOSED_LOOP = false;
MARKER_STREAM = false; % Output event markers for BCI Lab

SAVE_RAW_DATA = false;
SAVE_EPOCHED_DATA = false;
PLOTS = false;

EPOCHED_VERSION = 6; % Different versions of the data. Look at readme in data folder for details.
SUBJECT_ID = '13';
BLOCK = '1'; % First block in batch
nBLOCKS = 1; % Number of blocks to do in batch

EEG_WARNING_THRESHOLD = 500; % threshold for EEG data overwhich matlab will warn you that you are getting extreme values

%% Set Paths
% Add path to where functions livec
function_path = fullfile('..','Functions');
addpath(function_path);

%% Load Data
if (UNITY||EEG_connected||EYE_connected) == false
    % For simulation of matlab data processing code when no live signals
    % are being streamed
    LOAD_PATH = fullfile('..','..','..','Dropbox','NEDE_Dropbox','Data',...
        'raw_mat', ['subject_', SUBJECT_ID],...
        ['s', SUBJECT_ID, '_b', BLOCK, '_raw.mat']);
    load(LOAD_PATH);
    % Because billboard_id can be zero, make default nan when no billboard
    % onscreen. Correct for old data collection system where default was 0.
    billboard_offscreen_ind = find(unity.time_series(5,:)==0);
    unity.time_series(7,billboard_offscreen_ind) = nan(1,length(billboard_offscreen_ind));
end

if PCA_ICA
    dimred_path = fullfile('..','..','..','Dropbox','NEDE_Dropbox',...
        'Data','dim_red_params',...
        ['s',num2str(SUBJECT_ID),'_dimredparams.mat']);
    load(dimred_path);
end

%% Set Constants
smi_pixels_y = 1010; % Range of SMI eye-tracker in the y-direction (in pixels)
oculus_fov = 106.188; % Field of view of oculus in degrees (Unity lists it)
oculus_pixels_x = 1915; % Pixels in oculus in the horizontal direction, found empirically
allowedDiscrepency = 6*oculus_pixels_x/oculus_fov; % Number of degrees to expand the bounding box of billboards for fixation

block_duration = 140; % Upper bound used to initialize data storage variables (seconds) 
trials_per_block = 20;
n_chan = 64;
freq_eye = 60;
freq_unity = 75;
freq_eeg = 2048;
n_block_start_cues = 0;

% Thresholds for pupil radius to be considered valid data
blink_upper_thresh = 3.2;
blink_lower_thresh = 1.3;

% Dimensions of the chunks we are pushing to python
dimChunkForPython = [66, 385];

%% Create Filters
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
% Load LSL libraries
if UNITY||EEG_connected||EYE_connected||PYTHON
    addpath(genpath(fullfile('..','liblsl-Matlab')));
    addpath('..','dependancies')
    lib = lsl_loadlib();
end

% Create outlet from matlab to unity
if ~PYTHON && CLOSED_LOOP
    info = lsl_streaminfo(lib, 'NEDE_Stream_Response', 'Markers', 3, 0,'cf_float32','sdfwerr32432');
    outlet = lsl_outlet(info);
    disp('Opened outlet: Matlab -> Unity');
end

% Create outlet from matlab to python
if PYTHON
    info = lsl_streaminfo(lib,'Matlab->Python','data_epochs',66,0,'cf_float32', 'Matlab2015a');
    outlet = lsl_outlet(info, 385, 385);
    disp('Opened outlet: Matlab -> Python');
    pause(2);
end

% Create outlet from matlab to BCILab
if MARKER_STREAM
    info = lsl_streaminfo(lib,'FixationOnsetMarkers','Markers',1,0,'cf_string','Matlab2015a');
    outlet_markers = lsl_outlet(info);
    disp('Opened outlet: Marker Stream (Matlab -> BCILab)')
end

%% Outer loop - Iterate over blocks of the experiment
for block_counter = str2double(BLOCK):str2double(BLOCK)+nBLOCKS-1
    BLOCK = num2str(block_counter);

    % Create Inlets
    % Create inlet from eyetracker to matlab
    if EYE_connected
        result_eye = {};
        while isempty(result_eye) 
            result_eye = lsl_resolve_byprop(lib,'name','iViewNG_HMD'); 
            disp('Waiting for: EYE stream');
        end
        inlet_eye = lsl_inlet(result_eye{1});
        disp('Opened inlet: EYE -> Matlab');
    end
    % Create inlet from EEG to matlab
    if EEG_connected
        result_eeg = {};
        while isempty(result_eeg) 
            result_eeg = lsl_resolve_byprop(lib,'name','BioSemi'); 
            disp('Waiting for: EEG stream');
        end
        inlet_eeg = lsl_inlet(result_eeg{1});
        disp('Opened inlet: EEG -> Matlab');
    end
    % Create inlet from Unity to Matlab
    if UNITY
        result_unity = {};
        while isempty(result_unity) 
            result_unity = lsl_resolve_byprop(lib,'name','NEDE_Stream'); 
            disp('Waiting for: UNITY stream');
        end    
        inlet_unity = lsl_inlet(result_unity{1});
        disp('Opened inlet: Unity -> Matlab');
        disp('All streams resolved');
    end
    
    % Look for cue to start a new block from unity
    if UNITY
        disp('Waiting for start cue from unity...');
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
    
    if (PYTHON && CLOSED_LOOP)
        % Create the cue for python to start a new block
        %    1 - (66,385) is the start cue. 1 to start a block, -1 to end
        %    it, and 0 throughout. 
        %    2 - (66,383) is subject ID
        %    3 - (66,384) is the block number
        %    4 - (66,382) is the number of blocks in the set
        startCuePython = zeros(dimChunkForPython);
        startCuePython(end,end) = 1;
        startCuePython(end,end-2) = str2num(SUBJECT_ID);
        startCuePython(end,end-1) = str2num(BLOCK);
        startCuePython(end,end-3) = nBLOCKS;
        
        % Push data to python
        pause(1.5) % Need a delay between opening the outlet and pushing
        outlet.push_chunk(startCuePython);
        disp('Pushed start cue to python')
    end
    
    disp(['***STARTING BLOCK ', BLOCK,'***']);
    fprintf('\n')

    %% Initialize Data Storage Variables
    left_border = zeros(1, ceil(block_duration * freq_eye)); % boarder of the onscreen billboard in pixels in oculus space, in eye-time
    right_border = zeros(1, ceil(block_duration * freq_eye));
    isFixated = zeros(1,floor(block_duration*freq_eye)); % Flag for if eye point-of-regard is fixated within bounding box of billboard
    dwell_times = zeros(1,trials_per_block);
    head_rotation = zeros(trials_per_block, round(freq_unity*2)+2);
    stop_time_live_stream = inf;

    % EEG data (64xtime array)
    eeg_data = zeros(64, floor(block_duration * freq_eeg));
    eeg_ts = zeros(1, floor(block_duration) * freq_eeg);

    % eye_data (37xtime array)
    %   2) PORx
    %   3) PORy
    %   23) left pupil radius
    %   37) right pupil radius
    eye_data = zeros(37, floor(block_duration * freq_eye));
    eye_ts = zeros(1, floor(block_duration * freq_eye));

    % unity_data (15xtime array)
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
    %   16) Image No (ie 32 for car_side_32.jpg)
    %   17) Block start/end flag (1 for block start, 2 for block end)
    unity_data = zeros(17,floor(block_duration*freq_unity));
    unity_data(7,:) = -1*ones(1,size(unity_data,2)); %Initialize this to -1 bc 0 is a valid billboard id
    unity_ts = nan(1,floor(block_duration*freq_unity));

    Billboard.isOnscreen = zeros(1, floor(block_duration * freq_unity));
    Billboard.id_eye_frames = zeros(1, floor(block_duration * freq_eye));
    Billboard.id_unity_frames = -1*ones(1, floor(block_duration * freq_unity)); % -1 marks the absence of a billboard since 0 is a valid id
    Billboard.id = []; % Records the ids as they are fixated upon
    Billboard.stimulus_type = zeros(1, trials_per_block);
    Billboard.imageNo = zeros(1, trials_per_block);
    Billboard.category = zeros(1, trials_per_block);

    Fixation.start_times = zeros(1,trials_per_block);
    Fixation.stop_times = zeros(1,trials_per_block);
    Fixation.stop_frames_eye = zeros(1,trials_per_block);
    Fixation.start_frame_eye = zeros(1,trials_per_block);
    Fixation.start_frame_unity = zeros(1,trials_per_block);
    Fixation.start_frame_eeg = zeros(1,trials_per_block);

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

    EEG = struct;
    EEG.epoch = zeros(64, round(freq_eeg * 1.5) + 1);
    EEG.baseline = zeros(64, 1);
    EEG.filtered = zeros(64, round(freq_eeg * 1.5) + 1);
    EEG.downsampled = zeros(64, floor(size(EEG.filtered, 2)/8)+1);
    EEG.processed = zeros(64, size(EEG.downsampled, 2), trials_per_block);
    EEG.time_epoch = linspace(-500, 1000, size(EEG.downsampled, 2));

    % Constants for maltab only mode that are reset for each block
    if ~EEG_connected && ~EYE_connected % (Matlab only mode)
        batch_eeg_start = 1; % start-frame of the 1-sec block of eeg data to be imported
        batch_eeg_end = round(freq_eeg)+1; % the end-frame of the 1-sec block of eeg data to be imported
        prev_sec = 0;
        max_frame_eye = size(eye.time_series, 2);
        max_frame_unity = size(unity.time_series, 2);
        max_frame_eeg = size(eeg.time_series, 2);
        start_time = eye.time_stamps(1); % simulation start time
        stop_time_sim = max(unity.time_stamps) + 3.2; % simulation end time. Allow extra 3 sec to allow pupil data to come in.
    end
    
    %% Main Loop - Within a block, continuously analyze incoming data 
    % The counters run in a non-traditional way. counter_matlab counts the
    % number of times through the large inner while loop. In each run through
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
    counter_eeg = 1;
    first_frame_unity = true;
    first_frame_eye = true;
    first_frame_eeg = true;
    
    tic
    while true
        % Exit block in Matlab only mode
        timer = toc;
        if ~EEG_connected && ~EYE_connected % (Matlab only mode)
            time = timer + start_time;
            % Exit simulation when time has elapsed
            if time > stop_time_sim
                break
            end
        end
        
        % Exit block in unity mode
        if UNITY
            % Wait 3 sec after receiving the exit cue to allow the pupil
            % data to come in.
            if unity_data(end,counter_unity) == 2
                if stop_time_live_stream == inf
                    stop_time_live_stream = timer + 3.1;
                end
            end
            if timer > stop_time_live_stream
                break
            end
        end

        % Flags to track of whether each stream was updated in a given loop of Matlab
        update_eye = false;
        update_unity = false;
        update_eeg = false;

        %% Simulate the data streams in real time (only for matlab only simulation mode)
        if ~EEG_connected && ~EYE_connected % (Matlab only mode)
           % Eye Stream
           if counter_eye < max_frame_eye
               if time > eye.time_stamps(counter_eye)
                   if counter_eye <= max_frame_eye
                       update_eye = true;
                       if ~first_frame_eye
                           counter_eye = counter_eye + 1;
                       else
                            first_frame_eye = false;
                       end
                       eye_data(:, counter_eye) = eye.time_series(:,counter_eye);
                       eye_ts(counter_eye) = eye.time_stamps(counter_eye);
                   end
               end
           end

           % Unity Stream
           if counter_unity < max_frame_unity
               if time > unity.time_stamps(counter_unity)
                   if counter_unity <= max_frame_unity
                       update_unity = true;
                       if ~first_frame_unity
                           counter_unity = counter_unity + 1;
                       else
                           first_frame_unity = false;
                       end
                       unity_data(1:15,counter_unity) = unity.time_series(1:15,counter_unity);
                       unity_ts(counter_unity) = unity.time_stamps(counter_unity);
                   end
               end
           end

           % EEG Stream
           if floor(timer) ~= prev_sec % Stream it in in 1 sec blocks
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

        %% Stream in data (Live streaming mode)
        % Unity Stream
        if UNITY 
            [a, b] = inlet_unity.pull_sample(0);
            if ~isempty(a) % If Unity has moved to a new frame
                update_unity = true;
                if ~first_frame_unity
                    counter_unity = counter_unity + 1;
                end
                if first_frame_unity
                    first_frame_unity = false;
                end
                unity_data(:, counter_unity) = a;
                unity_ts(counter_unity) = b;
            end
        end
       
        % Eye Stream
        if EYE_connected
           if ~first_frame_unity %only start collecting eye&eeg data once unity has started. Otherwise, you exceed the allocated space for the data streams.
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
           end
        end
                
        % EEG Stream
        if EEG_connected
            if ~first_frame_unity
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

        %% Find Fixation Onsets
        % Find when there is a billboard onscreen
        if update_unity
            Billboard.id_unity_frames(counter_unity) = unity_data(7, counter_unity);
            if unity_data(3, counter_unity) ~= 0
                Billboard.isOnscreen(counter_unity) = 1; % Flag for whether there is a billboard onscreen
            end
        end
        % Define the padded bounding box of the billboard
        if update_eye
            Billboard.id_eye_frames(counter_eye) = unity_data(7, counter_unity);
            if Billboard.isOnscreen(counter_unity)
                left_border(counter_eye) = unity_data(1, counter_unity) - allowedDiscrepency;
                right_border(counter_eye) = unity_data(1, counter_unity) + unity_data(3, counter_unity) + allowedDiscrepency;
            end
            % If the eye is fixated on a billboard
            if eye_data(2, counter_eye) > left_border(counter_eye) && eye_data(2, counter_eye) < right_border(counter_eye)
                isFixated(counter_eye) = 1;
                
                % If the billboard being fixated upon is new, add it to the list of billboard ids
                if ~any(Billboard.id == unity_data(7, counter_unity))
                    Billboard.id = [Billboard.id unity_data(7, counter_unity)];
                    Billboard.stimulus_type(counter_billboard) = unity_data(5, counter_unity);
                    Billboard.imageNo(counter_billboard) = unity_data(16,counter_unity);
                    Billboard.category(counter_billboard) = unity_data(6, counter_unity);
                    Fixation.start_times(counter_billboard) = eye_ts(counter_eye);
                    Fixation.start_frame_eye(counter_billboard) = counter_eye;
                    Fixation.start_frame_unity(counter_billboard) = counter_unity;
                    counter_billboard = counter_billboard + 1;
                end
            end
        end

       %% Epoch Data
       if size(Billboard.id, 2) >= counter_epoch % For a new billboard
           if eye_ts(counter_eye) > Fixation.start_times(counter_epoch) + 3.1 % wait 3 seconds for all of the pupil data to come in
                % Epoch the pupil data
                Pupil.left = eye_data(23,Fixation.start_frame_eye(counter_epoch)-round(freq_eye):Fixation.start_frame_eye(counter_epoch)+3*round(freq_eye));
                Pupil.right = eye_data(37,Fixation.start_frame_eye(counter_epoch)-round(freq_eye):Fixation.start_frame_eye(counter_epoch)+3*round(freq_eye));

                % Find the dwell times
                Fixation.stop_frames_eye(counter_epoch) = find(diff(isFixated) == -1, 1, 'last');
                Fixation.stop_times(counter_epoch) = eye_ts(Fixation.stop_frames_eye(counter_epoch));
                dwell_times(counter_epoch) = Fixation.stop_times(counter_epoch) - Fixation.start_times(counter_epoch);

                % Epoch the head tracking data
                oculus_rotation = unity_data(9, Fixation.start_frame_unity(counter_epoch)-round(.5*freq_unity):Fixation.start_frame_unity(counter_epoch)+round(1.5*freq_unity));
                car_rotation = unity_data(12, Fixation.start_frame_unity(counter_epoch)-round(.5*freq_unity):Fixation.start_frame_unity(counter_epoch)+round(1.5*freq_unity));
                
                % Epoch the eeg data
                % There is a jitter in the eeg_ts such that occassionally you
                % will get two locations for where the fixation onset is. This
                % jitter is on the order of 5  milliseconds though and only 
                % occurs in about 1/100 billboards. If you get multiple values
                % for start_frame_eeg, take the first one.
                tmp = find(diff(eeg_ts<Fixation.start_times(counter_epoch))==-1,1,'first')+1;
                Fixation.start_frame_eeg(counter_epoch) = tmp;
                Epoch.start_frame_eeg(counter_epoch) = Fixation.start_frame_eeg(counter_epoch) - round(.5 * freq_eeg);
                Epoch.stop_frame_eeg(counter_epoch) = Fixation.start_frame_eeg(counter_epoch) + round(1 * freq_eeg);
                EEG.epoch = eeg_data(:, Epoch.start_frame_eeg(counter_epoch) : Epoch.stop_frame_eeg(counter_epoch));

                %% Process Pupil Data
                Pupil.avg = mean([Pupil.left; Pupil.right], 1); % Use avg of left and right pupil
                Pupil.avg = interpBlinks(Pupil.avg, blink_lower_thresh, blink_upper_thresh);
                % Lowpass filter the pupil data
                Pupil.avg = filtfilt(Hd_lp_pupil.sosMatrix, Hd_lp_pupil.ScaleValues, Pupil.avg);
                % Baseline the pupil data to the second prior to first fixation
                Pupil.baseline = mean(Pupil.avg(1:floor(freq_eye * 1)));
                Pupil.processed(counter_epoch,:) = Pupil.avg - Pupil.baseline;
                
                % Warn experimenter if getting empty pupil vectors
                if ~any(Pupil.processed)
                    disp('WARNING: Got an empty pupil vector for last trial. Consider modifying blink_lower_thresh and blink_upper_thresh.') 
                end
                
                %% Process head rotation data
%                 % The rotation of the oculus that is recorded is the rotation
%                 % relative to the rotation of the car. Correct for that.
%                 % if the car rotation is 0
%                 if max(car_rotation) < 1
%                     for i = 1:length(oculus_rotation)
%                         if oculus_rotation(i) > 180
%                             head_rotation(counter_epoch,i) = oculus_rotation(i)-360;
%                         else
%                             head_rotation(counter_epoch,i) = oculus_rotation(i);
%                         end
%                     end
%                 else
%                     head_rotation(counter_epoch,:) = oculus_rotation - 180;
%                 end

                % Get head rotation from oculus rotation and car rotation
                head_rotation(counter_epoch,:) = processHeadRotation(oculus_rotation, car_rotation);
                
                %% Process EEG Data
                % HP and LP Filter. Downsample.
                EEG.filtered = filtfilt(Hd_hp.sosMatrix, Hd_hp.ScaleValues, EEG.epoch')';
                EEG.filtered = filtfilt(Hd_lp.sosMatrix, Hd_lp.ScaleValues, EEG.filtered')';
                EEG.downsampled = downsample(EEG.filtered', 8)';

                % Clean using PCA and ICA
                if PCA_ICA
                    EEG.pcs = pca_coeff'*EEG.downsampled;
                    EEG.pc_cleaned = pinv(pca_coeff)'*EEG.pcs;
                    % Find the component activations. Code borrowed from:
                    % https://sccn.ucsd.edu/pipermail/eeglablist/2013/006954.html
                    EEG.ica = (icaweights*icasphere)*EEG.pc_cleaned;
                    EEG.downsampled = EEG.ica;
                end
                
                % Baseline EEG Data
                EEG.baseline = mean(EEG.downsampled(:, 1:floor(256*.2)), 2);                
                for i = 1:n_chan
                    EEG.processed(i,:,counter_epoch) = EEG.downsampled(i,:) - EEG.baseline(i);  
                end

                %% Send Epoched Data to Python
                if PYTHON
                    % Package all the data from one epoch into a 66x385 matrix
                    % to be sent to Unity. The data has the following format:
                    %    1 - (1:64,1:385) is all EEG data.
                    %    2 - (65,1:150) is the head rotation
                    %    3 - (65,151:385) is zeros
                    %    3 - (66,1) is the stimulus type (1=target, 2=distractor)
                    %    4 - (66,2) is the billboard id (unique identifier in unity for finding the position of the billboard)                
                    %    5 - (66,3) is the dwell time
                    %    6 - (66,4) is the billboard category (1=car, 2=grand piano, 3=laptops, 4=schooners)
                    %    7 - (66,5) is the image number (ie 32 for car_side_32.jpg)
                    %    7 - (66,6:246) is the pupil dilation
                    %    8 - (66,246:385) is zeros
                    %    9 - (66,385) is the cue. 1 to start the block, -1 to end it, and 0 throughout the
                    %    main loop, but is 1 when cuing python that matlab has
                    %    finished its main loop
                    Epoch.complete = zeros(size(EEG.processed,1)+2, size(EEG.processed,2));
                    Epoch.complete(1:size(Epoch.complete,1)-2,:) = EEG.processed(:,:,counter_epoch);
                    Epoch.complete(size(Epoch.complete,1)-1,1:size(head_rotation,2)) = head_rotation(counter_epoch,:);
                    Epoch.complete(end,1) = Billboard.stimulus_type(counter_epoch);
                    Epoch.complete(end,2) = Billboard.id(counter_epoch);
                    Epoch.complete(end,3) = dwell_times(counter_epoch);
                    Epoch.complete(end,4) = Billboard.category(counter_epoch);
                    Epoch.complete(end,5) = Billboard.imageNo(counter_epoch);
                    Epoch.complete(end,6:size(Pupil.processed,2)+5) = Pupil.processed(counter_epoch,:);

                    % Push data to python
                    outlet.push_chunk(Epoch.complete);               
                    disp(['Pushed Data: BillboardID-' num2str(Billboard.id(counter_epoch))])
                end
                
                % Push event data to marker stream
                if MARKER_STREAM
                    outlet_markers.push_sample({'fixation_start'}, Fixation.start_times(counter_epoch));
                    if Billboard.stimulus_type(counter_epoch) == 1
                        outlet_markers.push_sample({'target'}, Fixation.start_times(counter_epoch));
                    else
                        outlet_markers.push_sample({'distractor'}, Fixation.start_times(counter_epoch));
                    end
                end
                disp(['captured epoch: ' num2str(counter_epoch)])
                counter_epoch = counter_epoch + 1;
            end
        end

       %% Dummy classifier for matlab and unity mode (for debugging unity)
       if UNITY && ~PYTHON && ~EEG_connected && ~EYE_connected && CLOSED_LOOP && (counter_unity ~= 1)
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
                disp('pushed to unity')
                disp(['billboard number: ', num2str(billboard_num), '    classified as: ', num2str(classification), '    confidence: ', num2str(confidence)]);
            end
        end
        counter_matlab = counter_matlab + 1;
    end

    %% Close block
    % Find the target category for the block (ie. billboard category that was target)
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
    Billboard.ids_passed = unique(unity_data(7,~isnan(unity_data(7,:))), 'stable');
    Billboard.ids_passed(Billboard.ids_passed == -1) = [];
    nBillboardsPassed = length(Billboard.ids_passed);
    Billboard.pass_onsets = nan(nBillboardsPassed,1);
    for i = 1:nBillboardsPassed
         Billboard.pass_onsets(i) = find(unity_data(7,:) == Billboard.ids_passed(i), 1, 'first');
    end
    Billboard.nTargetsPassed = sum(unity_data(5,Billboard.pass_onsets)==1);

    % Push block exit cue to python
    if PYTHON
        tmp = zeros(size(Epoch.complete,1),size(Epoch.complete,2));
        tmp(end,end) = -1;
        tmp(end,end-1) = target_category;
        outlet.push_chunk(tmp);
    end

    %% Plots
    timer = toc;
    if PLOTS
        start_time = eye_ts(1);
        n_eye_frames = find(eye_ts == max(eye_ts));
        n_unity_frames = find(unity_ts == max(unity_ts));
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
    fprintf('\n')
    if SAVE_RAW_DATA
        % Convert data to storage format and trim trailing zeros from initialization
        [eye.time_series, eye.time_stamps] = trimExcess(eye_data,eye_ts);
        [unity.time_series, unity.time_stamps] = trimExcess(unity_data,unity_ts);
        [eeg.time_series, eeg.time_stamps] = trimExcess(eeg_data,eeg_ts);
        eeg.time_series = [zeros(1, length(eeg.time_stamps)); eeg.time_series];
        
        % Check that you are not overwriting existing data file
        SAVE_PATH_RAW = fullfile('..','..','..','Dropbox','NEDE_Dropbox','Data','raw_mat', ['subject_' SUBJECT_ID], ['s', SUBJECT_ID, '_b', BLOCK, '_raw.mat']);
        if exist(SAVE_PATH_RAW)==2
            error('Data file already exists. Update subject and block number.') 
        end

        % Create directory for raw data of this subject
        if ~exist(fullfile('..','..','..','Dropbox','NEDE_Dropbox','Data','raw_mat',['subject_' SUBJECT_ID]))
            mkdir(fullfile('..','..','..','Dropbox','NEDE_Dropbox','Data','raw_mat',['subject_' SUBJECT_ID]));
            disp(['New directory created for raw data for subject ' SUBJECT_ID])
        end
        
        save(SAVE_PATH_RAW, 'eye', 'unity', 'eeg')
        disp('Saved raw data!')
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
        Billboard.imageNo(trials_missed) = [];

        EEG = EEG.processed;
        pupil = Pupil.processed;
        stimulus_type = Billboard.stimulus_type;
        billboard_cat = Billboard.category;
        image_no = Billboard.imageNo;
        target_category = target_category * ones(1,length(stimulus_type));
        
        % Check that you are not overwriting existing data file
        SAVE_PATH_EPOCHED = fullfile('..','..','..','Dropbox','NEDE_Dropbox','Data',['epoched_v' num2str(EPOCHED_VERSION)], ['subject_' SUBJECT_ID], ['s', SUBJECT_ID,'_b' BLOCK, '_epoched.mat']); %the path to where the raw data is stored.
        if exist(SAVE_PATH_EPOCHED)==2
            error('Data file already exists. Update subject and block number.') 
        end
        
        % Create directory for epoched data of this subject
        if ~exist(fullfile('..','..','..','Dropbox','NEDE_Dropbox','Data',['epoched_v' num2str(EPOCHED_VERSION)],['subject_' SUBJECT_ID]))
            mkdir(fullfile('..','..','..','Dropbox','NEDE_Dropbox','Data',['epoched_v' num2str(EPOCHED_VERSION)],['subject_' SUBJECT_ID]));
            disp(['New directory created for epoched data for subject ' SUBJECT_ID])
        end
        
        save(SAVE_PATH_EPOCHED,'EEG','pupil','dwell_times','stimulus_type', 'head_rotation', 'billboard_cat', 'target_category','image_no');
        disp('Saved epoched data!')
    end
    disp(['Number of billboards that came onscreen: ', num2str(length(Billboard.ids_passed))])
    disp(['Number of targets that came onscreen: ' num2str(Billboard.nTargetsPassed)])
    disp(['Number of billboards fixated upon: ', num2str(length(Billboard.id))])
    disp(['Number of targets fixated upon: ' num2str(sum(Billboard.stimulus_type == 1))])
    
    % Close the inlets
    if UNITY
        inlet_unity.delete();
        disp('Inlet closed: Unity -> Matlab')
    end
    if EEG_connected
        inlet_eeg.delete();
        disp('Inlet closed: EEG -> Matlab')
    end
    if EYE_connected
        inlet_eye.delete();
        disp('Inlet closed: Eye -> Matlab')
    end
    
    % Warn the experimenter if you are getting extreme EEG values
    max_eeg_per_chan = max(eeg_data, [], 2);
    min_eeg_per_chan = min(eeg_data, [], 2);
    if max(max_eeg_per_chan) > EEG_WARNING_THRESHOLD || min(min_eeg_per_chan) < -EEG_WARNING_THRESHOLD
        max_ind = find(max_eeg_per_chan > EEG_WARNING_THRESHOLD);
        min_ind = find(min_eeg_per_chan < -EEG_WARNING_THRESHOLD);
        extreme_chans = union(max_ind, min_ind);
        disp(['WARNING: Getting extreme EEG values on ', num2str(length(extreme_chans)) ' channels. Check signal.']) 
    end
    
    disp(['***COMPLETED BLOCK NUMBER ', BLOCK,'***'])
    fprintf('\n')
    
end

% Send set end cue to python and close outlet
if CLOSED_LOOP || PYTHON
    setEndCue = zeros(dimChunkForPython);
    setEndCue(end,end) = -2;
    outlet.push_chunk(setEndCue);
    pause(1.5); % Give python time to pick up the exit cue before closing the stream
    outlet.delete()
    disp('outlet closed')
end

disp('done')