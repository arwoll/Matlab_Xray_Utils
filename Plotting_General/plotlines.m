function v= plotlines(x, linespec, varargin)
if nargin == 3
    lw = varargin{1};
else
    lw = 1.0;
end

v = [];
ax = axis;
xmin = ax(1); xmax = ax(2);
ymin = ax(3); ymax = ax(4);
x = x(find(x>xmin .* x<xmax));
allx = [column(x) column(x) NaN(length(x),1)]';
ally = repmat([ymin ymax NaN], length(x), 1)';
plot(allx(:), ally(:), linespec, 'linewidth', lw);
