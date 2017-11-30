% Created 7/10/13 by DJ for one-time use.

%% Load data

subject = 22;
sessions = 2:14;
    
% Get events
y = loadBehaviorData(subject,sessions,'3DS');

% Get pupil size
for i=1:numel(sessions)        
    load(sprintf('3DS-%d-%d-eyepos',subject,sessions(i)));
    ps{i} = InterpolateBlinks(pupilsize,y(i).eyelink.record_time-1+(1:length(pupilsize)),y(i));
end 

%% Pick data
iSession = 2;
x = y(iSession);
pupilsize = ps{iSession};
PisN = isnan(pupilsize);
pupilsize(PisN) = interp1(find(~PisN),pupilsize(~PisN),find(PisN),'spline');
psdm = pupilsize - mean(pupilsize); % de-meaned


%% Make filter
f_filter = .5;
w_temp = f_filter/(srate/2);
filtorder = 10; % filter order (initial: 10 for all bands. Min from pop_iirfilt: 8 = theta, 9 = lower1alpha, 9 = lower2alpha, 9 = upperalpha)
filtertype = 'butter'; % filter type to build
rp=1;%0.0025; % Ripple in the passband
rs=40; % Ripple in the stopband
srate = 1000; % Hz
[filtorder,w_filter] = buttord(w_temp*2,w_temp/2,rp,rs);

% Find filter parameters
switch filtertype
    case 'butter'
%         [bl,al] = butter(filtorder, w_filter(2),'low');
        [bh,ah] = butter(filtorder, w_filter(1),'high');
%         [z,p,k] = butter(filtorder, w_filter(1),'high');
        
    case 'ellip'
%         [bl,al] = ellip(filtorder,rp,rs, w_filter(2),'low');
        [bh,ah] = ellip(filtorder,rp,rs, w_filter(1),'high');
    case 'fir'
        bh = fir1(filtorder,w_filter(1),'high');
        ah = 1;
end
% Filter data        
%         fprintf('%dth order low pass at %.3f Hz...\n',filtorder, f_filter(2));
% tempdata = filtfilt(bl,al,double(ALLEEG(i).data(j,:)));
%         fprintf('%dth order high pass at %.3f Hz...\n',filtorder, f_filter(1));
psdm_filtered = filtfilt(bh,ah,psdm);

% Plot
figure(222);
freqz(bh,ah,2000,srate);
figure(13); clf;
plot([psdm, psdm_filtered]);