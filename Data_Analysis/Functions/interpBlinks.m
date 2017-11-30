function pupil_interped = interpBlinks(pupil, lowerLim, upperLim)

% Linearly interpolate pupil radius time-series during blinks
%
% INPUTS:
% - pupil is a 1xn vector of pupil radius
% - lowerLim is the pupil radius lower threshold for considering it a
%   blink. (scalar typically at roughly 1.5)
% - upperLim is the pupil radius upper threshold for considering it a
%   blink. (scalar typically at roughly 2.5)
%
% OUTPUTS:
% - pupil_interped is a 1xn vector of pupil radius with the blinks removed

% Create a flag for blinks that is padded by 3 frames
Pupil.isBlink = pupil < lowerLim | pupil > upperLim; 
Pupil.isBlink_padded = zeros(1, size(Pupil.isBlink, 2));
for i = 1:size(Pupil.isBlink, 2) - 5
    if sum(Pupil.isBlink(i:i+5)) >= 1
        Pupil.isBlink_padded(i) = 1;
    end
end
for i = 6:size(Pupil.isBlink, 2)
    if sum(Pupil.isBlink(i-5:i)) >= 1
        Pupil.isBlink_padded(i) = 1;
    end
end
% If there is a blink on either end of an epoch, call the whole end a blink
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

% If either end of an epoch is a blink, have it stay flat
% at the nearest valid value
if ~isempty(blink_starts)
    if blink_starts(1) == 1
        pupil(blink_starts(1):blink_stops(1)) = pupil(blink_stops(1))*ones(1,blink_stops(1));
    end
    if blink_stops(end) == size(Pupil.isBlink,2);
        pupil(blink_starts(end):blink_stops(end)) = pupil(blink_starts(end))*ones(1,blink_stops(end)-blink_starts(end)+1);
    end

    for i = 1:nBlinks
        pupil(blink_starts(i):blink_stops(i)) = linspace(pupil(blink_starts(i)), pupil(blink_stops(i)), blink_stops(i)-blink_starts(i)+1);
    end
end
pupil_interped = pupil;
end