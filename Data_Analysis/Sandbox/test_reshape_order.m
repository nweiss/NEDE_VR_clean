clear all; close all; clc;

a = nan(3,4,5);
for i = 1:5
    for j = 1:3
        for k = 1:4
            a(j,k,i) = i;
        end
    end
end

% THIS DOES NOT WORK!
% b = reshape(a,size(a,2) * size(a,3), size(a,1));
% 
% tmp = permute(a, [3, 2, 1]);
% b = reshape(a,size(a,2) * size(a,3), size(a,1));

% USE THIS INSTEAD
tmp1 = [];
for i = 1:size(a,3)
    tmp1 = cat(2, tmp1, a(:,:,i));  
end

tmp2 = [];
counter1 = 1;
counter2 = size(a,2);
for i = 1:size(a,3)
    tmp2 = cat(3,tmp2, tmp1(:,counter1:counter2));
    counter1 = counter1+size(a,2);
    counter2 = counter2+size(a,2);
end

disp('done')