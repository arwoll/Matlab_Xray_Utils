function [sorted_files, files_per_point] = tiff_file_sort(mcafiles)
%
% sort an arbitrary collection of tif filenames matching the pattern:
%    specfile_device_scann_ptn_filen.tiff
%  
%    returning a cell array sorted_files where:
%        sorted_files(N) is a cell array containing the tiff file names for
%        point number N. e.g. sorted_files(N){n} is the filename for the
%        nth file for point N.
%  
% 6 Feb 2018: I notice that I pick up the scan number below, but do not
% user it. It COULD be used to check that all files are associated with the
% same scan...
%
% 
%fprintf('In tiff_file_sort: PLEASE TEST files_per_point bit, then make that output mandatory\n');

sorted_files = {};
nfiles = length(mcafiles);
A = zeros(nfiles, 3);
for k = 1:nfiles
   [path, name, extn] = fileparts(mcafiles{k});
   C = strsplit(name, '_');
   if (length(C) < 3)
       fprintf('Error in tiff_file_sort: cannot grab scann, ptn, and filen\n');
       return
   end
   A(k,:) = str2double(C(end-2:end));
   if any(isnan(A(k,:)))
       fprintf('Error in tiff_file_sort: NaN found among scann, ptn, filen\n');
       return
   end
end

% Sort the filenames by point number, then file number
[A, order] = sortrows(A, [2 3]);
mcafiles = mcafiles(order);
npts = A(end, 2);
files_per_point = max(A(:, 3))+1;
% if nargout == 2
%     varargout{1} = files_per_point;
% end

sorted_files = cell(npts, 1);

for k = 1:nfiles
    ptn = A(k,2); filen = A(k,3);
    sorted_files{ptn+1}{filen+1} = mcafiles{k};
end
