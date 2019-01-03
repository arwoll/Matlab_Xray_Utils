function peak_data = find_peaks(x,y, varargin)
% peak_data = find_peaks(x,y, varargin)
% Returns information about multiple peaks in x vs y. 
%
% This is a variation on find_peak() which finds peak information in
% possibly numerous columns of y. 
%
% Here, we look for numerous peaks in a single (x,y) pair and return
% information about each of those peaks each of which, in turn, would be suitable
% to send to the routine gauss_fit 
%
% input arguments:
%
%    'Npeaks': perform a search on the npeaks highest peaks. Default 2.
%    'startx': a vector of starting X values from which to search for
%    peaks. The value of y at startx should be close to a local maximum.
%
% ToDo: 
%       - Generalize original find_peaks to take 2D matrix x as well as 2D
%       matrix y
%       - test for function and efficiencity wrt how we are obtaining
%       peak_data
% 

peak_data = [];
pd = struct('xi', [], 'x', [], 'y', []);

if length(x) == 1
    return
end

mode = 'mean';
bk = [];
bkgd = 0;
threshold = 0.5;
sampley = [];
xrange = [min(x) max(x)];
startx = [];
Npeaks = 2;
MinPeakProminence = 100;
nvarargin = nargin - 2;
for k = 1:2:nvarargin
    switch varargin{k}
        case 'mode'
            mode = varargin{k+1};
        case 'back'
            bk = column(varargin{k+1});
        case 'thresh'
            threshold = varargin{k+1};
        case 'xmin'
            xrange(1) = varargin{k+1};
        case 'xmax'
            xrange(2) = varargin{k+1};
        case 'Npeaks'
            Npeaks = varargin{k+1};
        case 'MinPeakProminence'
            MinPeakProminence = varargin{k+1};
        case 'startx'
            startx = varargin{k+1};
        otherwise
            warndlg(sprintf('Unrecognized variable %s',varargin{k}));
    end
end

% In this case we should probably actually create and annotate the plot...
if isempty(startx)
    [peaky, startx] = findpeaks(y, x, 'Npeaks', Npeaks, ...
        'MinPeakProminence', MinPeakProminence, 'SortStr', 'descend');
end

Npeaks = length(startx);
for k = 1:length(startx)
    % find index
    [sn, si] = min(abs(x-startx(k)));
    yd = diff(y);
    if yd(si-1) > 0 && yd(si) < 0
        % then we are already close to or on peak.
        mi = si; 
    elseif yd(si-1) < 0  && yd(si) < 0  % si is to the right of the peak
        [mx, mi] = find(yd(si-1:-1:1)>0, 1);
        mi = si - (mi-1);
    elseif yd(si-1) > 0  && yd(si) > 0  % si is to the left of the peak
        [mx, mi] = find(yd(si:end) < 0, 1);
        mi = si + (mi-1);       
    else 
        % we're in a minimum??? Come on! poor startx; complain and abort
        fprintf('Oops: start position %f is at a minimum. Must be close to a peak\n', startx(k));
        return
    end
    mx = y(mi);
    % er and el (extent_right, extent_left) are the indices where the
    % slope changes outside of the peak range.
    % OK: this algorithm is not good: totally intollerant of noise. We
    % should start the search only after the half-max.
    er = mi + find(yd(mi:end) > 0, 1);
    el = mi - find(yd(mi-1:-1:1) < 0, 1);
    pd(k).xi = el:er;
    pd(k).x = x(el:er);
    pd(k).y = y(el:er);
end

x_all = x; y_all = y;

for k = 1:Npeaks
    x = pd(k).x;
    y = pd(k).y;
    i_offset = pd(k).xi(1);
    peak_data(k) = find_peak(peak_data(k).x, peak_data(k).y, 'back', [1 numel(x)]);
    peak_data(k).x = x;
    peak_data(k).y = y;
    peak_data(k).xi = pd(k).xi;
    peak_data(k).wl = peak_data(k).wl + i_offset-1;
    peak_data(k).wr = peak_data(k).wr + i_offset-1;
    peak_data(k).xli = peak_data(k).xli + i_offset-1;
    peak_data(k).xri = peak_data(k).xri + i_offset-1;
    peak_data(k).ch_com = peak_data(k).ch_com + i_offset-1;
end

peak_data = rmfield(peak_data, 'bkgd_fit'); 

