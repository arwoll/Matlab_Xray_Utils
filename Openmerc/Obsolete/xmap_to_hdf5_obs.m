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
%%
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
scalars = scandata.spec.data;
scalardims = size(scalars);

time = scandata.spec.cttime;
%icr =9;
%%
map.ctime = scandata.spec.cttime;
% extract ion chamber counts

map.ic = squeeze(scandata.spec.data(5,trim_ind,1:mcadims(3)));
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
h5writeatt(h5filename,scangroup,'VERSION',0)
h5writeatt(h5filename,scangroup,'TAG','0')
h5writeatt(h5filename,scangroup,'NMCAS',4)
h5writeatt(h5filename,scangroup,'Header','test')

% detector_dataset = '/2D Scan/Detectors';
% h5create(h5filename,detector_dataset,scalardims, 'Datatype', 'single') 
% h5write(h5filename,detector_dataset,scalars)
% h5writeatt(h5filename,detector_dataset,'TIMER_CHANNEL',1)

%% This snippet does not work. 
% % The example file from ID20 has quite complicated structure.
% % I dont have a clue about what these "spaces" are supposed to be. ALso, in
% % the ID20 template, the Datatype field of the Detector Names attribute is
% % itself a structure, whereas the Dataspace field is just "simple". Not
% % sure how to accomplish this.
% acpl_id = H5P.create('H5P_ATTRIBUTE_CREATE');
% type_id = H5T.copy('H5T_STRING');
% space_id = H5S.create('H5S_SIMPLE');
% fid = H5F.open(h5filename);
% attr_id = H5A.create(fid, 'Detector Names', type_id, space_id, acpl_id);
% H5A.write(attr_id, 'H5ML_DEFAULT', scandata.spec.headers);
% H5A.close(attr_id);
% H5F.close(fid);
%%

%h5writeatt(h5filename,detector_dataset,'DATASET_TYPE','DETECTORS')
%h5writeatt(h5filename,detector_dataset,'TIMEBASE',time)
%h5writeatt(h5filename,detector_dataset,'ICR_CHANNEL',icr)
%h5writeatt(h5filename,detector_dataset,'AUTODTCORR','YES')

%%
DEFLATE = 1;
if ~isempty(onechan)
    mca_dataset = sprintf('/2D Scan/MCA %d', onechan);
    h5create(h5filename,mca_dataset, mcadims,...
        'Deflate', DEFLATE, 'ChunkSize', [mcadims(1:2) 1]  ,'Datatype', 'uint16')         % define h5 file location and size of expected data
    h5write(h5filename,mca_dataset, scandata.mcadata(1).spectra(:, trim_ind,:)) % write data to defined location
    h5writeatt(h5filename,mca_dataset,'DATASET_TYPE','MCA')
else
    mca_dataset = '/2D Scan/MCA 1';
    h5create(h5filename,mca_dataset, mcadims, ...
        'Deflate', DEFLATE, 'ChunkSize', [mcadims(1:2) 1]  ,'Datatype', 'uint16')         % define h5 file location and size of expected data
    h5write(h5filename,mca_dataset, scandata.mcadata(1).spectra(:, trim_ind,:)) % write data to defined location
    h5writeatt(h5filename,mca_dataset,'DATASET_TYPE','MCA')
    
    mca_dataset = '/2D Scan/MCA 2';
    h5create(h5filename,mca_dataset, mcadims, ...
        'Deflate', DEFLATE, 'ChunkSize', [mcadims(1:2) 1]  ,'Datatype', 'uint16')          % define h5 file location and size of expected data
    h5write(h5filename,mca_dataset, scandata.mcadata(2).spectra(:, trim_ind,:)) % write data to defined location
    h5writeatt(h5filename,mca_dataset,'DATASET_TYPE','MCA')
    
    mca_dataset = '/2D Scan/MCA 3';
    h5create(h5filename,mca_dataset, mcadims, ...
        'Deflate', DEFLATE, 'ChunkSize', [mcadims(1:2) 1]  ,'Datatype', 'uint16')          % define h5 file location and size of expected data
    h5write(h5filename,mca_dataset, scandata.mcadata(3).spectra(:, trim_ind,:)) % write data to defined location
    h5writeatt(h5filename,mca_dataset,'DATASET_TYPE','MCA')
    
    mca_dataset = '/2D Scan/MCA 4';
    h5create(h5filename,mca_dataset, mcadims,...
        'Deflate', DEFLATE, 'ChunkSize', [mcadims(1:2) 1]  ,'Datatype', 'uint16')         % define h5 file location and size of expected data
    h5write(h5filename,mca_dataset, scandata.mcadata(4).spectra(:, trim_ind,:)) % write data to defined location
    h5writeatt(h5filename,mca_dataset,'DATASET_TYPE','MCA')
    
end

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

h5create(h5filename,'/2D Scan/ic/',size(map.ic));
h5write(h5filename,'/2D Scan/ic/',map.ic);
h5writeatt(h5filename,'/2D Scan/ic/', 'DATASET_TYPE','Ion Chamber')

