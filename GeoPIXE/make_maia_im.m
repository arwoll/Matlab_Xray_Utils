function maia_im = make_maia_im(maia_sorted)
% function maia_im = make_maia_im(maia_sorted)
% given 384 values -- corresponding to intensities in each maia pixel in
% order from 1 to 384, return a 20 x 20 array that shows the distribution
% of those intensities on the detector
load maia_pixels.mat
maia_im = zeros(20,20);
maia_im(maia_det_location_1D) = maia_sorted;
