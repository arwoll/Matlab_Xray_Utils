function [xcol, ycol] = my_eb(x,y,e, varargin)
% function [xcol, ycol] = my_eb(x,y,e)
% requires row() in ~woll/Matlab/woll
npts = length(x);
nanrow = NaN(1, npts);
zrow = zeros(1, npts);

if nargin == 4 && strcmp(varargin{1}, 'log')
    w = .3*mean(x(2:end)./x(1:(end-1)));
    xcol = repmat([1/w; w; 1; 1; 1/w; w; NaN], 1, npts) .* repmat(row(x),7,1);
elseif nargin == 4
    w = varargin{1};
    xcol = repmat([-w; w; 0; 0; -w; w; NaN], 1, npts) + repmat(row(x),7,1);
else
    w = .2*mean(x(2:end) - x(1:(end-1)));
    xcol = repmat([-w; w; 0; 0; -w; w; NaN], 1, npts) + repmat(row(x),7,1);
end

ycol = [row(-e);row(-e); row(-e); row(e); row(e); row(e); nanrow] + repmat(row(y),7,1);
xcol = xcol(:);
ycol = ycol(:);