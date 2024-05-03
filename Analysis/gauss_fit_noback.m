function peak_data = gauss_fit_noback(x,y, varargin)
% peak_data = gauss_fit(x,y, varargin) accepts, as input, a set of
% x's and y's as input, and fits each tuple (x,y) to a gaussian profile,
% returning (at least) the area under each peak. (Each tuple is assumed to
% have only one such peak.) It is an analog of find_peak, which uses only
% simple summing and interpolation for the same purpose.
%
% There are different modes of operation, corresponding to different
% assumptions regarding the tuples (x,y). In 'linear' mode, the peak is
% assumed not to change position or width. In this case (appropriate for
% the vortex detector, or other detectors at low count rates...), the fits
% for individualt spectra simplies to the linear case, which is very fast.
% 
% modes:  'lin' or 'nonlin': the algorithm used for most of the fits...
%
% NOTES: x,y assumed to be column vectors...
%
mode = 'lin';
sampley = [];
peak_data = [];
delta = [];
use_wts = 1;

nvarargin = nargin -2;
if nvarargin > 1
    for k = 1:2:nvarargin
        switch varargin{k}
            case 'mode'
                if any(strcmp(varargin{k+1}, {'lin', 'nonlin'}))
                    mode = varargin{k+1};
                else
                    errorlg('Oops, unrecognized mode', 'gaussfit errror');
                    return
                end
            case 'sampley'
                if isnumeric(varargin{k+1})
                    sampley = varargin{k+1};
                else
                    errordlg(['optional argument sampley must be followed by an array\n' ...
                        'containing sample y values for use with param estimate'], ...
                        'gaussfit error');
                    return
                end
            case 'delta'
                if isnumeric(varargin{k+1}) && all(size(varargin{k+1}) == size(y))
                    delta = varargin{k+1};
                else
                    errordlg('optional argument detla must be the same dimensions as y\n', ...
                        'gaussfit error');
                    return
                end
            case 'use_wts'
                use_wts = varargin{k+1};
            otherwise
                warndlg(sprintf('Unrecognized input argument %s',varargin{k}));
        end
    end
end

% ARW adds this -- want a sampley if lin OR nonlin
% if strcmp(mode, 'lin') && 
if isempty(sampley)
    sampley = sum(y, 2);
elseif length(sampley) ~= size(y, 1)
    errorlg('Oops, sample must be the same size as the number of rows in y', ...
        'gaussfit errror');
end

X_CEN = mean(x);
x = x-X_CEN;

ny = length(sampley);
peak_data = find_peak(x, sampley, 'mode', 'lin', 'back', [1 ny]);

delsq = sampley;
mx = max(delsq);
delsq(delsq<=1e-5) = mean(sampley);

if use_wts
    wts = (1./delsq);
else
    wts = ones(size(sampley));
end
dfe = length(x) - 4;
% nonlin_model = fittype('bk + area*2.35482/(fwhm*sqrt(2*pi))*exp(-0.5*((xdata-cen)*2.35482/fwhm).^2)',...
%     'ind', 'xdata', 'coeff', {'area', 'bk', 'cen', 'fwhm'});

nonlin_model = fittype('area*2.35482/(fwhm*sqrt(2*pi))*exp(-0.5*((xdata-cen)*2.35482/fwhm).^2)',...
    'ind', 'xdata', 'coeff', {'area', 'cen', 'fwhm'});

startpoint = [peak_data.area peak_data.com  peak_data.fwhm];
% low_bound = [.8*startpoint(1) -Inf .8*startpoint(3) 0.8*startpoint(4)];
% high_bound = [1.2*startpoint(1) Inf 1.2*startpoint(3) 1.2*startpoint(4)]; 

nonlin_opts = fitoptions('Method', 'NonLinearLeastSquares', 'Display', 'off', ...
    'StartPoint', startpoint, ...
    'Weights', wts); %'Lower', low_bound, 'Upper', high_bound);


%area = pars(1);bk = pars(2); cen=pars(3); fwhm=pars(4);  
%figure
%plot(x, sampley, 'bo', x, gaussbk( [peak_data.counts peak_data.bkgd peak_data.com  peak_data.fwhm], x), 'r-')
[gaussfit, goodness, output] = fit(x, double(sampley),nonlin_model, nonlin_opts);
%hold on;
%plot(x, gaussfit(x), 'g-');
%hold off;
fval = goodness.sse/goodness.dfe;
%fval = sum((output.residuals.*wts).^2)/goodness.dfe
%fval = sum((output.residuals).^2)/goodness.dfe

peak_data.com = gaussfit.cen+X_CEN;
peak_data.fwhm = gaussfit.fwhm;

cen = gaussfit.cen;
fwhm = gaussfit.fwhm;
area = gaussfit.area;

%bk = gaussfit.bk;

lin_model = fittype({'2.35482/(fwhm*sqrt(2*pi))*exp(-0.5*((x-cen)*2.35482/fwhm).^2)', '1'},...
    'problem', {'cen', 'fwhm'},'coeff', {'area', 'bk'});
%model = fittype({'gauss([cen fwhm], x)', '1'}, 'problem', {'cen', 'fwhm'},'coeff', {'area', 'bk'});
lin_opts = fitoptions(lin_model);
set(lin_opts, 'Lower', [0 0]);
% tic;
% iter = 0;

nspectra = size(y, 2);
progress = waitbar(0, 'Background Subtraction...Please Wait');
%tic
if ~isempty(delta)
    delta = delta.*delta;
end

peak_data.area = zeros(1,nspectra);
peak_data.chi = zeros(1, nspectra);
peak_data.compare = zeros(size(y, 1), nspectra);


for k = 1:nspectra
    i_vs_e = y(:,k);
    if isempty(delta)
        delsq = i_vs_e;
    else
        delsq = delta(:,k);
    end
    mx = max(delsq);
    if mx == 0
        mx = 1;
    end
    delsq(delsq<=0) = mx;
    wts = 1./delsq;
    if strcmp(mode, 'lin')
        set(lin_opts, 'Weights', wts);
        [foo, good,out] = fit(x, i_vs_e, lin_model, lin_opts, 'problem', {cen , fwhm});
    else % mode == 'nonlin'
        set(nonlin_opts, 'Weights', wts);
        [foo, good,out] = fit(x, i_vs_e, nonlin_model, nonlin_opts);
    end
        
    peak_data.compare(:,k) = foo(x);
    peak_data.area(k) = foo.area;
    peak_data.chi(k) = good.sse/good.dfe;
%    plot(x, y(:,k), 'bo', x,foo(x), 'r-');
    waitbar(k/nspectra, progress);
end
%toc
close(progress);
%h = figure;
%plot(chi);
%close(h);


