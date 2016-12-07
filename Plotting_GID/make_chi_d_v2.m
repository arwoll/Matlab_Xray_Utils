function [rect_d, rect_chi, rect_z] = make_chi_d_v2(fname, scans, Energy, i2norm)

% Rectilinear chi-d grid; make into an input parameter at some point...
rect_chi = 3:0.5:90;
rect_d = 2.5:0.02:7; 

delrange = [.4 10];

tic
for f = 1:length(scans)
    matfile = sprintf('%s_%03d.mat', fname, scans(f));
    [q_par, q_perp, z] = open_gid_v5(matfile, Energy, 'i2norm', i2norm, ...
	'delrange', delrange);
    chi = 90 - atand(q_perp./q_par); d = 2*pi./sqrt((q_perp.^2 + q_par.^2));
    if f == 1
        [rtz, norm] = curve_to_rect(d', chi', z', rect_d, rect_chi);
        rtz_tot = rtz; 
        norm_tot = norm;
    else
        [rtz, norm] = curve_to_rect(d', chi', z', rect_d, rect_chi);
        rtz_tot = rtz_tot + rtz; 
        norm_tot = norm_tot + norm;
    end
    
end
toc

norm_tot(rtz_tot == 0) = 1.0;
rect_z = rtz_tot'./norm_tot';

