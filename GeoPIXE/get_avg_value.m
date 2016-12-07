function val = get_avg_value(im, coords)

coords = round(coords);
left = coords(1);
width = coords(3);
bottom = coords(2);
height = coords(4);

x = [left left+width left+width left left];
y = [bottom bottom bottom+height bottom+height bottom];

hold on
plot(x, y, 'w-', 'linewidth', 2);
hold off

subim = im(y(1):y(3), x(1):x(2));
val = mean(subim(:));