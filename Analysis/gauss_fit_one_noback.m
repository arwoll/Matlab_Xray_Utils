function m = gauss_fit_one_noback(x,y)
% peak_data = gauss_fit_one(x,y, varargin) accepts, as input, a single set
% of x's and y's as input, and fits it  to a gaussian profile,
% returning the resulting fit. The y values are assumed to have
% poisson-style weights

peak_data = find_peak(x, y, 'mode', 'lin', 'back', [1 length(y)]);

delsq = y;
mx = max(delsq);
delsq(delsq<=0) = mx;

wts = (1./delsq);

dfe = length(x) - 4;
nonlin_model = fittype('area*2.35482/(fwhm*sqrt(2*pi))*exp(-0.5*((xdata-cen)*2.35482/fwhm).^2)',...
    'ind', 'xdata', 'coeff', {'area', 'cen', 'fwhm'});

nonlin_opts = fitoptions('Method', 'NonLinearLeastSquares', 'Display', 'off', ...
    'StartPoint', [peak_data.area peak_data.com  peak_data.fwhm], ...
    'Weights', wts);

[m, goodness, output] = fit(x, y,nonlin_model, nonlin_opts);


