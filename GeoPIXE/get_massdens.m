function y = get_massdens(x_trans, sigma)
%function y = get_massdens(x_trans, rho)
% given the transmitted x-ray intensity of a region, prompt the user to:
%    1) draw areas for use as background
%    2) draw the area of interest
%
% then subsequently uses the mean difference in intensity in the ROI vs.
% the background, in addition to sigma, the absorption cross section, to
% compute the area density in g/cm2
% app = area per pixel -- defined here as 400 (um2) / 1e8 (um2/cm2)

app = 400/1e8;

figure(1)
meanval = mean(x_trans(:));
range = std(x_trans(:));
h_f1 = imagesc(x_trans, [meanval-range, meanval+range]); 
axis xy

fprintf('Draw first background region (freehand)\n');
h_b1 = imfreehand(gca);
bk_m1 = createMask(h_b1, h_f1);

fprintf('Draw first background region (freehand)\n');
h_b2 = imfreehand(gca);
bk_m2 = createMask(h_b2, h_f1);

bk_mask = bk_m1 | bk_m2;

% sanity check -- draw total mask region in a different window
%figure(2)
%imagesc(bkrd_m); axis xy

trans_bk = mean(x_trans(bk_mask));

fprintf('Draw ROI (impoly)\n');
h_roi = impoly(gca);
roi_mask = createMask(h_roi, h_f1);

trans_roi = mean(x_trans(roi_mask));
roi_area = sum(sum(roi_mask))*app;

ratio = trans_bk/trans_roi;
y = log(ratio)/sigma;

fprintf('trans_bk = %.1f, trans_roi = %.1f\n', trans_bk, trans_roi);
fprintf('roi_area = %.3f cm2\n', roi_area);
fprintf('Mean areal density in ROI = %.4f g/cm2\n', y)
fprintf('Giving a total weight of %.4f g\n', y*roi_area)

figure(2)
imagesc(bk_mask | roi_mask); axis xy



