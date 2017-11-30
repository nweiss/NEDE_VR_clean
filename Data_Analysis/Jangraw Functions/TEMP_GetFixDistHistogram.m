% TEMP_GetFixDistHistogram.m
%
% Plots a histogram of all the saccade endpoints' distances from the
% object.
%
% Created 9/30/13 by DJ for one-time use.

clear dist;
for iSubj = 1:numel(YDATA)
    fprintf('---Subject %d/%d...\n',iSubj,numel(YDATA));
    for i = 1:numel(YDATA{iSubj})
        fprintf('------Session %d/%d...\n',i,numel(YDATA{iSubj}));
        x = YDATA{iSubj}(i);
        
        dist{iSubj}{i} = DistToObject(x,x.eyelink.saccade_positions,x.eyelink.saccade_times);
    end
end
disp('Done!')

%%
% Append all
distAllCell = cell(1,numel(YDATA));
for iSubj = 1:numel(YDATA)
    distAllCell{iSubj} = cat(1,dist{iSubj}{:});
end
distAll = cat(1,distAllCell{:});

figure(992); clf;
hist(distAll(~isinf(distAll)),100);
xlabel('Distance from saccade endpoint to Object (pixels)');
ylabel('# saccades');
title(sprintf('Histogram for %d saccades across %d subjects',sum(~isinf(distAll)),numel(YDATA)));