clear all; clc; close all;

x = (1:500)';
y = (1:500)';
for i = 1:length(y)
    y(i) = y(i) + 100*rand;
end

figure
plot(x,y,'.')
title('before PCA')

mat = [x,y];
[coeff, score] = pca(mat);

figure
plot(score(:,1),score(:,2),'.')
title('after pca')
legend('component 1','component 2')
ylim([-300,300])