function [omega, tth, z, varargout] = open_xrr_v1(matfile, varargin)
% function make_gidplot_v1(matfile, E, varargin) 
%   if present, varargin must be a 2-value vector with intensity ranges to
%   user for the plot

i2norm = [];
scann=0;

delrange = [-360 360];

nvarargin = nargin - 2;
for k = 1:2:nvarargin
    switch varargin{k}
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

if nargout == 4
    varargout{1} = specd;
end

% Here we should check that we recognize the scan type -- e.g. tth scan
dcal = specd.ecal;
if ~strcmp(specd.mot1, 'tth')
   fprintf('Unrecognized scan type -- abort\n')
   return
end

% impose range on del here -- use it to choose only some channels
% so that del has a new length, and so that we define a new range of
% channels?
scan_dims=size(scandata.mcadata);
npts = scan_dims(2);

% In a th-2th scan with a linear detector in the scattering plane, tth is
% del calculated below *plus* the motor value of del, (equivalently, the
% macro motor called "tth"
ch = specd.channels;
del = dcal(1) + ch*dcal(2) + dcal(3)*ch.^2;
del_select = del > delrange(1) & del < delrange(2);
ch = ch(del_select);
nchan = length(ch);
del = repmat(del(del_select), 1, npts);

tth_vector = double(specd.var1);
del_offset = repmat(tth_vector', nchan, 1);
alpha = repmat(tth_vector'/2, nchan, 1);

tth = del + del_offset;
omega  = tth/2 - alpha;

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
if any(strcmp(specd.headers, 'att_norm'))
    fprintf('Normalizing by att_norm\n');
    normcts = double(specd.data(strcmp(specd.headers, 'att_norm'), :));
    i2vals = double(specd.data(strcmp(specd.headers, 'I2'), :));
    mean_i2 = mean(i2vals);
elseif (any(strcmp(specd.headers, 'att_scaler')) && any(strcmp(specd.headers, 'I2')))
    fprintf('Normalizing by att_scaler and I2\n');
    atts = double(specd.data(strcmp(specd.headers, 'att_scaler'), :));
    i2vals = double(specd.data(strcmp(specd.headers, 'I2'), :));
    mean_i2 = mean(i2vals);
    normcts = atts .* i2vals;
elseif any(strcmp(specd.headers, 'I2'))
    fprintf('Normalizing by I2 only\n');
    normcts = double(specd.data(strcmp(specd.headers, 'I2'), :));
    mean_i2 = mean(i2vals);
end
if isempty(i2norm)
    i2norm = mean_i2;
end
norm_mat = i2norm./ repmat(normcts, size(z,1), 1);

z = z.* norm_mat;

