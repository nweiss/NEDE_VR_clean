% TEMP_OneSidedSignRanks.m
%
% Created 7/22/13 by DJ.

foo = load('TEMP_HybridClassifier_Results.mat');
fields = fieldnames(foo);
Azfields = fields(strncmp('Az_',fields,3));
p = zeros(1,numel(Azfields));
fprintf('---Two-tailed sign-rank tests: HYBRID---\n');
for i=1:numel(Azfields)
    p(i) = signrank(foo.Az_eegpsdt - foo.(Azfields{i}),0);%,'tail','right');
    fprintf('Az_eegpsdt > %s: p = %g\n',Azfields{i},p(i));
end
fprintf('---Two-tailed sign-rank tests: HYBRID + CV---\n');
for i=1:numel(Azfields)
    p(i) = signrank(foo.Az_eegpsdt_cv - foo.(Azfields{i}),0);%,'tail','right');
    fprintf('Az_eegpsdt_cv > %s: p = %g\n',Azfields{i},p(i));
end

fprintf('---Two-tailed sign-rank tests: CV---\n');
fields = fieldnames(foo.stats_eegpsdt);
p_stats = zeros(1,numel(fields));
for i=1:numel(fields);
    temp = cat(1,foo.stats_eegpsdt.(fields{i}));    
    if size(temp,2)==1
        temp(:,2) = 100;
    end
    p_stats(i) = signrank(temp(:,2)-temp(:,1),0);
    fprintf('%s_cv > %s_hci: p = %g\n',fields{i},fields{i},p_stats(i));
end
pctFound = cat(1,foo.stats_eegpsdt.pctFound);
efficiency = pctFound(:,2)./cat(1,foo.stats_eegpsdt.pctDistance);
p_efficiency = signrank(efficiency, 1);
fprintf('efficiency_cv > efficiency_random: p = %g\n',p_efficiency);

%%
fprintf('---One-tailed sign-rank tests: HYBRID---\n');
for i=1:numel(Azfields)
    p(i) = signrank(foo.Az_eegpsdt - foo.(Azfields{i}),0,'tail','right');
    fprintf('Az_eegpsdt > %s: p = %g\n',Azfields{i},p(i));
end
fprintf('---One-tailed sign-rank tests: HYBRID + CV---\n');
for i=1:numel(Azfields)
    p(i) = signrank(foo.Az_eegpsdt_cv - foo.(Azfields{i}),0,'tail','right');
    fprintf('Az_eegpsdt_cv > %s: p = %g\n',Azfields{i},p(i));
end

fprintf('---One-tailed sign-rank tests: CV---\n');
fields = fieldnames(foo.stats_eegpsdt);
p_stats = zeros(1,numel(fields));
for i=1:numel(fields);
    temp = cat(1,foo.stats_eegpsdt.(fields{i}));    
    if size(temp,2)==1
        temp(:,2) = 100;
    end
    p_stats(i) = signrank(temp(:,2)-temp(:,1),0,'tail','right');
    fprintf('%s_cv > %s_hci: p = %g\n',fields{i},fields{i},p_stats(i));
end
pctFound = cat(1,foo.stats_eegpsdt.pctFound);
efficiency = pctFound(:,2)./cat(1,foo.stats_eegpsdt.pctDistance);
p_efficiency = signrank(efficiency, 1,'tail','right');
fprintf('efficiency_cv > efficiency_random: p = %g\n',p_efficiency);

clear foo fields Azfields temp p p_stats