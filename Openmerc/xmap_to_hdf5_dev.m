function xmap_to_hdf5(scandata, varargin)
% function xmap_to_hdf5(scandata) 
% will take a variable "scandata"  as input -- a structure
% containing spec scan information (generally including spectra)
% and export to data to an hdf5 format -- ideally suitable for analysis
% by various software packages, such as PyMCA or GeoPIXE.
%
% This variatn assumes that the scandata.mcadata variable is itself a
% 4 element array contating spectra from each of 4 detector channels.
%
% Developed first as a companion to "openmerc" for opening data obtained
% from the Mercury or XMAP controllers for single or quad-element vortex
% detectors, making use of "flymesh" macros (flymesh_v2_a1.mac and
% xiamerc_fly_v3.mac)
%
% 4 Dec ToDo List:
%    * Solve how to save detector names as one of the attributes in
%      Detectors
%    * Figure out Dead time info. Looks like ID20's practice is to save ICR
%      and OCR for each channel
%    * Determine whether the data order should be reversed -- see note
%      below from the Matlab HDF5 docs.
%    * 12/9: File size is enormous: probably storing all values as large
%    floating points: change to uint16s
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

%
%%

deflate_par = 1;

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
        otherwise
            warndlg(sprintf('Unrecognized variable %s',varargin{k}));
    end
end   

if isempty(onechan) && length(scandata.mcadata) == 1
    fprintf('Warning: only one set of spectra found: assuming it is channel 1\n')
    onechan = 1;
end


%% generate auto-named hdf5 file

h5filename = strrep(scandata.matfile, '.mat', '.hdf5');

% The trim_ind stuff here is to remove the first and last point from each
% line before saving -- to get rid of pesky zeros in Ion Chamber cts.
mcadims = size(scandata.mcadata(1).spectra);
trim_ind = 2:mcadims(2)-1;
mcadims(2) = mcadims(2)-2;
mcachunk = [mcadims(1:2) 1];


