function m = err_fit_nodecay(x, y, startpoint)
% function m = err_fit(x, y, startpoint)
%
% fits x and y to:
%   'y=A*0.5*(1 + erf((x-X0)*2.35/(sqrt(2)*FWHM))) + BKGD'
%   startpoint is a vector of initial valuesfor [A, X0, FWHM,  BKGD] 


errfun = fittype('A*0.5*(1 + erf((x-X0)*2.35/(sqrt(2)*FWHM)))+BKGD', ...
    'coeff', {'A', 'X0', 'FWHM', 'BKGD'});


errfit_opts = fitoptions(errfun);
err_sp = startpoint; %[5 -.005 .001 100];     %Estimated values of A, X0, and FWHM
err_lower = [0  -Inf  0 0];
err_upper = [Inf  Inf  Inf Inf];
ys_for_wgts = y;
if any(y<=0)
    ys_for_wgts(y<=0) = min(ys_for_wgts(ys_for_wgts>0));
end
set(errfit_opts, 'Lower', err_lower, 'Upper', err_upper, ...
    'Startpoint', err_sp)
%set(errfit_opts, 'Lower', err_lower, 'Upper', err_upper, ...
%    'Weights', 1./ys_for_wgts, 'Startpoint', err_sp)

[m,g,o] = fit(x,y, errfun, errfit_opts);


