function peak_data = find_peak(x,y, varargin)
% peak_data = find_peak(x,y, varargin)
% Returns information about the peak in y
%
% 'thresh' optional arg in added 6/19/07 for use with openspec-1.1, particularly
% looking at diffuse data from G3, wich very asymmetric peaks...
%
% y values are assumed to be column vectors, i.e.  Multiple y values can be placed in
% adjacent columns of y.  x, at present, is only allowed to be a single
% vector
%
% varargin can either be empty, in which case no background subtraction is
% performed, or can be one or more pairs of parameter / value pairs:
%     'mode'  : 'mean', 'lin' or 'quad' for linear/quadratic estimation of the
%                background.
%     'back'  :  indices of x to be used for background estimation.
%     'thresh':  The fractional value of the peak to use as threshold (default = 0.5.
%                Note that in this case, fwhm is really the  FW at thresh*MAX
%
% TODO: 1. list all output fields of peak_data
%       2. check checks for array size
%       3. expand to 2D arrays, or write 2D version...

peak_data = struct('wl', 1, 'wr', 1, 'xli', 1, 'xri', 1, 'xl', 1, 'xr',1, ...
    'fwhm', 1, 'com', 1, 'ch_com', 1, ...
    'counts', 1, 'area', 1, 'delta', 1, ...
    'bkgd',zeros(size(y)));

if length(x) == 1
    return
end

mode = 'mean';
bk = [];
bkgd = 0;
threshold = 0.5;
sampley = [];
nvarargin = nargin - 2;
for k = 1:2:nvarargin
    switch varargin{k}
        case 'mode'
            mode = varargin{k+1};
        case 'back'
            bk = varargin{k+1};
        case 'thresh'
            threshold = varargin{k+1};
        otherwise
            warndlg(sprintf('Unrecognized variable %s',varargin{k}));
    end
end

if strcmp(mode,'lin')
%    ftype = fittype({'a*x+b', '1'}, 'coeff', {'a', 'b'});   
    ftype = fittype('poly1');
    fopts = fitoptions(ftype);
elseif strcmp(mode,'quad')    
%    ftype = fittype('a*x^2+b*x+_c','ind', 'x', 'coeff', {'a', 'b', 'c'});
    ftype = fittype('poly2');
	fopts = fitoptions(ftype);
end


for k = 1:size(y, 2)
    if ~isempty(bk)
        xbk = x(bk); ybk = y(bk,k);
        switch mode
            case 'mean'
                bkgd_per_point = mean(ybk);
                bkgd = bkgd_per_point*ones(size(y(:,k)));
            case 'lin'
                %f=fit(xbk, ybk, 'm*x+b');
                f=fit(xbk, ybk, ftype);
                bkgd = f(x);
                %y = y-(f.m.*x-f.b);
            case 'quad'
                %f=fit(xbk, ybk, 'a*x*x+b*x + c');
                f=fit(xbk, ybk, ftype);
                bkgd = f(x);
        end
        y(:,k) = y(:,k) - bkgd;
    end

    [mx, mi] = max(y(:,k));
    hm = mx*threshold;

    walk = mi;

    wl = find(y(mi:-1:1,k)<hm, 1);
    if isempty(wl)
        wl = mi;  % Rather than 1 -- to make fwhm
        % the half width of an error function shape
        xli = mi;
        xl=x(wl);
    else
        wl = mi +1 - wl; % index of first element to left of peak < hm
        dx = x(wl+1)-x(wl);
        dy = y(wl+1,k)-y(wl,k);
        xl = dx/dy*(hm-y(wl,k)) + x(wl);
        xli = 1/dy*(hm-y(wl,k))+wl;  % xli, xri are the precise fractional index positions of the hm points.
    end
    wr = find(y(mi:end,k)<hm, 1);
    if isempty(wr)
        %wr = length(y);
        wr = mi;
        xri = mi;
        xr=x(wr);
    else
        wr = mi - 1 + wr;  % index of first element to right of peak < hm
        dx = x(wr)-x(wr-1);
        dy = y(wr,k)-y(wr-1,k);
        xr = dx/dy*(hm-y(wr-1,k)) + x(wr-1);
        xri = 1/dy*(hm-y(wr-1,k)) + wr-1;
    end

    peak_data.wl(k) = wl;
    peak_data.xl(k) = xl;
    peak_data.xli(k) = xli;
    peak_data.wr(k) = wr;
    peak_data.xr(k) = xr;
    peak_data.xri(k) = xri;
    peak_data.fwhm(k) = abs(xr-xl);
    if sum(y(wl:wr,k))==0
        peak_data.com(k) = mean(x(wl:wr));
        peak_data.ch_com(k) = mean([wl:wr]);
    else
        peak_data.com(k) = sum(x(wl:wr).*y(wl:wr,k))/sum(y(wl:wr,k));
        peak_data.ch_com(k) = sum([wl:wr]'  .*y(wl:wr,k))/sum(y(wl:wr,k));
    end
    peak_data.counts(k) = sum(y(:,k));
    peak_data.area(k) = abs(x(2)-x(1))*peak_data.counts(k);
    peak_data.delta(k) = sqrt(sum(y(:,k)));
    peak_data.bkgd(:,k) = bkgd;
end

% An alternative way of getting the area is to use only the counts within
% the fwhm.  1.3141 is the ratio between the full area of a gaussian peak
% and the area within the fwhm.
% 
% peak_data.area = 1.3141*a;
% peak_data.area = 1.3141*abs((x(2)-x(1))*sum(y(wl:wr)-bkgd));
