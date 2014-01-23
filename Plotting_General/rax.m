function v = rax(xmin, xmax)
v = [];
ax = axis(gca);
if isnan(xmin)
    xmin = ax(1);
end
if isnan(xmax)
    xmax = ax(2);
end
n_ax = [xmin xmax ax(3) ax(4)];
axis(n_ax);