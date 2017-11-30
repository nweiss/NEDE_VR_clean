tic


cities = randi([0 15],[50 2]);

tsp_cityList = zeros(1,length(cities));

display = 1;
usegridconstraints = true;
tsp_cityList = solveTSP( cities, display, usegridconstraints);
toc