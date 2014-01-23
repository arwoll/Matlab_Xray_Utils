function [q_par q_perp q_par2 q_perp2 z] = open_gid_v2(matfile, E)
% function make_gidplot_v2(matfile, E, varargin) 
%   This version serves to compare true Q calculations with the estimates
%   used in v. 1. 
%   if present, varargin must be a 2-value vector with intensity ranges to
%   user for the plot
%  Q_par = k*sqrt(cos^2(alpha)...

load(matfile)
k = 2*pi*E/12.4;

getq = @(nu) 4*pi*E/12.4 * sind(nu/2);

scan_dims=size(scandata.mcadata);

specd = scandata.spec;
alpha = specd.motor_positions(strcmpi(specd.motor_names, 'eta'));

nu = repmat(double(specd.var1)', scan_dims(1), 1) ;
dcal = scandata.ecal;
ch = scandata.channels;

del_offset = scandata.spec.motor_positions(...
    strcmp(scandata.spec.motor_names, 'Delta'));

if dcal(3) == -1e-6
    dcal(3) = -7.5e-7;
end
del = del_offset + dcal(1) + ch*dcal(2) + dcal(3)*ch.^2;

beta = repmat(del - alpha, 1, scan_dims(2));

cosnu = cosd(nu);
cosb = cosd(beta);
cosa = cosd(alpha);
sina = sind(alpha);

q_par = k*sqrt(cosa^2 + cosb.^2 - 2*cosa*cosb.*cosnu);
q_perp = k*(sina + sind(beta));

q_par2 = getq(nu);
q_perp2 = getq(beta+alpha);



z = double(scandata.mcadata);

%% clean up bad pixels
row_sums = sum(z, 2);
bad = find(row_sums == 0);
for k = 1:length(bad)
   z(bad(k), :) = 0.5 * ( z(bad(k)-1, :) + z(bad(k)+1, :));
end


normcts = double(specd.data(strcmp(specd.headers, 'I2'), :));
avg_norm = mean(normcts);
norm_mat = avg_norm ./ repmat(normcts, size(z,1), 1);

z = z.* norm_mat;

