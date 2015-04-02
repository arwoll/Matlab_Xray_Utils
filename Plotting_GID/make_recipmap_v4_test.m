%%
fname = 'Si_16'; scans = 22:25; E = 11.27; i2norm = 5e4;
[qpar, qperp, z] = make_recipmap_v4(['Test_data/' fname]', scans, E, i2norm);

%%

cra = [12 300];
imagesc(qpar, qperp, log(z+1), log(cra));
axis equal tight xy

title_str = sprintf('%s_scans%s', fname, num2str(scans, '_%d'));
title(strrep(title_str, '_', '\_'));
xlabel(['Q_{||} [' char(197) '^{-1}]'])
ylabel(['Q_{\perp} [' char(197) '^{-1}]'])

%%
export_png(get(gcf, 'Number'), title_str)