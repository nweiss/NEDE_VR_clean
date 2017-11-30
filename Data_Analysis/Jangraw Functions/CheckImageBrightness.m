function brightness_all = CheckImageBrightness(R,subjects,sessions_cell)

% Created 8/19/13 by DJ.

[~,brightness] = GetImageBrightness;
categories = {'car_side','grand_piano','laptop','schooner'};

nSubjects = numel(subjects);
nRows = ceil(sqrt(nSubjects));
nCols = ceil(nSubjects/nRows);

figure;
brightness_all = cell(1,nSubjects);
for i=1:nSubjects
    subject = subjects(i); sessions = sessions_cell{i};
    fprintf('Subject %d/%d: %d...\n',i,nSubjects,subject);
    
    % Load data
    load(sprintf('ALLEEG%d_NoeogEpochedIcaCropped.mat',subject)); % ALLEEG
    [objects, objnames, objlocs, objtimes, objisessions] = GetObjectList(subject,sessions); % get a list of every object seen and its properties
    
    % Match EEG epochs (trials with interest scores) to object numbers
    iObjects_targets = EpochToObjectNumber(ALLEEG(2),objtimes, objisessions); % Find the objects that were seen in the target EEG struct's trials
    iObjects_distractors = EpochToObjectNumber(ALLEEG(1),objtimes, objisessions); % Find the objects that were seen in the distractor EEG struct's trials

    % Get object names
    truth = [R(i).truth]==1;
    iObjects_all = nan(size(truth));
    iObjects_all(truth)=iObjects_targets;
    iObjects_all(~truth)=iObjects_distractors;
    objnames_all = objnames(iObjects_all);
    
    % Get object brightness
    brightness_all{i} = zeros(size(objnames_all));
    for j=1:numel(objnames_all)        
        iDash = find(objnames_all{j}=='-');
        isCat = strcmp(objnames_all{j}(1:iDash-1),categories);
        iIm = str2double(objnames_all{j}(iDash+1:end));
        brightness_all{i}(j) = brightness(isCat,iIm);
    end
    
    % get target category    
    targname = objnames{iObjects_targets(1)};
    iDash = find(targname=='-');
    targcat = targname(1:iDash-1);
   
    % Scatter plot of brightness vs "y value" (interest score)
    subplot(nRows,nCols,i);
    scatter(brightness_all{i}(~truth),R(i).y(~truth));
    hold on
    scatter(brightness_all{i}(truth),R(i).y(truth),'r');
    xlabel('brightness')
    ylabel('interest score')
    title(show_symbols(sprintf('Subject %d: target = %s',subject,targcat)));
    
    
end