function [E, chans, spectra] = import_spec_multi(fname)
% function [E, chans, spectra] = import_spec_multi(fname)
%  returns the Energy, detector numbers, and spectra from a
%  GeoPIXE-exported csv file. 

fid = fopen(fname, 'r');
headline = fgetl(fid);
headers = textscan(headline, '%s', 'Delimiter', ',');
try 
    headers = headers{1};
catch
    fprintf('import_spec_multi : Error scanning for headers\n');
end

cols = length(headers);

dataArray = textscan(fid, '%f', 'Delimiter', ',', ...
    'EmptyValue' ,NaN, 'ReturnOnError', false);

dataArray = dataArray{1};
nelements = length(dataArray);

if rem(nelements, cols) > 0
     fprintf('import_spec_multi : Error -- number of elements not a multiple of header rows\n');
end

rows = nelements/cols;

dataArray = transpose(reshape(dataArray, cols, rows));
E = dataArray(:,1);
spectra = dataArray(:, 2:end);

chans = NaN(384,1);
for k=2:cols
    u = strfind(headers{k}, '_');
    detN = str2num(headers{k}(u(end-1)+1:u(end)-1));
    chans(detN+1) = k-1;
end

