clear all; clc; close all;

a = (1:100);
b = linspace(0,5,100);
c = (15:114);
d = linspace(5,0,100);

figure
H1 = shadedErrorBar((1:100),a, b, '-r');
hold on
H2 = shadedErrorBar((1:100),c,d, '-b');
legend([H1.mainLine, H2.mainLine],'1','2')
