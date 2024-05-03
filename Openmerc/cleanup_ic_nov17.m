function scandata_out = cleanup_ic_nov17(scandata, varargin)
% A very kludgy fix for Nov 2017 tomography data obtained at G3
% Take ion chamber data, already purged of MCS-induced zeros, and fiddle
% with it to reflect the DWELL time, rather than the actual ion chamber
% counts. 
scandata_out = scandata;
dwell = scandata.spec.data(3, :,:);
ic = squeeze(scandata.spec.data(5,:,:));
ic_zeros = ic == 0;
nzeros = sum(ic_zeros(:));
force_corr = 0;

nvarargin = nargin - 1;
for k = 1:2:nvarargin
    switch varargin{k}
        case 'force'
            force_corr = varargin{k+1};
        otherwise
            warndlg(sprintf('Unrecognized variable %s',varargin{k}));
    end
end
if nzeros == 0 && ~force_corr
    fprintf('Found no zeros in spec.data.column 5\ -- no action taken.\n');
    return
end

fprintf('Found %d zeros in spec.data column 5 -- locations in output.spec.ic_zeros\n', ...
    sum(ic_zeros(:)));
scandata_out.spec.ic_zeros = ic_zeros;
mean_ic = mean(mean(ic));
mean_dwell = mean(mean(dwell));
scandata_out.spec.data(5,:,:) = mean_ic/mean_dwell * dwell;