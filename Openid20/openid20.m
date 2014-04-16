function scan = openid20(filename)
% function scan = openid20(filename)
% reads an ascii text file filename, output by LabView control software at ID20, 
% and returns data from that file in a data structure with fields
% representing different information in the file, esp:
% 
%     * scan.fileheader : The complete text header of the file
%     * scan.data : a 2D (for 1-D scans) or 3D (for 2-D scans) matrix
%       containing the scan data. The first index is the column number
%     * scan.headers : a cell array containing the column labels for the
%       data
%
% NOTE: openid20 uses the first line to determine dimensionality of scan,
% "1-D" or "2-D".It next finds the "Column Headings" line, and assumes the actual
%  column labels are on the line immediately following.

scan = [];

fileid = fopen(filename, 'r');
if fileid == -1
    fprintf('Error: file %s not found....abort\n', filename);
    return
end

%
%  DETERMINE 2D VS 1D
%

nextline = [fgetl(fileid) char(13)];    % The newline character, 13, is appended to 
                                        % make the scan.fileheader string print nicely
if nextline(1) ~= '#'
    fprintf('Error: file %s not recognized (first character not "#")\n',filename);
    return
end

fileheader = nextline;
scan_type = strtok(nextline(2:end));  % "1-D"  or "2-D"
ion_chambers = struct('name', {}, 'sensitivity', {}, ...
    'V0', {}', 'V1', {}); % Sensitivity in A/V


nextline = [fgetl(fileid) char(13)];   % Net effect of this motif is to remove carriage returns but leave newlines
fileheader = horzcat(fileheader, nextline);
[tok, partline] = strtok(nextline);
while tok(1) =='#'
    if ~isempty(strfind(partline, 'Column Headings'))
        nextline = [fgetl(fileid) char(13)];
        fileheader = horzcat(fileheader, nextline);
        break
    elseif ~isempty(strfind(partline, 'Sensitivities'))
        nextline = [fgetl(fileid) char(13)];
        fileheader = horzcat(fileheader, nextline);
        [tok, partline] = strtok(nextline);
        values = textscan(partline(1:end-1), '%s %f %s', 'whitespace', ' \b\t:');
        for k = 1:length(values{1})
           ion_chambers(k).name = values{1}{k};
           ion_chambers(k).sensitivity = values{2}(k);
           switch values{3}{k}
               case 'nA/V'
                   ion_chambers(k).sensitivity = ion_chambers(k).sensitivity * 1e-9;
               case 'pA/V'
                   ion_chambers(k).sensitivity = ion_chambers(k).sensitivity * 1e-12;
           end
        end
    elseif ~isempty(strfind(partline, 'Analog Input Voltages'))
        ic_names = {ion_chambers.name};
        nextline = [fgetl(fileid) char(13)];
        fileheader = horzcat(fileheader, nextline);
        [tok, partline] = strtok(nextline);
        values = textscan(partline(1:end-1), '%s %f %f', 'whitespace', ' \b\t:/');
        for k = 1:length(values{1})
           this_ic = strcmp(values{1}{k}, ic_names);
           if any(this_ic)
               ion_chambers(this_ic).V0 = values{2}(k);
               ion_chambers(this_ic).V1 = values{3}(k);
           end
        end
    end
    nextline = [fgetl(fileid) char(13)];
    if nextline == -1
            fprintf('Error: Reached end of file %s without finding Column Headings line\n', filename);
        return
    end
    fileheader = horzcat(fileheader, nextline);
    [tok, partline] = strtok(nextline);
end

% The following regular expression is used to capture individual column
% labels names as they appear the files -- immediately after the "# Column
% Headings" line.  Distinct motor or counter labels begin with an
% alphanumeric character or '-' and may include single spaces between more
% such characters.  At least two whitespace characters (or an '*') are required to separate
% neighboring names.  The regexp breaks down as follows:
%   [\w-]+ : match  1 or more alphanumeric ([a-zA-Z_0-9]) or dash
%   ( ?    : match 0 or 1 spaces within the label
%   ( ?[^ \f\n\r\t\v*]+)* : match 0 or more tokens, where a token is: 0 or 1 spaces
%       followed by 1 or more alphnumberic chars, dash, parens or colons

ID20_LABEL_REGEXP = '[\w-]+( ?[^ \f\n\r\t\v*]+)*';

headers = regexp(nextline(2:end), ID20_LABEL_REGEXP, 'match');
ncolumns = length(headers);

if strcmp(scan_type, '2-D')
    extra_line = fgetl(fileid);
    scan_dims = textscan(extra_line, '* %*d %*d %*d %d %d');
    var1_n = double(scan_dims{1});
    var2_n = double(scan_dims{2});
end

lines = 0;
data = [];
[data_cell, stop_position] = textscan(fileid, '%f');
if ~isempty(data_cell{1})
    data = [data' data_cell{1}']';
end

fclose(fileid);
lines = length(data)/ncolumns;

if lines==0
    fprintf('No data found in file %s\n',filename);
    return
end

scan.data = reshape(data, ncolumns, lines);
scan.ion_chambers = ion_chambers;
scan.filename = filename;
scan.fileheader = fileheader;
scan.headers = headers;
scan.npts = lines;
scan.columns = ncolumns;
scan.type = scan_type;

% specscan.complete = 1 / -1: scan is complete / incomplete

scan.complete = 1;
switch scan_type
    case '1-D'        
        scan.ctrs = headers(2:end);
        scan.var1 = scan.data(1,:)';
        scan.mot1 = headers{1};
        scan.dims = 1;
        scan.size = lines;
        scan.scanline = sprintf('1-D scan, motor %s from %g to %g, %d points', ...
            scan.mot1, scan.var1(1), scan.var1(end), scan.size);
    case '2-D'
        scan.ctrs = headers(3:end);
        scan.mot1 = headers{1};
        scan.mot2 = headers{2};

        planned_npts = var1_n*var2_n;

        if planned_npts ~= scan.npts
            scan.complete = -1;
            scan.extra = mod(scan.npts, var1_n);
            if scan.extra ~= 0
                scan.npts = scan.npts - scan.extra;
            end 
            var2_n = scan.npts/var1_n;
            scan.data=reshape(scan.data(:,1:scan.npts), ...
                ncolumns, var1_n, var2_n);
        else
            scan.data=reshape(scan.data,ncolumns, var1_n, var2_n);
        end
        scan.var1 = squeeze(scan.data(1,:,:)); 
        scan.var2 = squeeze(scan.data(2,:,:));
        scan.dims = 2;
        scan.size = [var1_n var2_n];
        scan.scanline = sprintf('2-D scan, motor %s from %g to %g, %d points, motor %s from %g to %g, %d points', ...
            scan.mot1, scan.var1(1), scan.var1(end), scan.size(1), ...
            scan.mot2, scan.var2(1), scan.var2(end), scan.size(2));
    otherwise
        fprintf('Error: Unrecognized scan type in %s\n',filename);
        return
end % -------- switch -------------

