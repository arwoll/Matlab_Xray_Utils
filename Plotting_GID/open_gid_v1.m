function [q_par q_perp z] = open_gid_v1(matfile, E, varargin)
% function make_gidplot_v1(matfile, E, varargin) 
%   if present, varargin must be a 2-value vector with intensity ranges to
%   user for the plot

% Newest version of openmca in gidview as of Dec 2010 incorporates Delta
% value into Ecal...

calc_del_offset = 1;
i2norm = [];

nvarargin = nargin - 2;
for k = 1:2:nvarargin
    switch varargin{k}
        case 'calc_del_offset'
            calc_del_offset = varargin{k+1};
        case 'i2norm'
            i2norm = varargin{k+1};
        otherwise
            warndlg(sprintf('Unrecognized variable %s',varargin{k}));
    end
end

load(matfile)
getq = @(nu) 4*pi*E/12.4 * sind(nu/2);

specd = scandata.spec;

nu = double(specd.var1);
dcal = scandata.ecal;
ch = scandata.channels;

if calc_del_offset
    del_offset = scandata.spec.motor_positions(...
        strcmp(scandata.spec.motor_names, 'Delta'));
else
    del_offset = 0;
end
    
if dcal(3) == -1e-6
    dcal(3) = -7.5e-7;
end
del = del_offset + dcal(1) + ch*dcal(2) + dcal(3)*ch.^2;



q_par = getq(nu);
q_perp = getq(del);
z = double(scandata.mcadata);

%% clean up bad pixels
row_sums = sum(z, 2);
bad = find(row_sums == 0);
for k = 1:length(bad)
   z(bad(k), :) = 0.5 * ( z(bad(k)-1, :) + z(bad(k)+1, :));
end


normcts = double(specd.data(strcmp(specd.headers, 'I2'), :));
if isempty(i2norm)
    i2norm = mean(normcts);
end
norm_mat = i2norm./ repmat(normcts, size(z,1), 1);

z = z.* norm_mat;

