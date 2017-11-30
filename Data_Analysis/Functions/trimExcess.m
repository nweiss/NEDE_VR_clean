% Delete trailing zeros in data left over from variable initialization

function [time_series_trimmed,time_stamps_trimmed] = trimExcess(time_series,time_stamps)

% Throw error if time_stamps is not a row vector
if size(time_stamps,1) ~= 1
    error('time_stamps has multiple rows. Possibly swapped position of time_series and time_stamps.') 
end

% Find the last frame of real data
real_data_flag = any(time_stamps,1);
last_frame = find(diff(real_data_flag));

% Throw error if there are multiple frames considered to be the last one
if length(last_frame) ~= 1
    error('Finding multiple transitions between true data and zeros')
end

time_series_trimmed = time_series(:,1:last_frame);
time_stamps_trimmed = time_stamps(1:last_frame);