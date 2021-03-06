nSensitivity = 0.9;
graph_1 = load('graph_3_tiny.mat');
result_eye = {};
while isempty(result_eye) 
    result_classifier = lsl_resolve_byprop(lib,'name','Python'); 
    disp('Waiting for: Classifier stream');
end
inlet_classifier = lsl_inlet(result_classifier{1});
disp('Opened inlet: Classifier -> Matlab');

% need to time this properly
result = dlmread('../NEDE_Game/objectLocs.txt',',');

% we should change this order and probably read these in from a file
image_types = {'car_side', 'grand_piano', 'laptop','schooner'};

objectList = cell(1,length(result));
billboardIdList = zeros(1,length(result));

for i = 1:length(result)
    image_type = result(i,3) + 1;
    pict_num = result(i,4) + 1;
    billboardIdList(i) = result(i,5);
    full_string = strcat(image_types{image_type},'-',sprintf('%04d', pict_num)); %% get the number into the right string format
    objectList{i} = full_string;
end

num_classified = 1;

while true
   [a,b] = inlet_classifier.pull_sample(0);
   if ~isempty(a)
       
       classifier_output(num_classified,:) = a;
       
       target_indices = classifier_output(:,2) == 1;
       distractor_indices = classifier_output(:,2) == 0;
       
       iTargets = classifier_output(target_indices,1);
       % get the order the billboards should be visited in
       [outputOrder,outputScore,isSelfTunedTarget] = RerankObjectsWithTag(objectList,iTargets,nSensitivity,graph_1.graph);
       
       % sort outputScore so it goes from billboard 0 - highest num
       orderedScores = zeros(1,length(outputOrder));
       
       for i = 0:length(outputOrder)-1
            orderedScores(i+1) = outputScore(outputOrder == i);
       end
       % get the order of the rest of the b
       
       highProbTargets = outputOrder(outputScore > 0.9);
       
       counter = 1;
       unseenOutputOrder = [];
       for i=1:length(orderedScores)
           if ismember(highProbTargets(i),target_indices)
               orderedScores(i) = 1;
           elseif ismember(highProbTargets(i), distractor_indices)
               orderedScores(i) = 0;
           else 
               unseenOutputOrder(counter) = highProbTargets(i);
               counter = counter + 1;
           end
       end    
       num_classified = num_classified + 1;
       
       dlmwrite('../NEDE_Game/interestScores.txt',orderedScores')
       
       display = 1;
       usegridconstraints = true;
       billboardLocations = result(1:2,unseenOutputOrder+1);
       
       pathLocations = convertBillboardtoPathLocation(billboardLocations);
       tspOutput = solveTSP(pathLocations, display, usegridconstraints);       
       dlmwrite('../NEDE_Game/newCarPath.txt', horzcat(tspOutput,zeros(1,length(tspOutput))));
   end
end