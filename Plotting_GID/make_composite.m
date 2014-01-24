function make_composite(fname, scans, Energy, i2norm)
% function make_composite(spec_fname, scans, Energy, i2norm_cts)
% Attenuation matching between scan 3 (att=1) and scans 4 & 5 (att=0):
% figure(2);plot(q_perp1, z1(:,51)*4, q_perp2, z2(:,1))

for k = 1:length(scans)
    fprintf('Opening %s scan %d\n', fname, scans(k));
    [s(k).q_par s(k).q_perp s(k).z] = open_gid_v1(sprintf('%s_%03d.mat', fname, ...
        scans(k)), Energy, 'i2norm', i2norm);
end


%p3_indices = 1:610; % This is used to favor the high-angle region of the low-Delta scans
cra = [2 3000];
figure(1); clf
imagesc(s(1).q_par, s(1).q_perp,log(s(1).z+1), log(cra))
hold on
imagesc(s(2).q_par, s(2).q_perp,log(s(2).z+1), log(cra))
imagesc(s(3).q_par, s(3).q_perp,log(s(3).z+1), log(cra))
%imagesc(s(4).q_par, s(4).q_perp,log(s(4).z+1), log(cra))
%imagesc(s(3).q_par, s(3).q_perp(p3_indices),log(s(3).z(p3_indices,:)+1), log(cra))




axis xy

axis equal tight
%axis([-0.35 3 -0.07 3])
bigfonts
xlabel(['Q_{||} [' char(197) '^{-1}]'])
ylabel(['Q_{\perp} [' char(197) '^{-1}]'])
%title_str = sprintf('%s : Scans %d, %d, %d and %d', ...
%    fname, scans(1), scans(2), scans(3), scans(4));

title_str = sprintf('%s : Scans %d, %d, and %d', ...
    fname, scans(1), scans(2), scans(3));

title(strrep(title_str, '_', '\_'));

