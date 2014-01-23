function ray(ymin, ymax)
%v = [];
ax = axis(gca);
if isnan(ymin)
    ymin = ax(3);
end
if isnan(ymax)
    ymax = ax(4);
end
n_ax = [ax(1) ax(2) ymin ymax];
axis(n_ax);