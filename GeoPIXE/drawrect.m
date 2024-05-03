function [coords, inds] = drawrect(coords)

coords = round(coords);
left = coords(1);
width = coords(3);
bottom = coords(2);
height = coords(4);

x = [left left+width left+width left left];
y = [bottom bottom bottom+height bottom+height bottom];

inds = [y(1) y(3) x(1) x(2)];
hold on
if nargin > 2
    h = plot(x, y, varargin);
else
    h = plot(x, y, 'w-', 'linewidth', 2);
end
hold off