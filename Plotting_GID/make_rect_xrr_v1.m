function [rect_tth, rect_omega, rect_z, varargout] = make_rect_xrr_v1(fname, scans, delrange, i2norm)

% Rectilinear chi-d grid; make into an input parameter at some point...

[omega, tth, z, specd] = open_xrr_v1(fname, 'scann', scans, 'delrange', delrange, 'i2norm', i2norm);
delta_tth = mean(diff(tth(1,:)));
delta_omega = delta_tth/2;
%delta_omega = abs(mean(diff(omega(:,1))));
rect_omega = min(omega(:,1)):delta_omega:max(omega(:,1));

% goal, here, is to find the region near the center
[mntth, imin] = min(abs(omega(:, 1)));
rect_tth = tth(imin, 1):delta_tth:tth(imin, end);

[rtz, norm] = curve_to_rect(tth', omega', z', rect_tth, rect_omega);
rtz_tot = rtz;
norm_tot = norm;

norm_tot(rtz_tot == 0) = 1.0;
rect_z = rtz_tot'./norm_tot';

if nargout == 4
  specd.mcadata = rect_z;
  specd.channels = rect_omega;
  specd.ecal = [0 1 0];
  specd.scanline = [specd.scanline 'xformed'];
  specd.var1 = column(rect_tth);
  scandata.spec = specd;
  scandata.mcadata = rect_z;
  scandata.dead.key = 'no_dtcorr';
  scandata.depth = column(rect_tth);
  scandata.channels = column(specd.channels);
  scandata.mcafile = 'Unknown';
  scandata.ecal = specd.ecal;
  scandata.energy = column(rect_omega);
  scandata.specfile = 'Unknown';
  scandata.dtcorr = 1;
  scandata.dtdel = 1;
  scandata.mcaformat = 'spec';
  varargout{1} = scandata;
end