function [ps_bin, ps_max, ps_latency, ps_deriv] = GetVariousPupilFeatures(ps_all,t_epoch,binstart,binwidth)

% Created 8/13/13 by DJ.

dt = mode(diff(t_epoch));
[ps_bin, ps_max, ps_latency, ps_deriv] = deal(cell(1,numel(ps_all)));

for iSubj = 1:numel(ps_all)
    [psMax,iMax] = max(ps_all{iSubj}(:,t_epoch>0),[],2);
    ps_max{iSubj} = psMax;
    ps_latency{iSubj} = t_epoch(iMax)';
    dp = [nan(size(ps_all{iSubj},1),1), diff(ps_all{iSubj},[],2)];
    dpdt = dp/dt;
    
    % Build windowed classifier
    binstart_samples = find(ismember(t_epoch,binstart));    
    binwidth_samples = round(binwidth/dt);
    bindata = nan(size(ps_all{iSubj},1),numel(binstart));
    deriv_bindata = nan(size(dpdt,1),numel(binstart));
    for i=1:numel(binstart)        
        bindata(:,i) = nanmean(ps_all{iSubj}(:,binstart_samples(i)+(1:binwidth_samples)-1),2);
        deriv_bindata(:,i) = nanmean(dpdt(:,binstart_samples(i)+(1:binwidth_samples)-1),2);        
    end
    bindata(isnan(bindata)) = 0; % if unknown, say no info.
    deriv_bindata(isnan(deriv_bindata)) = 0; % if unknown, say no info.
    ps_bin{iSubj} = bindata;
    ps_deriv{iSubj} = deriv_bindata;
end