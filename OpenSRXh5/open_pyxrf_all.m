function  [scandata, errors] = open_pyxrf_all(mcafile, varargin)
%function scandata = open_pyxrf_all(fn)
%
% TODO : where fn is an h5 file containing fit results (from pyxrf) and E0 is the
% incident energy, returns a structure with standard 'scandata' format,
% e.g. which can be re-saved to an hdf5 format that is readable by GeoPIXE. 
%
errors.code = 0;
scandata = [];
specscan = [];

if nargin < 1 
    errors=add_error(errors,1,...
        'open_pyxrf_all takes at least one input -- the filename');
    return
elseif ~exist(mcafile, 'file')
    % Need to add an echo, especially if 2nd output arg is not called for
    emsg = sprintf('File %s not found', mcafile);
    if nargout > 1
        errors=add_error(errors,1, ...
            emsg);
    else
        fprintf([emsg '\n']);
    end
    return
end

nvarargin = nargin -1;
if mod(nvarargin, 2) ~= 0
    errordlg('Additional args to openxmap must come in variable/value pairs');
    return
end

ecal = [0 1];
mcaformat = 'pyxrf';
dead = struct('key','none');
force_save_mat = 0;
E0 = [];
startx = [];
make_rois = 0;
for k = 1:2:nvarargin
    switch varargin{k}
        case 'ecal'
            if isnumeric(varargin{k+1})
                ecal = varargin{k+1};
            end
        case 'force'
            force_save_mat = varargin{k+1};
        case 'E0'
            E0 = varargin{k+1};
        case 'make_rois'
            startx = varargin{k+1};
        otherwise
            warndlg(sprintf('Unrecognized variable %s',varargin{k}));
    end
end       

if ~isempty(startx)
    make_rois = 1;
end

[mcapath, mcaname, extn] = fileparts(mcafile);

switch mcaformat
    case 'pyxrf'
        if ~strcmp(extn, '.h5')
           fprintf('Error in open_pyxrf_all: file does not have h5 extension\n');
           return
        end
        matfile = [mcaname '.mat'];
        % Note that detsum is always there but evidently det1 is not there
        % if there is only one detector. (ARGHH)
        mcadata = h5read(mcafile,'/xrfmap/detsum/counts');
        MCA_channels = size(mcadata, 1);
        channels = (0:MCA_channels-1)';
    otherwise
        errors=add_error(errors,1,...
            sprintf('Uncrecognized mca file format %s', mcaformat));
        return
end
    
i0_name = deblank(h5read(mcafile, '/xrfmap/scalers/name'));
if length(i0_name) == 1
    i0_ind = 1;
elseif any(strcmp(i0_name, 'sclr_i0'))
    i0_ind = find(strcmp(i0_name, 'sclr_i0'));
elseif any(strcmp(i0_name, 'i0'))
    i0_ind = find(strcmp(i0_name, 'i0'));
else
   fprintf('Error -- neither i0 nor sclr_i0 found for normalization\n'); 
   return
end
i0_dat = squeeze(h5read(mcafile, '/xrfmap/scalers/val'));
% The following corrects for the fact that for 1D scans, the scalar data is
% saved in a single row. Need it in col form to match dims of ffit.
if length(i0_name)>1
    i0_dat = squeeze(i0_dat(i0_ind,:,:));
end
if size(i0_dat, 1) == 1
   i0_dat = i0_dat'; 
end
i0_norm = mean(i0_dat(:));

motor_names = deblank(h5read(mcafile, '/xrfmap/positions/name'));
motor_pos = h5read(mcafile, '/xrfmap/positions/pos');

if size(motor_pos, 1) == 1
    dims = 1;
    scan_axis = 1; 
elseif size(motor_pos, 2) == 1
    dims = 1;
    scan_axis = 2; 
else
    dims = 2;
end
if dims == 1
   mot1 = motor_names{scan_axis};
   var1 = squeeze(motor_pos(:,:,scan_axis));
else
    mot1 = motor_names{2};
    mot2 = motor_names{1};
    var1 = squeeze(motor_pos(:,:,2));
    var2 = squeeze(motor_pos(:,:,1));
    % The following takes care of a very unfortunate difference between fly
    % and non-fly scans...
    if var1(end)-var1(1) < 1e-6
        mot1 = motor_names{1};
        mot2 = motor_names{2};
        var1 = squeeze(motor_pos(:,:,1));
        var2 = squeeze(motor_pos(:,:,2));
    end
end

% The following hard codes the x's and y's and so may not be general

