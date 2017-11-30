% test upsample by non-integer number
clear all; close all; clc;

t = linspace(1,20,100);
x = 2*sin(t) + rand(1,100) + t;

figure
plot(x,'*')
title('before upsample')

xnew = interp1(t, x, linspace(1,20,1037));
figure
plot(xnew,'*')
title('after upsample')