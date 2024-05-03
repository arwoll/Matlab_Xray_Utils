function success = falcon_hdf5_writerow(scandata, scalar_row, mca_row, varargin)
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
    errordlg('Additional args to falcon_hdf5_writerow must come in variable/value pairs');
    return
end

% if isempty(onechan) && length(scandata.mcadata) == 1
%     fprintf('Warning: only one set of spectra found: assuming it is channel 1\n')
%     onechan = 1;
% end


%% generate auto-named hdf5 file

h5filename = scandata.h5file;

detector_dataset = '/2D Scan/Detectors';
scalar_labels = {'Timer'; 'IC_incident'; 'DT-corrected IC'; 'ICR Ch 1'; 'OCR Ch 1'};
scalarchunk = [length(scalar_labels) scandata.nfast];
nslow = scandata.nslow;

%% (the following steps were lifted from the Matlab H5G doc page.
if ~exist(h5filename, 'file')
    fprintf('Error: hdf5 file to append to, %s, not found\n', h5filename);
    return
end

% detector_dataset = '/2D Scan/Detectors';
% h5create(h5filename,detector_dataset, [scalarchunk(1) scalarchunk(2) Inf], ...'Inf', ...  scalardims, ...
%     'Deflate', deflate_par, 'ChunkSize', scalarchunk ,'Datatype', 'single') 

% % The trim_ind stuff here is to remove the first and last point from each
% % line before saving -- to get rid of pesky zeros in Ion Chamber cts.
mcadims = size(mca_row(1).spectra);
% trim_ind = 2:mcadims(2)-1;
%mcadims(2) = mcadims(2)-2;
%mcachunk = [mcadims(1:2) 1];
% 
% % Extrct scandata  only the 3rd (timer) and 5th (ion chamber) columns of
% % scandata: Columns 1 and 2 are motor positions; column 4 is the motor
% % pulses. Below we fill other "detector" channels with ICR, OCR, and a "dt
% % corrected ic val. (which is reproduced below as its own dataset for ease
% % of user with PyMCA. 

scalars = zeros(scalarchunk, 'single');
scalardims = scalarchunk;
scalars(1:2, :) = scalar_row([3 5], :);
scalars(4, :) = mca_row(1).icr;
scalars(5, :) = mca_row(1).ocr;
ic = scalars(2,:)';
dt_corr_ic = ic .* scalars(5, :)' ./ scalars(4, :)';
scalars(3,:) = dt_corr_ic';

% %% Writing data
start = [1 1 nslow];
count = [scalardims 1];
h5write(h5filename,detector_dataset, scalars, start, count);

% Convert X's and Y's to microns . (Better would be to have units as an
% attribute!
X = 1000 * scalar_row(1, :);
Y = 1000 * scalar_row(2, 1)'; % THESE VALUES ARE ASSUMED TO BE IDENTICAL IN EACH ROW
x_dataset = '/2D Scan/X Positions/';
y_dataset = '/2D Scan/Y Positions/';


%h5create(h5filename,detector_dataset, [scalarchunk(1:2) Inf], ...'Inf', ...  scalardims, ...
%    'Deflate', deflate_par, 'ChunkSize', scalarchunk ,'Datatype', 'single') 
% Need to include chunk size = nfast x 1
nfast = numel(X);
if nslow == 1
    Xmotor =  scandata.mot1;
    Ymotor = scandata.mot2;
    h5create(h5filename,x_dataset,[1 nfast Inf],...
        'Deflate', deflate_par, 'ChunkSize', [1 nfast 1] ,'Datatype', 'single');
    h5writeatt(h5filename,x_dataset,'Motor Info', Xmotor)
    h5writeatt(h5filename,x_dataset,'DATASET_TYPE','X')
    
    h5create(h5filename,y_dataset,[Inf 1],...
        'Deflate', deflate_par, 'ChunkSize', [1 1] ,'Datatype', 'single');
    h5writeatt(h5filename,y_dataset, 'Motor Info',Ymotor)
    h5writeatt(h5filename,y_dataset, 'DATASET_TYPE','Y')
    
    h5create(h5filename,'/2D Scan/IC/',[nfast Inf], ...
        'Deflate', deflate_par, 'ChunkSize', [nfast 1], 'Datatype', 'single');
    h5writeatt(h5filename,'/2D Scan/IC/', 'DATASET_TYPE','Ion Chamber')
    
    h5create(h5filename,'/2D Scan/DT_corr_IC/',[nfast Inf], ...
        'Deflate', deflate_par, 'ChunkSize', [nfast 1], 'Datatype', 'single')
    h5writeatt(h5filename,'/2D Scan/DT_corr_IC/', 'DATASET_TYPE','DeadTime Corrected Ion Chamber')
    for k=1:length(mca_row)
        mca_dataset = sprintf('/2D Scan/MCA %d',k);
        h5create(h5filename,mca_dataset, [mcadims Inf], ...
            'Deflate', deflate_par, 'ChunkSize', [mcadims 1],'Datatype', 'uint32')    
        h5writeatt(h5filename,mca_dataset,'DATASET_TYPE','MCA')
    end
end
% Syntax: h5write(filename,datasetname,data,start,count)
h5write(h5filename,x_dataset, X, [1 1 nslow], [1 nfast 1]);
h5write(h5filename,y_dataset, Y, [nslow 1], [1 1]);

h5write(h5filename,'/2D Scan/IC/',ic, [1 nslow], [nfast 1]);
h5write(h5filename,'/2D Scan/DT_corr_IC/',dt_corr_ic, [1 nslow], [nfast 1]);
for k=1:length(mca_row)
    mca_dataset = sprintf('/2D Scan/MCA %d',k);
    h5write(h5filename,mca_dataset, mca_row(k).spectra, [1 1 nslow], ...
        [mcadims 1]) % write data to defined location
end

