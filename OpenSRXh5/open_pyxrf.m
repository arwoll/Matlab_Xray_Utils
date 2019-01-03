function scandata = openpyxrf_all(fn)
%function fitdata = open_pyxrf(fn, E0)
% 0. URGENT ToDo: Fix opening of fly scans...Done. NOTE: xrf_fly and 2dxrf
% scans seem to have different behavoir. Specifically, in 2dxrf scans, the
% columns in the maps are associated with variation in the columnns of the
% SECOND motor in motor_pos. In contrast, in xrf_fly scans, the columns of
% the maps are associated with the FIRST motor in motor_pos.
%
% Other info: in fly scans, the fly motor is the first listed on the scan
% line, but the 2nd motor in motor_names, and corresponds to the ROWS in
% the map data...
% 
% 1. If fn is the name of a SRX scan of type "2dxrf": deduce whether the
%    scan is really a 2D map or a 1D scan, and spit out a corresponding
%    structure. Possibly also: use elamdb to pick out the element and group of
%    the sort the individual maps, possibly sort them.
%
% 2. NOTE: when the maps are loaded into matlab, columns correspond to the
%    fast/first axis. It looks like my vertical resolution maps were all taken
%    with hf_stage_z as the fast axis, so it works well to label "x" as the
%    2nd axis in this case. this may not always be so!
% 3. For fly scans, we know that at minimum, the i0 label changes from
%    sclr_i0 to just i0. 
%
% TODO : where fn is an h5 file containing fit results (from pyxrf) and E0 is the
% incident energy, returns a structure with standard 'scandata' format,
% e.g. which can be re-saved to an hdf5 format that is readable by GeoPIXE. 
%

[p, f, e] = fileparts(fn);
fnames = deblank(h5read(fn, '/xrfmap/detsum/xrf_fit_name'));
ffit = h5read(fn, '/xrfmap/detsum/xrf_fit');
nfit = length(fnames);
i0_name = deblank(h5read(fn, '/xrfmap/scalers/name'));
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
i0_dat = squeeze(h5read(fn, '/xrfmap/scalers/val'));
% The following corrects for the fact that for 1D scans, the scalar data is
% saved in a single row. Need it in col form to match dims of ffit.
i0_dat = squeeze(i0_dat(i0_ind,:,:));
if size(i0_dat, 1) == 1
   i0_dat = i0_dat'; 
end
i0_norm = mean(i0_dat(:));
for k = 1:nfit
    scandata.roi(k).I = squeeze(ffit(:,:,k));
    scandata.roi(k).name = fnames{k};
end

motor_names = deblank(h5read(fn, '/xrfmap/positions/name'));
motor_pos = h5read(fn, '/xrfmap/positions/pos');

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
%    motor_names = motor_names{rest_axis};
%    motor_pos = motor_pos(1,1,rest_axis);
   var1 = squeeze(motor_pos(:,:,scan_axis));
else
    mot1 = motor_names{2};
    mot2 = motor_names{1};
    var1 = squeeze(motor_pos(:,1,2));
    var2 = squeeze(motor_pos(1,:,1));
    % The following takes care of a very unfortunate difference between fly
    % and non-fly scans...
    if var1(end)-var1(1) < 1e-6
        mot1 = motor_names{1};
        mot2 = motor_names{2};
        var1 = squeeze(motor_pos(:,1,1));
        var2 = squeeze(motor_pos(1,:,2));
    end
end

% The following hard codes the x's and y's and so may not be general

scandata.filename = f;
scandata.dims = dims;
scandata.fnames = fnames;
scandata.var1 = var1;
scandata.mot1 = mot1;

% if dims == 1
scandata.motor_names = motor_names;
scandata.motor_pos = motor_pos;
if dims>1
    scandata.var2 = var2;
    scandata.mot2 = mot2;
end
scandata.i0_dat = i0_dat;
scandata.i0_norm = i0_norm;
%return
% quality of fit?

%% Gather info about the lines taht were fit
if exist('cs_fluor_total', 'file') == 0
    addpath( '/home/aw30/Matlab/Xraylib:')
    xraylib_setup
end
roi =  scandata.roi;

sym = fnames;
group = sym;
nA = sym;
load elamdb  % loads ele, a structure with element info, and n, a structure of atomic numbers 
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
   [sigma_f, e] = cs_fluor_total(roi(k).nA, roi(k).group, E0);
   roi(k).E = e;
   roi(k).sigma_f = sigma_f;
end

[vals, indices] = sort([roi.E]);
roi = roi(indices);
scandata.fnames = {roi.name};

scandata.roi = roi;
return

