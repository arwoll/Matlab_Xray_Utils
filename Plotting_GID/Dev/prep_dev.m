vaddpath([AW_MATLAB_BASE 'Matlab_Xray_Utils/Plotting_GID/Dev:'])

%%
fname = 'G2.2.1'; scans = [28,29,30]; E = 11.21; i2norm = 1.5e5;
[qpar, qperp, z] = make_recipmap_v5(fname, scans, E, i2norm);

%%

cra = [12 300];
imagesc(qpar, qperp, log(z+1), log(cra));
axis equal tight xy

title_str = sprintf('%s_scans%s', fname, num2str(scans, '_%d'));
title(strrep(title_str, '_', '\_'));
xlabel(['Q_{||} [' char(197) '^{-1}]'])
ylabel(['Q_{\perp} [' char(197) '^{-1}]'])
