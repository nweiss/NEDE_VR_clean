clear all; clc; close all;

y=randn(30,80); x=1:size(y,2);
a = shadedErrorBar(x,mean(y,1),std(y),'g');
b = get(1, 'children');
set(b, 'LineWidth', 5)
%shadedErrorBar(x,y,{@median,@std},{'r-o','markerfacecolor','r'});    
%shadedErrorBar([],y,{@median,@std},{'r-o','markerfacecolor','r'});  