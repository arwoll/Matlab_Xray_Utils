function [rect_q, rect_chi, rect_z] = make_q_chi_v2(fname, scans, Energy, i2norm, varargin)
%
% Rectilinear chi-d grid; make into an input parameter at some point...
autoextent = 0;
if nargin > 4
    nvaragin = nargin-4;
    k = 1;
    switch varargin{k}
        case 'auto'
            autoextent = 1;
    end
end

rect_chi = 3:2:90;
rect_q = 0.1:0.02:1;
delrange = [.4 10.0];

if isstruct(fname)
   scans = 1; 
end

tic
for f = 1:length(scans)
    if ~isstruct(fname)
        matfile = sprintf('%s_%03d.mat', fname, scans(f));
    else
       matfile = fname; 
    end
    [q_par, q_perp, z] = open_gid_v5(matfile, Energy, 'i2norm', i2norm, ...
	'delrange', delrange);
    chi = 90 - atand(q_perp./q_par); 
    q = sqrt(q_perp.^2 + q_par.^2);
    if autoextent
        rect_chi = min(chi(:)):1:max(chi(:));
        rect_q = min(q(:)):.05:max(q(:));
    end
       
    if f == 1
        [rtz, norm] = curve_to_rect(q', chi', z', rect_q, rect_chi);
        rtz_tot = rtz; 
        norm_tot = norm;
    else
        [rtz, norm] = curve_to_rect(q', chi', z', rect_q, rect_chi);
        rtz_tot = rtz_tot + rtz; 
        norm_tot = norm_tot + norm;
    end
end
toc

norm_tot(rtz_tot == 0) = 1.0;
rect_z = rtz_tot'./norm_tot';
