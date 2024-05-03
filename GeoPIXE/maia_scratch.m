% The following enables the function make_maia_im, as in:
% >> scan20_im = make_maia_im(scan20_sum, ordered_index);
% >> imagesc(scan20_im)
% 
% where scan20_sum is a list of maia pixel intensities in numeric order,
% from 0 to 383, and scan20_im is a 20x20 array showing how those
% intensities appear distributed on the detector.

maia_det_array = zeros(20,20);
maia_det_location_1D = zeros(384,1);
for k = 1:384
   detN = str2double(det_struct(k).Data);
   col = str2double(det_struct(k).Column);
   row = str2double(det_struct(k).Row);
   ordered_detN = col*20+row;
   maia_det_array(row+1, col+1) = detN;
   maia_det_location_1D(detN+1) = ordered_detN+1;
end

%maia_det_location_1D(N) = the single-index position of detector N in the 20x20
%matrix, maia_det_array. In other words:
%maia_det_array(maia_det_location_1D(N+1))=N;
%
% Also, this can be used to plot the intensity distribution on the detector
% by the operation (in make_maia_im.m):
%maia_im = zeros(20,20);
%maia_im(maia_det_location_1D) = intensity_sorted;
% since this is equivalent to:
% for k=1:384; maia_im(maia_det_location_1D(k)) = intensity_sorted(k); end

