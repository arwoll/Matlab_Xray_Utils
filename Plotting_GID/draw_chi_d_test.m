%%
fname = 'Si_16'; scans = 22:25; Energy = 11.27; i2norm = 5e4;
%[chi, d, z] = draw_chi_d(['Test_data/' fname]', scans, Energy, i2norm);

[d,chi, z] = make_chi_d_v1(['Test_data/' fname], scans, Energy, i2norm);

%%
%load Test_data/Si_16_chi_d_scans_22_23_24_25.mat
cra = [7 200];
clf;
imagesc(d, chi, log(z+1), log(cra));
axis tight xy

title_str = sprintf('%s_chi_d_scans%s', fname, num2str(scans, '_%d'));
title(strrep(title_str, '_', '\_'));
ylabel('chi [degrees]')
xlabel(['d ' char(197)])