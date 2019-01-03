function pyxrf_to_pymca(scandata, varargin)
% function pyxrf_to_pymca(scandata) 
% will take a variable "scandata"  as input -- a structure
% containing spec scan information (generally including spectra)
% and export to data to an hdf5 format -- suitable for PyMCA.
% 
% This is based on "xmap_to_hdf5" built for CHESS data, and which included
% dead time information. Since SRX currently does not provide that, this
% script only includes a single scalar -- ion chamber. And so will not be
% suitable for GeoPIXE but should work for PyMCA.
%
% TODO: Open
%
% Note:(from Matlab Docs): The HDF5 library uses C-style ordering for multidimensional arrays, 
% while MATLAB uses FORTRAN-style ordering. If the MATLAB array size is 
% 5-by-4-by-3, then the HDF5 library should be reporting the attribute size 
% as 3-by-4-by-5. Please consult "Using the MATLAB Low-Level HDF5 Functions" 
% in the MATLAB documentation for more information.
%
% >> s = h5info('ID20_GeoPIXE_NIST_1834.0006.hdf5', '/2D Scan/Detectors')
% s = 
%       Filename: '/nfs/chess/user/aw30/Matlab/HDF...'
%           Name: 'Detectors'
%       Datatype: [1x1 struct]
%      Dataspace: [1x1 struct]
%      ChunkSize: [25 41 1]
%      FillValue: 0
%        Filters: []
%     Attributes: [6x1 struct]
% 
% >> s.Attributes(2)
% ans =
%          Name: 'Detector Names'
%      Datatype: [1x1 struct]
%     Dataspace: [1x1 struct]
%         Value: {25x1 cell}
% >> s.Attributes(2).Datatype
% ans =
%           Name: ''
%          Class: 'H5T_STRING'
%           Type: [1x1 struct]
%           Size: 8
%     Attributes: []
% >> s.Attributes(2).Datatype.Type
% ans = 
%            Length: 'H5T_VARIABLE'
%           Padding: 'H5T_STR_NULLTERM'
%      CharacterSet: 'H5T_CSET_ASCII'
%     CharacterType: 'H5T_C_S1'
% >> s.Attributes(2).Dataspace
% ans = 
%        Size: 25
%     MaxSize: 25
%        Type: 'simple'
%%

deflate_par = 1;
force_save = 0;

nvarargin = nargin -1;
if mod(nvarargin, 2) ~= 0
    errordlg('Additional args to xmap_to_hdf5 must come in variable/value pairs');
    return
end

onechan = [];

for k = 1:2:nvarargin
    switch varargin{k}
        case 'channel'
            onechan = varargin{k+1};
        case 'force'
            force_save = varargin{k+1};
        otherwise
            warndlg(sprintf('Unrecognized variable %s',varargin{k}));
    end
end   

if isempty(onechan) && length(scandata.mcadata) == 1
    fprintf('Warning: only one set of spectra found: assuming it is channel 1\n')
    onechan = 1;
end


%% generate auto-named hdf5 file

h5filename = strrep(scandata.matfile, '.mat', '_pymca.h5');

% The trim_ind stuff here is to remove the first and last point from each
% line before saving -- to get rid of pesky zeros in Ion Chamber cts.
mcadims = size(scandata.mcadata);
if length(mcadims) > 2
    mcachunk = [mcadims(1:2) 1];
else
    mcachunk = mcadims;
end

ic = single(squeeze(scandata.spec.data(1,:,:)));

%%
% extract ion chamber counts
X = scandata.spec.var1(:, 1)';
Xmotor =  scandata.spec.mot1;
scangroup = '/1D Scan';
if scandata.dims == 2
    Y = scandata.spec.var2(1,:);
    Ymotor = scandata.spec.mot2;
    scangroup = '/2D Scan';
end

%% (the following steps were lifted from the Matlab H5G doc page.
if force_save
    fcpl = H5P.create('H5P_FILE_CREATE');
    fapl = H5P.create('H5P_FILE_ACCESS');
    fid = H5F.create(h5filename, 'H5F_ACC_TRUNC', fcpl, fapl);
else
    fid = H5F.create(h5filename);
end
plist = 'H5P_DEFAULT';
scan_id = H5G.create(fid, scangroup, plist, plist, plist);
H5G.close(scan_id)
H5F.close(fid);

%%
%scangroup = '/2D Scan';
h5writeatt(h5filename,scangroup,'VERSION',3.0)
h5writeatt(h5filename,scangroup,'TAG','S20')
h5writeatt(h5filename,scangroup,'NMCAS',uint16(4))
h5writeatt(h5filename,scangroup,'Header',scandata.spec.scanline)

%%
x_dataset = [scangroup '/X Positions/'];
h5create(h5filename,x_dataset,size(X),'Datatype', 'single')
h5write(h5filename,x_dataset,X)
h5writeatt(h5filename,x_dataset,'Motor Info', Xmotor)
h5writeatt(h5filename,x_dataset,'DATASET_TYPE','X')

if scandata.dims > 1
    y_dataset = [scangroup '/Y Positions/'];
    h5create(h5filename,y_dataset,size(Y),'Datatype', 'single')
    h5write(h5filename,y_dataset, Y)
    h5writeatt(h5filename,y_dataset, 'Motor Info',Ymotor)
    h5writeatt(h5filename,y_dataset, 'DATASET_TYPE','Y')
end

ic_dataset = [scangroup '/IC/'];
h5create(h5filename, ic_dataset, size(ic),'Datatype', 'single');
h5write(h5filename, ic_dataset, ic);
h5writeatt(h5filename, ic_dataset, 'DATASET_TYPE','Ion Chamber')

%%

mca_dataset = [scangroup '/MCA 1'];
h5create(h5filename,mca_dataset, mcadims, ...
    'Deflate', deflate_par, 'ChunkSize', mcachunk   ,'Datatype', 'uint16')         % define h5 file location and size of expected data
h5write(h5filename,mca_dataset, scandata.mcadata) % write data to defined location
h5writeatt(h5filename,mca_dataset,'DATASET_TYPE','MCA')

