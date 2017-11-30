function Hd = LPF(Fs,type)
%LPF Returns a discrete-time filter object.

% Chebyshev Type II Lowpass filter designed using FDESIGN.LOWPASS.

% All frequency values are in Hz.
%Fs = 600;  % Sampling Frequency

%ssvep
Fpass = 40;          % Passband Frequency
Fstop = 45;          % Stopband Frequency
Apass = 1;           % Passband Ripple (dB)
Astop = 80;          % Stopband Attenuation (dB)
match = 'stopband';  % Band to match exactly


% Construct an FDESIGN object and call its CHEBY2 method.
h  = fdesign.lowpass(Fpass, Fstop, Apass, Astop, Fs);
if(type==1)
Hd = design(h, 'cheby2', 'MatchExactly', match);
end

if(type==2)
Hd = design(h, 'equiripple');
end

% [EOF]
