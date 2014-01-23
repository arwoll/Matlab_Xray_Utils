function y = row (x)
% function y = row(x) returns the row vector form of x
y=squeeze(x);
if size(x, 1) > 1
    y = y';
end