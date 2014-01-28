%% A script to generate reciprocal-space plots from Fall 2012 G2 data
E = 10.04;  %keV
i2norm = 1e5; 
figs =    [  41     43     45     47     49      51    53     55      57       59];
indices = {'331', '531', '622', '440', '22-2', '400', '511', '33-3', '840', '66-2'}; 

%% Make plots
for f = 1:3
    matfile = sprintf('Test_data/YSZ0828_20131209_%03d.mat', figs(f));
    [q_par, q_perp, z] = make_recipmap_v3(matfile,  E, 'fig', figs(f),'i2norm', 1e5, ...
        'title_append', indices{f});
end

%% Determine appropriate bounds for the new, rectilinear q-space grid
min_qpar = 1e10;
max_qpar = 0;
min_qperp = 1e10;
max_qperp = 0;
max_qpar_size = 0;
max_qperp_size = 0;
for f = 1:length(figs) %6
    matfile = sprintf('Test_data/YSZ0828_20131209_%03d.mat', figs(f));
    [q_par, q_perp, z] = open_gid_v4(matfile, E, 'i2norm', i2norm);
    min_qpar = min(min_qpar, min(q_par(:)));
    max_qpar = max(max_qpar, max(q_par(:)));
    min_qperp = min(min_qperp, min(q_perp(:)));
    max_qperp = max(max_qperp, max(q_perp(:)));
    max_qpar_size = max(max_qpar_size, max(max(diff(q_par, 1,2))));
    max_qperp_size = max(max_qperp_size, max(max(abs(diff(q_perp, 1,1)))));
end

rect_qpar = min_qpar - max_qpar_size/2.0 : max_qpar_size : max_qpar + max_qpar_size/2.0 ; 
rect_qperp = min_qperp -max_qperp_size/2.0: max_qperp_size : max_qperp + max_qperp_size/2.0;

%z = zeros(length(rect_qpar), length(rect_qperp));
%%
[rtz, norm] = curve_to_rect(q_par, q_perp, z, rect_qpar, rect_qperp);
imagesc(rect_qpar, rect_qperp, log(rtz'./norm'+1)); axis xy
%%
%figs = [47];
tic
for f = 1:length(figs) %1:length(figs)
    matfile = sprintf('YSZ0828_20131209_%03d.mat', figs(f));
    [q_par, q_perp, z] = open_gid_v4(matfile, E, 'i2norm', i2norm);
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
%%
%load Test_data/combined_recipmap1.mat

norm_tot(rtz_tot == 0) = 1.0;
imagesc(rect_qpar, rect_qperp, log(rtz_tot'./norm_tot'+1)); axis xy
%save combined_recipmap1.mat rect_qpar rect_qperp rtz_tot norm_tot figs

%%
title 'YSZ0828\_20131209 : All Scans'
xlabel(['Q_{||} [' char(197) '^{-1}]'])
ylabel(['Q_{\perp} [' char(197) '^{-1}]'])