scandata.mcadata = single(mcadata);
scandata.mcaformat = mcaformat;
scandata.matfile = matfile;
scandata.dead = dead;
scandata.filename = mcaname;
scandata.scanline = mcaname;
scandata.dims = dims;
scandata.channels = channels;
scandata.path = fullfile(pwd, mcapath);


scandata.spec.data(1,:,:)  = single(i0_dat);
scandata.spec.scann = 1;
scandata.spec.npts = numel(i0_dat);
scandata.spec.dims = scandata.dims;
scandata.spec.scanline = '';
scandata.spec.columns = 1;
scandata.spec.headers = i0_name;
scandata.spec.ctrs = i0_name;
scandata.spec.complete = 1;
scandata.spec.var1 = single(var1);
scandata.spec.mot1 = mot1;
mcadata_size = size(mcadata);
scandata.spec.size = mcadata_size(2:end);

% if dims == 1
%scandata.spec.motor_names = motor_names;
if dims>1
    scandata.spec.var2 = single(var2);
    scandata.spec.mot2 = mot2;
end
scandata.motor_pos = motor_pos;
scandata.depth = scandata.spec.var1;
scandata.ecal = ecal;
scandata.energy = channel2energy(scandata.channels, ecal);
%scandata.i0_dat = i0_dat;
%scandata.i0_norm = i0_norm;
try 
    fnames = deblank(h5read(mcafile, '/xrfmap/detsum/xrf_fit_name'));
    ffit = h5read(mcafile, '/xrfmap/detsum/xrf_fit');
    nfit = length(fnames);
    scandata.fnames = fnames;
catch
    nfit = 0;
end
for k = 1:nfit
    scandata.pyfit(k).I = squeeze(ffit(:,:,k));
    scandata.pyfit(k).name = fnames{k};
end

%% Gather info about the lines taht were fit
if nfit > 0 && ~isempty(E0)
    scandata.E0 = E0;
    if exist('cs_fluor_total', 'file') == 0
        addpath( '/home/aw30/Matlab/Xraylib:')
        xraylib_setup
    end
    if exist('elamdb.mat', 'file') == 2
        load elamdb
    end
    roi =  scandata.pyfit;
    
    sym = fnames;
    group = sym;
    nA = sym;
    element_syms = fields(elamdb.n);
    for k = 1:length(fnames)
        foo = strsplit(fnames{k}, '_');
        roi(k).E = NaN;
        if ~any(strcmp(element_syms, foo{1}))
            fprintf('This fit line -- %s -- not an element\n', fnames{k});
            continue
        end
        roi(k).sym = foo{1};
        roi(k).group = foo{2};
        roi(k).nA = elamdb.n.(roi(k).sym);
        [sigma_f, extn] = cs_fluor_total(roi(k).nA, roi(k).group, E0);
        roi(k).E = extn;
        roi(k).sigma_f = sigma_f;
    end
    
    [vals, indices] = sort([roi.E]);
    roi = roi(indices);    
    scandata.pyfit = roi;
    scandata.fnames = scandata.fnames(indices);
end

if ~exist(matfile, 'file') || force_save_mat
    save(matfile, 'scandata', '-v7.3');
end

if make_rois
    E_peaks = startx;
    npeaks = numel(E_peaks);
    E = scandata.energy;
    mcadims = size(scandata.mcadata);
    if scandata.dims == 1
        roidims = [mcadims(2) 1];
    else
        roidims = mcadims(2:end);
    end
    mca2D = reshape(scandata.mcadata, mcadims(1), prod(mcadims(2:end)));
    Isum = sum(mca2D, 2);
    multi_peaks = find_peak(E, Isum, 'startx', E_peaks);

    roi = struct('e_roi', 1, 'y', 1, 'e_com', 1, 'ch_com', 1, 'e_fwhm', 1, ...
        'compare', 1, 'bkgd', 1, 'chi', 1);
    
    for k = 1:npeaks
        sub_ind = multi_peaks.el(k):multi_peaks.er(k);
        Esub = E(sub_ind);
        ysub = double(scandata.mcadata(sub_ind, :));
        pd = gauss_fit(Esub, ysub);
        roi(k).y = reshape(pd.area, roidims);
        roi(k).e_roi = sub_ind;
        roi(k).e_com = pd.com;
        roi(k).ch_com = pd.ch_com;
        roi(k).e_fwhm = pd.fwhm;
        roi(k).compare = pd.compare;
        roi(k).bkgd = pd.bkgd;
        roi(k).chi = pd.chi;
    end
    scandata.roi = roi;
end
return

