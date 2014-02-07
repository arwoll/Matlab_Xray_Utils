function horlin(y,varargin)
% Plots a horizontal line at location of x into last called plot
% second input on/off allows for hold on or off following function,
% defaults to hold off
f=fittype('poly1')
line=cfit(f,0,y)
hold on
plot(line)
if (nargin==1)&& (varargin(1)=='on')
else
    hold off
end