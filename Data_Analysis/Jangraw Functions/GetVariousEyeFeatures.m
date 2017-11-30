function [dwell_time, sac_size, sac_speed, fixtime_max, fixtime_mean, nsac, fixtime_first, rxn_time, fixtime_b4, fixtime_after, sacsize_away, dist2obj_b4, dist2obj_first, dist2obj_last, dist2obj_after, fixtime_last] = GetVariousEyeFeatures(subjects,sessions_cell)

% Created 8/13/13 by DJ.
% Updated...
% Updated 8/28/13 by DJ - added 2 more outputs

DIST_CUTOFF = 100;

[dwell_time, sac_size, sac_speed, fixtime_max, fixtime_mean, nsac, fixtime_first, rxn_time, fixtime_b4, fixtime_after, sacsize_away, dist2obj_b4, dist2obj_first, dist2obj_last, dist2obj_after, fixtime_last, isTarget] = deal(cell(1,numel(subjects)));

for iSubj = 1:numel(subjects)
    fprintf('Subject %d/%d...\n',iSubj,numel(subjects));
    subject = subjects(iSubj);
    sessions = sessions_cell{iSubj};
    
    % Get dwell time and saccade info    
    y = loadBehaviorData(subject,sessions,'3DS');
%     [dwell_cell isToTarget_cell] = GetDwellTimes(y);
    [dwell_time_0,sac_size_0, sac_speed_0, fixtime_max_0, fixtime_mean_0, nsac_0, fixtime_first_0, rxn_time_0, fixtime_b4_0, fixtime_after_0, sacsize_away_0, dist2obj_b4_0, dist2obj_first_0, dist2obj_last_0, dist2obj_after_0, fixtime_last_0] = deal(cell(1,numel(y)));
    [iOn, iOff, isToTarget] = deal(cell(1,numel(y)));
    for i=1:numel(y)
        times = y(i).eyelink.saccade_times;
        dist = DistToObject(y(i),y(i).eyelink.saccade_positions,times);
        isOnObject = dist<DIST_CUTOFF;
                
        objectOnTimes = y(i).eyelink.object_events(y(i).eyelink.object_events(:,2)<1000,1);
        objectOffTimes = y(i).eyelink.object_events(y(i).eyelink.object_events(:,2)>1000,1);    
        objectNumbers = y(i).eyelink.object_events(y(i).eyelink.object_events(:,2)>1000,2)-1000;
        objectIsTarget = strcmp('TargetObject',{y(i).objects(objectNumbers).tag});
        for j=1:length(objectOnTimes)
            % iOn_all{i}{j} = find(times>objectOnTimes(j) & times<objectOffTimes(j) & isOnObject);
            iOnTime = find(times>objectOnTimes(j) & times<objectOffTimes(j) & isOnObject,1); % first saccade to this object
            if ~isempty(iOnTime)
                iOffTime = find(times>times(iOnTime) & ~isOnObject,1); % first saccade away from this object
                dwell_time_0{i}(j) = min(objectOffTimes(j),times(iOffTime))-times(iOnTime); % when the obj goes offscreen or the subj saccades away, whichever comes first
            else
                iOnTime = NaN;
                iOffTime = NaN;
                dwell_time_0{i}(j) = NaN;
            end
            iOn{i}(j) = iOnTime;
            iOff{i}(j) = iOffTime;
            isToTarget{i}(j) = objectIsTarget(j);
            
        end
        
        %% Extract features
        nanners = find(isnan(iOn{i})); % find nan trials so we can set them back to nan later
        iOn{i}(nanners) = 1;
        iOff{i}(nanners) = 2;
        sac_size_0{i} = sqrt(sum( (y(i).eyelink.saccade_positions(iOn{i},:)-y(i).eyelink.saccade_start_positions(iOn{i},:)).^2 ,2));
        sdur = y(i).eyelink.saccade_times(iOn{i})-y(i).eyelink.saccade_start_times(iOn{i});
        sac_speed_0{i} = sac_size_0{i}./sdur;   
        fixtime_first_0{i} = diff(y(i).eyelink.fixation_times(iOn{i}+1,:),[],2);
        rxn_time_0{i} = y(i).eyelink.saccade_start_times(iOn{i}) - objectOnTimes;
        
        % New from Ajanki 2009
        fixtime_b4_0{i} = diff(y(i).eyelink.fixation_times(iOn{i},:),[],2);
        fixtime_after_0{i} = diff(y(i).eyelink.fixation_times(iOff{i}+1,:),[],2);
        sacsize_away_0{i} = sqrt(sum( (y(i).eyelink.saccade_positions(iOff{i},:)-y(i).eyelink.saccade_start_positions(iOff{i},:)).^2 ,2));
        dist2obj_b4_0{i} = DistToObjectCenter(y(i),y(i).eyelink.saccade_start_positions(iOn{i},:),y(i).eyelink.saccade_start_times(iOn{i}));
        dist2obj_first_0{i} = DistToObjectCenter(y(i),y(i).eyelink.saccade_positions(iOn{i},:),y(i).eyelink.saccade_times(iOn{i}));
        dist2obj_last_0{i} = DistToObjectCenter(y(i),y(i).eyelink.saccade_start_positions(iOff{i},:),y(i).eyelink.saccade_start_times(iOff{i}));
        
        % Additions 8/28/13
        dist2obj_after_0{i} = DistToObjectCenter(y(i),y(i).eyelink.saccade_positions(iOff{i},:),y(i).eyelink.saccade_start_times(iOff{i}));
        fixtime_last_0{i} = diff(y(i).eyelink.fixation_times(iOff{i},:),[],2);
        
        
        [fixtime_max_0{i},fixtime_mean_0{i},nsac_0{i}] = deal(nan(size(sac_speed_0{i})));
        for j=1:length(iOn{i})
            ftimes = diff(y(i).eyelink.fixation_times(iOn{i}(j)+1:iOff{i}(j),:)+1,[],2);
            fixtime_max_0{i}(j) = nanmax(ftimes);
            fixtime_mean_0{i}(j) = nanmean(ftimes);
        end
        nsac_0{i} = (iOff{i}-iOn{i})';
        dwell_time_0{i} = dwell_time_0{i}';
        % replace nans
        dwell_time_0{i}(nanners) = [];
        sac_size_0{i}(nanners) = [];
        sac_speed_0{i}(nanners) = [];
        fixtime_max_0{i}(nanners) = [];
        fixtime_mean_0{i}(nanners) = [];
        nsac_0{i}(nanners) = [];
        fixtime_first_0{i}(nanners) = [];
        rxn_time_0{i}(nanners) = [];
        fixtime_b4_0{i}(nanners) = [];
        fixtime_after_0{i}(nanners) = [];
        sacsize_away_0{i}(nanners) = [];
        dist2obj_b4_0{i}(nanners) = [];
        dist2obj_first_0{i}(nanners) = [];
        dist2obj_last_0{i}(nanners) = [];
        dist2obj_after_0{i}(nanners) = [];
        fixtime_last_0{i}(nanners) = [];
    end
    
    % Append trials across datasets    
    dwell_time{iSubj} = cat(1,dwell_time_0{:});
    sac_size{iSubj} = cat(1,sac_size_0{:}); 
    sac_speed{iSubj} = cat(1,sac_speed_0{:}); 
    fixtime_max{iSubj} = cat(1,fixtime_max_0{:}); 
    fixtime_mean{iSubj} = cat(1,fixtime_mean_0{:});
    nsac{iSubj} = cat(1,nsac_0{:}); 
    fixtime_first{iSubj} = cat(1,fixtime_first_0{:}); 
    rxn_time{iSubj} = cat(1,rxn_time_0{:});
    isTarget{iSubj} = cat(1,isToTarget{:});
    
    fixtime_b4{iSubj} = cat(1,fixtime_b4_0{:});
    fixtime_after{iSubj} = cat(1,fixtime_after_0{:});
    sacsize_away{iSubj} = cat(1,sacsize_away_0{:});
    dist2obj_b4{iSubj} = cat(1,dist2obj_b4_0{:});
    dist2obj_first{iSubj} = cat(1,dist2obj_first_0{:});
    dist2obj_last{iSubj} = cat(1,dist2obj_last_0{:});
    
    dist2obj_after{iSubj} = cat(1,dist2obj_after_0{:});
    fixtime_last{iSubj} = cat(1,fixtime_last_0{:});
    
    % Load EEG
    load(sprintf('ALLEEG%d_NoeogEpochedIcaCropped.mat',subject)); % ALLEEG
    
    %% Find trials rejected by EEG
    badtrials = ALLEEG(1).etc.rejectepoch;    
    % Remove trials rejected by EEG so trials still match up
    fprintf('removing %d trials to match EEG record...\n',sum(badtrials));
    % reject offending trials
    dwell_time{iSubj}(badtrials) = []; 
    sac_size{iSubj}(badtrials) = []; 
    sac_speed{iSubj}(badtrials) = [];
    fixtime_max{iSubj}(badtrials) = [];
    fixtime_mean{iSubj}(badtrials) = [];
    nsac{iSubj}(badtrials) = [];
    fixtime_first{iSubj}(badtrials) = [];
    rxn_time{iSubj}(badtrials) = [];
    isTarget{iSubj}(badtrials) = [];
    
    fixtime_b4{iSubj}(badtrials) = [];
    fixtime_after{iSubj}(badtrials) = [];
    sacsize_away{iSubj}(badtrials) = [];
    dist2obj_b4{iSubj}(badtrials) = [];
    dist2obj_first{iSubj}(badtrials) = [];
    dist2obj_last{iSubj}(badtrials) = [];
    
    dist2obj_after{iSubj}(badtrials) = [];
    fixtime_last{iSubj}(badtrials) = [];

    disp('Done!')
end

