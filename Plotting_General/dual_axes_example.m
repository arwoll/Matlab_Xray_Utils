XMIN = 40; XMAX = 140;
load Jfbox10_4_026.mat
figure(2);
clf;
subplot(2,1,1)
imagesc(streak.t, streak.q, log(streak.im'+1), [7 9])
rax(XMIN, XMAX);
bigfonts
title 'Jfbox10\_4 -- Two 6-pulse bursts @ 50 Hz'

load Jfbox10_4_026_fit.mat
p1 = subplot(2,1,2);
axp = get(gca, 'Position');
cla('reset');
plot(sfit.t, sfit.X0, 'Linewidth', 1);axis([XMIN XMAX 0 0.12])
set(p1, 'XAxisLocation', 'bottom','YAxisLocation', 'left', 'Color', [1 1 1],  'Box', 'off');
xlabel 'Time (sec)'
ylabel 'Q_{||} (inv. Ang.)'
bigfonts
p2 = axes('Position', axp);
plot(sfit.t, sfit.FW./(sfit.X0+.000001), 'r-','Linewidth', 1); axis([XMIN XMAX 1 1.5])
set(p2, 'XTick',[], 'XTickLabel', [], 'YAxisLocation', 'right', 'Color', 'none', 'Box', 'off')
ylabel 'Diffuse Peak FWHM / Q_{||}'
bigfonts