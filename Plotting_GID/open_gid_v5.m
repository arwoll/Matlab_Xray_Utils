function [q_par, q_perp, z] = open_gid_v5(matfile, E, varargin)
% function make_gidplot_v1(matfile, E, varargin) 
%   if present, varargin must be a 2-value vector with intensity ranges to
%   user for the plot

% Newest version of openmca in gidview as of Dec 2010 incorporates Delta
% value into Ecal...

calc_del_offset = 1;
i2norm = [];
scann=0;

delrange = [-360 360];

nvarargin = nargin - 2;
for k = 1:2:nvarargin
    switch varargin{k}
        case 'calc_del_offset'
            calc_del_offset = varargin{k+1};
        case 'i2norm'
            i2norm = varargin{k+1};
        case 'scann'
            scann = varargin{k+1};
        case 'delrange'
            if length(varargin{k+1}) ~= 2
               warndlg('if present, delrange is an ordered, two-element array -- ignored');
            end
            delrange = sort(varargin{k+1});
        otherwise
            warndlg(sprintf('Unrecognized variable %s',varargin{k}));
    end
end

if strcmp(matfile(end-3:end), '.mat')
    load(matfile)
elseif (scann ~= 0)
    scandata = openspec(matfile, scann);
end
%getq = @(nu) 4*pi*E/12.4 * sind(nu/2);


if isfield(scandata, 'spec')
    specd = scandata.spec;
else
    specd = scandata;
end


dcal = specd.ecal;

if calc_del_offset
    del_offset = specd.motor_positions(...
        strcmp(specd.motor_names, 'Delta'));
else
    del_offset = 0;
end
    
if dcal(3) == -1e-6
    dcal(3) = -7.5e-7;
end

% impose range on del here -- use it to choose only some channels
% so that del has a new length, and so that we define a new range of
% channels?
scan_dims=size(scandata.mcadata);
npts = scan_dims(2);

ch = specd.channels;
del = dcal(1) + ch*dcal(2) + dcal(3)*ch.^2;
del_select = del > delrange(1) & del < delrange(2);
ch = ch(del_select);
nchan = length(ch);
del = del(del_select) + del_offset;

k = 2*pi*E/12.4;

nu = repmat(double(specd.var1)', nchan, 1);
alpha = specd.motor_positions(strcmpi(specd.motor_names, 'eta'));
beta = repmat(del - alpha, 1, npts);

cosnu = cosd(nu);
cosb = cosd(beta);
cosa = cosd(alpha);
sina = sind(alpha);

q_par = k*sqrt(cosa^2 + cosb.^2 - 2*cosa*cosb.*cosnu);
q_perp = k*(sina + sind(beta));

%q_par = getq(nu);
%q_perp = getq(del);

% delta sub-range must be used here
z = double(specd.mcadata(del_select, :, :));

%% clean up bad pixels
row_sums = sum(z, 2);
nrows = length(row_sums);
bad = find(row_sums == 0);
for k = 1:length(bad)
    if bad(k) == 0 
        z(bad(k), :) = z(bad(k)+1, :);
    elseif bad(k) == nrows
        z(bad(k), :) = z(bad(k)-1, :);
    else
        % fprintf('bad(%d) = %d\n', k, bad(k))
        z(bad(k), :) = 0.5 * ( z(bad(k)-1, :) + z(bad(k)+1, :));
    end
end

% normcts will be a 1 x NPTS (row) vector
normcts = double(specd.data(strcmp(specd.headers, 'I2'), :));
if isempty(i2norm)
    i2norm = mean(normcts);
end
norm_mat = i2norm./ repmat(normcts, size(z,1), 1);

z = z.* norm_mat;

