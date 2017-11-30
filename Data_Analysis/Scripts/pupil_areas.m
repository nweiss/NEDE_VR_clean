% This script finds the mean area of the pupil for each subject

clc; clear all; close all;

%% SETTINGS
SAVE_ON = false;
SAVE_PATH = fullfile('Data', 'epoched_v4', 'pupil_means.mat'); 

%%
freq_eye = 60;

%% Low Pass Filter for pupil data
Fpass = 3;          % Passband Frequency
Fstop = 6;          % Stopband Frequency
Apass = 1;           % Passband Ripple (dB)
Astop = 60;          % Stopband Attenuation (dB)
match = 'stopband';  % Band to match exactly

h_lp_pupil  = fdesign.lowpass(Fpass, Fstop, Apass, Astop, freq_eye);
Hd_lp_pupil = design(h_lp_pupil, 'cheby2', 'MatchExactly', match);

%%
BLOCKS = [13, 9, 1, 13, 16, 33, 23, 42];
sbj_eye_vec = cell(1,length(BLOCKS));
pupil_rad_subject_means = zeros(1, length(BLOCKS));

for SUBJECT_IND = [1, 2, 4, 5, 6, 7, 8]
    SUBJECT_ID = num2str(SUBJECT_IND);
    for BLOCK_IND = 1:BLOCKS(SUBJECT_IND)
        BLOCK = num2str(BLOCK_IND);
        
        LOAD_PATH = fullfile('Data', 'raw_mat', ['subject_', SUBJECT_ID], ['s', SUBJECT_ID, '_b', BLOCK, '_raw.mat']);
        load(LOAD_PATH);
        
        Pupil.left = eye.time_series(23,:);
        Pupil.right = eye.time_series(37,:);
                
        %% Process Pupil Data
        % Use the average of the left and right pupil
        Pupil.avg = mean([Pupil.left; Pupil.right], 1);
        Pupil.processed = Pupil.avg; 

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
                    Pupil.processed(blink_starts(1):blink_stops(1)) = Pupil.avg(blink_stops(1))*ones(1,blink_stops(1));
                elseif blink_stops(i) == size(Pupil.isBlink,2)
                    Pupil.processed(blink_starts(end):blink_stops(end)) = Pupil.avg(blink_starts(end))*ones(1,blink_stops(end)-blink_starts(end)+1);
                else                    
                    Pupil.processed(blink_starts(i):blink_stops(i)) = linspace(Pupil.avg(blink_starts(i)), Pupil.avg(blink_stops(i)), blink_stops(i)-blink_starts(i)+1);
                end
            end
        end
        
        % Lowpass filter the pupil data
        Pupil.processed = filtfilt(Hd_lp_pupil.sosMatrix, Hd_lp_pupil.ScaleValues, Pupil.processed);
        
        sbj_eye_vec{SUBJECT_IND} = [sbj_eye_vec{SUBJECT_IND}, Pupil.processed];
        
%         figure
%         plot(linspace(0,110,length(Pupil.avg)),Pupil.avg);
%         hold on
%         plot(linspace(0,110,length(Pupil.avg)),Pupil.isBlink_padded, '.');
%         hold on
%         plot(linspace(0,110,length(Pupil.avg)),Pupil.processed);
%         legend('avg', 'is blink', 'processed')
    end
    pupil_rad_subject_means(SUBJECT_IND) = mean(sbj_eye_vec{SUBJECT_IND});
end

pupil_rad_subject_means = sbj_means;
if SAVE_ON
    save(SAVE_PATH, 'pupil_rad_subject_means');
end

disp('done')