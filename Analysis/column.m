function y = column(x)
% function y = column(x) returns the column vector form of x
y=squeeze(x);
if size(x, 2) > 1
    y = y';
end