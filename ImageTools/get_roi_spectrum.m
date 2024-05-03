function y = get_roi_spectrum(Ispectra)
% function y = get_roi_spectrum(Ispectra) 
%   returns the average *spectrum* y over a mask region defined by the user
%   on the current image. The 3D matrix input argument Ispectra must have
%   the form Ispectra(n, y, x) where
%       n_c : spectrum channel (e.g. 1:2048 for a typical SDD
%       n_y : the row index / y position
%       n_x : the column index / x position
%
%  The convention above is such that if Ispectra is associated with vectors 
%  x and y, then imagesc(x, y, Ispectra(1, :,:)) will have the expected
%  orientation
% 
% ToDo : Add varargin options to:
%     * dictate the kind of ROI (rect, poly)
%     * specifiy the axes handle to use
% 
nchan = size(Ispectra, 1);

%h = imrect(h_implot);
h = impoly(h_implot);
bm = createMask(h);

nspectra = sum(bm(:));
% select spectra from within region only using this mask
bm_all = permute(repmat(bm, 1,1, nchan), [3 1 2]);
Imap_roi = Ispectra(bm_all);
% This appears to work - but also flattens to a vector and so must be
% reshaped back to nchan vs nspectra in order to perform a sum

Imap_roi = reshape(Imap_roi, nchan, nspectra);
y = mean(Imap_roi, 2);
