function h = drawrect(coords, varargin)

left = coords(1);
width = coords(3);
bottom = coords(2);
height = coords(4);

x = [left left+width left+width left left];
y = [bottom bottom bottom+height bottom+height bottom];
hold on
if nargin > 1
    h = plot(x, y, varargin{:});
else
    h = plot(x, y, 'w-', 'linewidth', 2);
end
hold off