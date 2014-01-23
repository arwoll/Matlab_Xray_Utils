function m = gauss_fit(x,y, startpoint)
% function y = gauss_fit(X, Y, startpoint)
%   pars(1) : X0
%   pars(2) : FWHM
% Returns a normalized gaussian function centered on pars(1) and with full-width
% at half maximum pars(2). (FWHM = 2.35482*sigma. A guassian is typically
% defined exp(-0.5*(x/sigma)^2), sigma is the second moment of the
% disttibution.

errfun = fittype('A/(FWHM*sqrt(2*pi)/2.35483)*exp(-0.5*(2.35483*(x-X0)/FWHM).^2)', ...
    'coeff', {'A', 'X0', 'FWHM'});


errfit_opts = fitoptions(errfun);
err_sp = startpoint; %[5 -.005 .001 100];     %Estimated values of A, X0, and FWHM
err_lower = [0  -Inf  0];
err_upper = [Inf  Inf  Inf];
set(errfit_opts, 'Lower', err_lower, 'Upper', err_upper, ...
    'Startpoint', err_sp)

[m,g,o] = fit(x,y, errfun, errfit_opts);