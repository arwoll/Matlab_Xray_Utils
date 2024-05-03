function peak_data = find_peak(x,y, varargin)
% peak_data = find_peak(x,y, varargin)
% Returns information about the peak in y:
%    wl, wr: nearest indices to peak that include the half-max of the peak
%    xl, xr: the interpolated left and right x values of the half-max
%    xli, xri: like xl & xr but the interpolated index positions
%    el, er: the indices just beyond the first left and right minima
%            outside the half-max positions
%    fwhm: peak FWHM
%    com: peak center of mass, calculated only using the points within the
%         half max.
%    ch_com: like com but given as the index (not x value)
%    counts: counts summed from el:er. 
%    area: counts mutliplied by the x increment.
%    delta: sqrt(counts)
%    bkgd: the background (an array) subtracted from y
%    bkgd_fit: if a linear or quad fit, a handle to the fit.
%
% y values are assumed to be column vectors, i.e.  Multiple y values can be placed in
% adjacent columns of y.  x, at present, is only allowed to be a single
% vector
%
% varargin can either be empty, in which case no background subtraction is
% performed, or can be one or more pairs of parameter / value pairs:
%     'mode'  :  'mean', 'lin' or 'quad' for linear/quadratic estimation of the
%                background.
%     'back'  :  indices of x to be used for background estimation.
%     'thresh':  The fractional value of the peak to use as threshold (default = 0.5.
%                Note that in this case, fwhm is really the  FW at thresh*MAX
%     'startx':  The starting value of x from which to find a local
%          maximum, instead of using the maximum of the entire column
%          y(:,k). Useful for arrays with multiple peaks. 
%
% TODO: 1. (DONE) list all output fields of peak_data
%       2. check checks for array size
%       3. expand to 2D arrays, or write 2D version...

peak_data = struct('wl', 1, 'wr', 1, 'el', 1, 'er', 1, 'xli', 1, ...
    'xri', 1, 'xl', 1, 'xr',1, 'fwhm', 1, 'com', 1, 'ch_com', 1, ...
    'counts', 1, 'area', 1, 'delta', 1, ...
    'bkgd',zeros(size(y)), 'bkgd_fit', []);

if length(x) == 1
    return
end

mode = 'mean';
bk = [];
bkpts = 2;
bkgd = 0;
threshold = 0.5;
sampley = [];
startx = [];
nvarargin = nargin - 2;
for k = 1:2:nvarargin
    switch varargin{k}
        case 'mode'
            mode = varargin{k+1};
        case 'back'
            bk = column(varargin{k+1});
        case 'thresh'
            threshold = varargin{k+1};
        case 'startx'
            startx = varargin{k+1};
        case 'bkpts'
            bkpts = varargin{k+1};
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

loop_ycol = 1;
ncolumns = size(y, 2);
if numel(startx)>1
    nloops = numel(startx);
    loop_ycol = 0;
else
    nloops = ncolumns;
end

if ~strcmp(mode, 'mean')
    bkgd_fit = cell(ncolumns, 1);
end


for k = 1:nloops
    if k == 1 || loop_ycol
        thisy = y(:,k);
        if (~isempty(bk) || bkpts > 0) && isempty(startx)
            if bkpts > 0
               bk = [1:bkpts numel(x)-bkpts+1:numel(x)];
            end
            xbk = column(x(bk)); ybk = double(thisy(bk));
            switch mode
                case 'mean'
                    bkgd_per_point = mean(ybk);
                    bkgd = bkgd_per_point*ones(size(thisy));
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
            thisy = thisy - bkgd;
        end
        yd = diff(smooth(thisy, 3));
    end

    if isempty(startx)
        [mx, mi] = max(thisy);
    else
        if loop_ycol
            sx = startx;
        else
            sx = startx(k);
        end
        [sn, si] = min(abs(x-sx));
        if yd(si-1) > 0 && yd(si) < 0
            % then we are already close to or on peak.
            mi = si;
        elseif yd(si-1) < 0  && yd(si) < 0  % si is to the right of the peak
            mi = find(yd(si-1:-1:1)>0, 1);
            mi = si - (mi-1);
        elseif yd(si-1) > 0  && yd(si) > 0  % si is to the left of the peak
            mi = find(yd(si:end) < 0, 1);
            mi = si + (mi-1);
        else
            % we're in a minimum??? Come on! poor startx; complain and abort
            fprintf('Warning: start position %f is at a local minimum. Assume local min on a max...\n', startx(k));
            mi = si;
        end
        mx = y(mi);
    end
    hm = mx*threshold;

    wl = find(thisy(mi:-1:1)<hm, 1);
    if isempty(wl)
        wl = mi;  % Rather than 1 -- to make fwhm
                  % the half width of an error function shape
        xli = mi;
        xl = x(wl);
        el = wl;
    else
        wl = mi +1 - wl; % index of first element to left of peak < hm
        dx = x(wl+1)-x(wl);
        dy = thisy(wl+1)-thisy(wl);
        xl = dx/dy*(hm-thisy(wl)) + x(wl);
        xli = 1/dy*(hm-thisy(wl)) + wl;  % xli, xri are the precise fractional index positions of the hm points.
        el = find(yd(wl:-1:1)<0, 1);
        if isempty(el)
            el = 1;
        else
            el = wl - (el-1);
        end
    end
    wr = find(thisy(mi:end)<hm, 1);
    if isempty(wr)
        %wr = length(y);
        wr = mi;
        xri= mi;
        xr = x(wr);
        er = wr;
    else
        wr = mi - 1 + wr;  % index of first element to right of peak < hm
        dx = x(wr)-x(wr-1);
        dy = thisy(wr)-thisy(wr-1);
        xr = dx/dy*(hm-thisy(wr-1)) + x(wr-1);
        xri = 1/dy*(hm-thisy(wr-1)) + wr-1;
        er = find(yd(wr:end)>0, 1);
        if isempty(er)
            er = numel(thisy);
        else
            er = wr + (er-1);
        end
    end

    if ~isempty(startx)
        subi = el:er;
        xsub = x(subi);
        ysub = y(subi);
        pd = find_peak_dev(xsub, ysub, 'bkpts', bkpts, 'mode', mode);
        wl = pd.wl + el - 1;
        wr = pd.wr + el - 1;
        xl = pd.xl;
        xr = pd.xr;
        xli = pd.xli + el - 1;
        xri = pd.xri + el - 1;
        bkgd = zeros(numel(x), 1);
        bkgd(subi) = pd.bkgd;
        thisy(subi) = thisy(subi) - bkgd(subi);
    end
    peak_data.wl(k) = wl;
    peak_data.xl(k) = xl;
    peak_data.xli(k) = xli;
    peak_data.wr(k) = wr;
    peak_data.xr(k) = xr;
    peak_data.xri(k) = xri;
    peak_data.el(k) = el;
    peak_data.er(k) = er;
    peak_data.fwhm(k) = abs(xr-xl);
    if sum(thisy(wl:wr))==0
        peak_data.com(k) = mean(x(wl:wr));
        peak_data.ch_com(k) = mean(wl:wr);
    else
        peak_data.com(k) = sum(column(x(wl:wr)).*thisy(wl:wr))/sum(thisy(wl:wr));
        peak_data.ch_com(k) = sum((wl:wr)' .*thisy(wl:wr))/sum(thisy(wl:wr));
    end
    peak_data.counts(k) = sum(thisy(el:er));
    peak_data.area(k) = abs(x(2)-x(1))*peak_data.counts(k);
    peak_data.delta(k) = sqrt(peak_data.counts(k));
    peak_data.bkgd(:,k) = bkgd;
    if ~strcmp(mode, 'mean') && isempty(startx)
        bkgd_fit{k} = f;
    end
end

if strcmp(mode, 'mean') || ~isempty(startx)
   peak_data = rmfield(peak_data, 'bkgd_fit'); 
else
   peak_data.bkgd_fit = bkgd_fit;
end

% An alternative way of getting the area is to use only the counts within
% the fwhm.  1.3141 is the ratio between the full area of a gaussian peak
% and the area within the fwhm.
% 
% peak_data.area = 1.3141*a;
% peak_data.area = 1.3141*abs((x(2)-x(1))*sum(y(wl:wr)-bkgd));
