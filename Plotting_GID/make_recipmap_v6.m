function [rect_qpar, rect_qperp, rect_z] = make_recipmap_v6(fname, scans, Energy, i2norm,varargin)
% From v5_gomez, but allows fname to be a preformed matfile
% 
% Determine appropriate bounds for the new, rectilinear q-space grid
% version 5 implements a "delrange" (which should be an input parameter)
% to use only a subset of the delta data
min_qpar = 1e10;
max_qpar = 0;
min_qperp = 1e10;
max_qperp = 0;
max_qpar_size = 0;
max_qperp_size = 0;

% Provide an override for determining the grid spacing in parallel and
% perpendicular directions
nvarargin = nargin - 4;
delta_qpar = [];
delta_qperp = [];
for k = 1:2:nvarargin
    switch varargin{k}
        case 'delta_qpar'
            delta_qpar = varargin{k+1};
        case 'delta_qperp'
            delta_qperp = varargin{k+1};
        otherwise
            warndlg(sprintf('Unrecognized variable %s',varargin{k}));
    end
end

delrange = [.5 10];

if size(scans, 1)> 1 
    % In this case, the first row is the scan numbers, the 2nd is the scale
    % factors
    scale_factors = scans(2,:);
    scans = scans(1,:);
else
    scale_factors = ones(size(scans));
end



for f = 1:length(scans) %6
    matfile = sprintf('%s_%03d.mat', fname, scans(f));
    [q_par, q_perp, z] = open_gid_v5_gomez(matfile, Energy, 'i2norm', i2norm, ...
        'delrange', delrange);
    min_qpar = min(min_qpar, min(q_par(:)));
    max_qpar = max(max_qpar, max(q_par(:)));
    min_qperp = min(min_qperp, min(q_perp(:)));
    max_qperp = max(max_qperp, max(q_perp(:)));
    max_qpar_size = max(max_qpar_size, max(max(diff(q_par, 1,2))));
    max_qperp_size = max(max_qperp_size, max(max(abs(diff(q_perp, 1,1)))));
end

if ~isempty(delta_qperp)
    max_qperp_size = delta_qperp;
end
if ~isempty(delta_qpar)
    max_qpar_size = delta_qpar;
end

rect_qpar = min_qpar - max_qpar_size/2.0 : max_qpar_size : max_qpar + max_qpar_size/2.0 ; 
rect_qperp = min_qperp -max_qperp_size/2.0: max_qperp_size : max_qperp + max_qperp_size/2.0;

tic
for f = 1:length(scans)
    matfile = sprintf('%s_%03d.mat', fname, scans(f));
    [q_par, q_perp, z] = open_gid_v5_gomez(matfile, Energy, 'i2norm', i2norm,...
        'delrange', delrange);
    if f == 1
        [rtz, norm] = curve_to_rect(q_par', q_perp', z', rect_qpar, rect_qperp);
        rtz_tot = rtz*scale_factors(f); 
        norm_tot = norm;
    else
        [rtz, norm] = curve_to_rect(q_par', q_perp', z', rect_qpar, rect_qperp);
        rtz_tot = rtz_tot + rtz*scale_factors(f); 
        norm_tot = norm_tot + norm;
    end
    
end
toc

norm_tot(rtz_tot == 0) = 1.0;
rect_z = rtz_tot'./norm_tot';

