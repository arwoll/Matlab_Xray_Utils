%%
scn = 30;
detc = 6;
s = openspec('monocap_aug7', scn);

figure(4)
x = s.data(1,:);
y = s.data(detc,:);
plot(x,y )
pd = find_peak(x',y');
xlabel(sprintf('%s, fwhm = %g',s.mot1, pd.fwhm))
ylabel(s.headers{detc})
title(sprintf('Scan %d', s.scann));
