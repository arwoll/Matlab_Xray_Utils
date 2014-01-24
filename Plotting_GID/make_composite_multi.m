function make_composite_multi(fname, scans, Energy, i2norm)
% function make_composite_multi(spec_fname, scans, Energy, i2norm_cts)
% Attenuation matching between scan 3 (att=1) and scans 4 & 5 (att=0):
% figure(2);plot(q_perp1, z1(:,51)*4, q_perp2, z2(:,1))
%
% ToDo: Generalize this to include a sensible title, to make the non-multi
% version obsolete
%  
%

figure(1)
clf;
cra = [2 5000];
for k = 1:length(scans)
    fprintf('Opening %s scan %d\n', fname, scans(k));
    [s(k).q_par s(k).q_perp s(k).z] = open_gid_v1(sprintf('%s_%03d.mat', fname, ...
        scans(k)), Energy, 'i2norm', i2norm);
    if k==1
        hold off
    end
    imagesc(s(k).q_par, s(k).q_perp,log(s(k).z+1), log(cra));
    hold on
end

axis xy equal tight

%axis([-0.35 3 -0.07 2.1])
bigfonts
xlabel(['Q_{||} [' char(197) '^{-1}]'])
ylabel(['Q_{\perp} [' char(197) '^{-1}]'])
%title_str = sprintf('%s : Scans %d, %d, and %d', fname, scans(1), scans(2), scans(3))
%title(strrep(title_str, '_', '\_'));

