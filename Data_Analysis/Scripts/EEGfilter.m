function [sig] = EEGfilter(sig,Fs,type)

% EEGfilter is a function to filter EEG signals. 
% Input: sig - a 2d matrix of EEG signals to be filtered. can be [channels x time] or [time x channels]
%	 Fs - Sampling frequency of sig
%	 type - 1 for IIR 2 for FIR filtering


%transpose input if need be.
if (size(sig,1)<size(sig,2))
    sig=sig';
end


% if IIR
if(type==1)
Hd = HPF(Fs,type);
sig=filtfilt(Hd.sosMatrix,Hd.ScaleValues, sig);
Hd = LPF(Fs,type);
sig=filtfilt(Hd.sosMatrix,Hd.ScaleValues, sig);


%if FIR
if(type==2)
Hd = HPF(Fs,type);   
sig=filtfilt(Hd.Numerator,1, sig);    
Hd = LPF(Fs,type);
sig=filtfilt(Hd.Numerator,1, sig);

end

