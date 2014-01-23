function v= add_verticals(x, linespec)
% Add vertical lines at each of the positions in x (that fall within the
% existing figure limits) to the current plot.
v = [];
ax = axis;
xmin = ax(1); xmax = ax(2);
ymin = ax(3); ymax = ax(4);
x = x(find(x>xmin .* x<xmax));
allx = [column(x) column(x) NaN(length(x),1)]';
ally = repmat([ymin ymax NaN], length(x), 1)';
hold on;
plot(allx(:), ally(:), linespec);
hold off;
