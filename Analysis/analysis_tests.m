%% find_peak:
load Test_data/find_peak_test.mat
peak_data = find_peak(x, y, 'mode', mode, 'back', bkgd);
areas = peak_data.area;
delta = sqrt(areas);

showplots(x,y, peak_data.bkgd);