% Extrct scandata  only the 3rd (timer) and 5th (ion chamber) columns of
% scandata: Columns 1 and 2 are motor positions; column 4 is the motor
% pulses. Below we fill other "detector" channels with ICR, OCR, and a "dt
% corrected ic val. (which is reproduced below as its own dataset for ease
% of user with PyMCA. 
% 
% Note especially this scheme is highly inflexible -- was built very
% specifically to suit A1 data obtained in December 2017. Abstracting to a
% general case is not hard but yet to be done.
scalar_labels = {'Timer'; 'IC_incident'; 'DT-corrected IC'; 'ICR Ch 1'; 'OCR Ch 1'};
spec_scalars = scandata.spec.data([3 5], trim_ind,:);
spec_scalardims = size(spec_scalars);
scalars = zeros(length(scalar_labels), spec_scalardims(2), spec_scalardims(3));
scalardims = size(scalars);
scalars(1:2, :, :) = spec_scalars;
scalars(4, :, :) = scandata.mcadata(1).icr(trim_ind, :);
scalars(5, :, :) = scandata.mcadata(1).ocr(trim_ind, :);
dt_corr_ic = squeeze(scalars(2,:,:) .* scalars(5, :, :) ./ scalars(4, :, :));
scalars(3,:,:) = dt_corr_ic;
scalarchunk = [scalardims(1:2) 1];
TIMEBASE = uint32(1e6); % The timer channel (mcs0) is reading pulses from a 1 MHz clock.
TIMER_CHANNEL = uint16(1);
ICR_CHANNEL = uint16(4);


%%
% extract ion chamber counts

X = scandata.spec.var1(trim_ind, 1)';
Y = scandata.spec.var2(1,:);
Xmotor =  scandata.spec.mot1;
Ymotor = scandata.spec.mot2;

%% (the following steps were lifted from the Matlab H5G doc page.
fid = H5F.create(h5filename);
plist = 'H5P_DEFAULT';
scan_id = H5G.create(fid, '2D Scan', plist, plist, plist);
H5G.close(scan_id)
H5F.close(fid);

%%
scangroup = '/2D Scan';
h5writeatt(h5filename,scangroup,'VERSION',3.0)
h5writeatt(h5filename,scangroup,'TAG','S20')
h5writeatt(h5filename,scangroup,'NMCAS',4)
h5writeatt(h5filename,scangroup,'Header',scandata.spec.scanline)

detector_dataset = '/2D Scan/Detectors';
h5create(h5filename,detector_dataset, scalardims, ...
    'Deflate', deflate_par, 'ChunkSize', scalarchunk ,'Datatype', 'single') 
h5write(h5filename,detector_dataset,scalars)
h5writeatt(h5filename,detector_dataset,'TIMER_CHANNEL',TIMER_CHANNEL)
h5writeatt(h5filename,detector_dataset,'DATASET_TYPE','DETECTORS')
h5writeatt(h5filename,detector_dataset,'TIMEBASE',TIMEBASE)
h5writeatt(h5filename,detector_dataset,'ICR_CHANNEL',ICR_CHANNEL)
h5writeatt(h5filename,detector_dataset,'AUTODTCORR','YES')

%Detector Names attribute must be handled with Low-level functions. THis is
%based on h5ex_t_vlstringatt.m from the H5 group examples page
acpl_id ='H5P_DEFAULT';
type_id = H5T.copy('H5T_FORTRAN_S1');
H5T.set_size (type_id,'H5T_VARIABLE');
memtype = H5T.copy('H5T_C_S1');
H5T.set_size(memtype, 'H5T_VARIABLE');
space_id = H5S.create_simple(1, fliplr(5), []);
fid = H5F.open(h5filename, 'H5F_ACC_RDWR', 'H5P_DEFAULT');
dset_id = H5D.open(fid, '/2D Scan/Detectors');
attr_id = H5A.create(dset_id, 'Detector Names', type_id, space_id, acpl_id);
H5A.write(attr_id, memtype, scalar_labels');
H5A.close(attr_id);
H5S.close(space_id);
H5D.close(dset_id);
H5F.close(fid);

%%
x_dataset = '/2D Scan/X Positions/';
h5create(h5filename,x_dataset,size(X))
h5write(h5filename,x_dataset,X)
h5writeatt(h5filename,x_dataset,'Motor Info', Xmotor)
h5writeatt(h5filename,x_dataset,'DATASET_TYPE','X')

y_dataset = '/2D Scan/Y Positions/';
h5create(h5filename,y_dataset,size(Y))
h5write(h5filename,y_dataset, Y)
h5writeatt(h5filename,y_dataset, 'Motor Info',Ymotor)
h5writeatt(h5filename,y_dataset, 'DATASET_TYPE','Y')

h5create(h5filename,'/2D Scan/DT_corr_IC/',size(dt_corr_ic));
h5write(h5filename,'/2D Scan/DT_corr_IC/',dt_corr_ic);
h5writeatt(h5filename,'/2D Scan/DT_corr_IC/', 'DATASET_TYPE','DeadTime Corrected Ion Chamber')

%%
if ~isempty(onechan)
    mca_dataset = sprintf('/2D Scan/MCA %d', onechan);
    h5create(h5filename,mca_dataset, mcadims,...
        'Deflate', deflate_par, 'ChunkSize', mcachunk  ,'Datatype', 'uint16')         % define h5 file location and size of expected data
    h5write(h5filename,mca_dataset, scandata.mcadata(1).spectra(:, trim_ind,:)) % write data to defined location
    h5writeatt(h5filename,mca_dataset,'DATASET_TYPE','MCA')
else
    mca_dataset = '/2D Scan/MCA 1';
    h5create(h5filename,mca_dataset, mcadims, ...
        'Deflate', deflate_par, 'ChunkSize', mcachunk   ,'Datatype', 'uint16')         % define h5 file location and size of expected data
    h5write(h5filename,mca_dataset, scandata.mcadata(1).spectra(:, trim_ind,:)) % write data to defined location
    h5writeatt(h5filename,mca_dataset,'DATASET_TYPE','MCA')
    
    mca_dataset = '/2D Scan/MCA 2';
    h5create(h5filename,mca_dataset, mcadims, ...
        'Deflate', deflate_par, 'ChunkSize', mcachunk   ,'Datatype', 'uint16')          % define h5 file location and size of expected data
    h5write(h5filename,mca_dataset, scandata.mcadata(2).spectra(:, trim_ind,:)) % write data to defined location
    h5writeatt(h5filename,mca_dataset,'DATASET_TYPE','MCA')
    
    mca_dataset = '/2D Scan/MCA 3';
    h5create(h5filename,mca_dataset, mcadims, ...
        'Deflate', deflate_par, 'ChunkSize', mcachunk   ,'Datatype', 'uint16')          % define h5 file location and size of expected data
    h5write(h5filename,mca_dataset, scandata.mcadata(3).spectra(:, trim_ind,:)) % write data to defined location
    h5writeatt(h5filename,mca_dataset,'DATASET_TYPE','MCA')
    
    mca_dataset = '/2D Scan/MCA 4';
    h5create(h5filename,mca_dataset, mcadims,...
        'Deflate', deflate_par, 'ChunkSize', mcachunk  ,'Datatype', 'uint16')         % define h5 file location and size of expected data
    h5write(h5filename,mca_dataset, scandata.mcadata(4).spectra(:, trim_ind,:)) % write data to defined location
    h5writeatt(h5filename,mca_dataset,'DATASET_TYPE','MCA')
    
end

