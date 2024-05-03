function success = flyscan_hdf5_append(scandata, scalar_data, mca_data, varargin)
% function flyscan_hdf5_writerow(scandata, scalar_row, mca_row, varargin) 
% will take a variable "scandata"  as input -- a structure
% containing spec scan information (generally including spectra)
% and export to data to an hdf5 format -- ideally suitable for analysis
% by various software packages, such as PyMCA or GeoPIXE.
% >> foo = h5info('seed1_eveXMAP_0027.h5', '/2D Scan/Detectors')
% foo = 
%       Filename: '/nfs/chess/aux/cycles/2018-1/g3/vatamaniuk-701-2/analysis/seed1_overnight_consolidate/seed1_eveXM?'
%           Name: 'Detectors'
%       Datatype: [1x1 struct]
%      Dataspace: [1x1 struct]
%      ChunkSize: [5 181 1]
%      FillValue: 0
%        Filters: [1x1 struct]
%     Attributes: [6x1 struct]
% 
% >> foo.Dataspace
% ans = 
%        Size: [5 181 76]
%     MaxSize: [5 181 Inf]
%        Type: 'simple'
%%
success = 1;
deflate_par = 1;
nvarargin = nargin -3;
if mod(nvarargin, 2) ~= 0
    errordlg('Additional args to flyscan_hdf5_init must come in variable/value pairs');
    return
end

% if isempty(onechan) && length(scandata.mcadata) == 1
%     fprintf('Warning: only one set of spectra found: assuming it is channel 1\n')
%     onechan = 1;
% end


%% generate auto-named hdf5 file
% detector_dataset = '/2D Scan/Detectors';
% h5create(h5filename,detector_dataset, [scalarchunk(1) scalarchunk(2) Inf], ...'Inf', ...  scalardims, ...
%     'Deflate', deflate_par, 'ChunkSize', scalarchunk ,'Datatype', 'single') 

h5filename = scandata.h5file;

detector_dataset = '/2D Scan/Detectors';
detector_info = h5info(h5filename, detector_dataset);
scalar_dims_file = detector_info.Dataspace.Size;
nslow = scalar_dims_file(3)+1;
%scalar_labels = {'Timer'; 'IC_incident'; 'DT-corrected IC'; 'ICR Ch 1'; 'OCR Ch 1'};
scalarchunk = detector_info.ChunkSize; %[length(scalar_labels) scandata.nfast];
scalar_dims_in = size(scalar_data);
if scalar_dims_file(2) ~= scalar_dims_in(2) || scalar_dims_file(1) ~= 5 || scalar_dims_in(1) ~= 5
    fprintf('Error: scalar_data incompatible with h5file %s\n', h5filename);
    return
end

%% (the following steps were lifted from the Matlab H5G doc page.
if ~exist(h5filename, 'file')
    fprintf('Error: hdf5 file to append to, %s, not found\n', h5filename);
    return
end


% 
% % Extrct scandata  only the 3rd (timer) and 5th (ion chamber) columns of
% % scandata: Columns 1 and 2 are motor positions; column 4 is the motor
% % pulses. Below we fill other "detector" channels with ICR, OCR, and a "dt
% % corrected ic val. (which is reproduced below as its own dataset for ease
% % of user with PyMCA. 

% scalars = zeros([5, scalar_dims_in(2:3)], 'single');
% scalardims = size(scalars);
% scalars(1:2, :, :) = scalar_data([3 5], :,:);
% scalars(4, :,:) = mca_data(1).icr;
% scalars(5, :,:) = mca_data(1).ocr;
% scalars(3,:,:) = scalars(2,:,:) .* scalars(5, :,:) ./ scalars(4, :,:);
scalars = scalar_data;
ic = squeeze(scalars(2,:,:));
dt_corr_ic = squeeze(scalars(3,:,:));

% %% Writing data
start = [1 1 nslow];
count = size(scalars);
h5write(h5filename,detector_dataset, scalars, start, count);

% TODO: review how X's and Y's are normally saved (which index first)
X = squeeze(scalar_data(1, :,:));
Y = squeeze(scalar_data(2, :,:)); % THESE VALUES ARE ASSUMED TO BE IDENTICAL IN EACH ROW
x_dataset = '/2D Scan/X Positions/';
y_dataset = '/2D Scan/Y Positions/';


%h5create(h5filename,detector_dataset, [scalarchunk(1:2) Inf], ...'Inf', ...  scalardims, ...
%    'Deflate', deflate_par, 'ChunkSize', scalarchunk ,'Datatype', 'single') 
% Need to include chunk size = nfast x 1
mcadims = size(mca_data(1).spectra);
nfast = size(X, 1); %numel(X);
if nslow == 1
    Xmotor =  scandata.mot1;
    Ymotor = scandata.mot2;
    h5create(h5filename,x_dataset,[nfast Inf],...
        'Deflate', deflate_par, 'ChunkSize', [nfast 1] ,'Datatype', 'single');
    h5writeatt(h5filename,x_dataset,'Motor Info', Xmotor)
    h5writeatt(h5filename,x_dataset,'DATASET_TYPE','X')
    
    h5create(h5filename,y_dataset,[nfast Inf],...
        'Deflate', deflate_par, 'ChunkSize', [nfast 1] ,'Datatype', 'single');
    h5writeatt(h5filename,y_dataset, 'Motor Info',Ymotor)
    h5writeatt(h5filename,y_dataset, 'DATASET_TYPE','Y')
    
    h5create(h5filename,'/2D Scan/IC/',[nfast Inf], ...
        'Deflate', deflate_par, 'ChunkSize', [nfast 1], 'Datatype', 'single');
    h5writeatt(h5filename,'/2D Scan/IC/', 'DATASET_TYPE','Ion Chamber')
    
    h5create(h5filename,'/2D Scan/DT_corr_IC/',[nfast Inf], ...
        'Deflate', deflate_par, 'ChunkSize', [nfast 1], 'Datatype', 'single');
    h5writeatt(h5filename,'/2D Scan/DT_corr_IC/', 'DATASET_TYPE','DeadTime Corrected Ion Chamber')
    for k=1:length(mca_data)
        mca_dataset = sprintf('/2D Scan/MCA %d',k);
        h5create(h5filename,mca_dataset, [mcadims(1:2) Inf], ...
            'Deflate', deflate_par, 'ChunkSize', [mcadims(1:2) 1],'Datatype', 'uint16')    
        h5writeatt(h5filename,mca_dataset,'DATASET_TYPE','MCA')
    end
end
% Syntax: h5write(filename,datasetname,data,start,count)
h5write(h5filename,x_dataset, X, [1 nslow], size(X));
h5write(h5filename,y_dataset, Y, [1 nslow], size(Y));

h5write(h5filename,'/2D Scan/IC/',ic, [1 nslow], size(ic));
h5write(h5filename,'/2D Scan/DT_corr_IC/',dt_corr_ic, [1 nslow], size(dt_corr_ic));


for k=1:length(mca_data)
    mca_dataset = sprintf('/2D Scan/MCA %d',k);
    h5write(h5filename,mca_dataset, mca_data(k).spectra, [1 1 nslow], ...
        size(mca_data(k).spectra)); % write data to defined location
end

