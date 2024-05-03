function [rect_qpar, rect_qperp, rect_z] = make_recipmap_v5_vineetha(matfiles, Energy, i2norm)
% Determine appropriate bounds for the new, rectilinear q-space grid
% version 5 implements a "delrange" (which should be an input parameter)
% to use only a subset of the delta data
min_qpar = 1e10;
max_qpar = 0;
min_qperp = 1e10;
max_qperp = 0;
max_qpar_size = 0;
max_qperp_size = 0;

delrange = [.4 15];

if iscell(matfiles)
    scans = length(matfiles);
elseif ischar(matfiles)
    tmp = matfiles;
    matfiles = cell(1,1);
    matfiles{1} = tmp;
    scans = 1;
end

for f = 1:length(scans) %6
    [q_par, q_perp, z] = open_gid_v5(matfiles{f}, Energy, 'i2norm', i2norm, ...
        'delrange', delrange);
    min_qpar = min(min_qpar, min(q_par(:)));
    max_qpar = max(max_qpar, max(q_par(:)));
    min_qperp = min(min_qperp, min(q_perp(:)));
    max_qperp = max(max_qperp, max(q_perp(:)));
    max_qpar_size = max(max_qpar_size, max(max(diff(q_par, 1,2))));
    max_qperp_size = max(max_qperp_size, max(max(abs(diff(q_perp, 1,1)))));
end

rect_qpar = min_qpar - max_qpar_size/2.0 : max_qpar_size : max_qpar + max_qpar_size/2.0 ; 
rect_qperp = min_qperp -max_qperp_size/2.0: max_qperp_size : max_qperp + max_qperp_size/2.0;

tic
for f = 1:length(scans)
    [q_par, q_perp, z] = open_gid_v5(matfiles{f}, Energy, 'i2norm', i2norm,...
        'delrange', delrange);
    if f == 1
        [rtz, norm] = curve_to_rect(q_par', q_perp', z', rect_qpar, rect_qperp);
        rtz_tot = rtz; 
        norm_tot = norm;
    else
        [rtz, norm] = curve_to_rect(q_par', q_perp', z', rect_qpar, rect_qperp);
        rtz_tot = rtz_tot + rtz; 
        norm_tot = norm_tot + norm;
    end
    
end
toc

norm_tot(rtz_tot == 0) = 1.0;
rect_z = rtz_tot'./norm_tot';

