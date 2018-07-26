function [scan_start, scan_data_start, scan_end, motor_start, motor_end] = openmerc_find_scan(specfile, scann)
% [scan_start, scan_end, motor_mark, motor_end] = openmerc_find_scan(specfile, scann)
% 
% openmerc_find_scan finds the start and end positions of a scan in a
% datafile, as well as the most recent (before the scan) position in the
% file where the motor names are specified. 
% This permits the full scan string to be read outside the
% function. 
% 
% Not sure whether scan_end should only be non-negative if the actual end
% of the scan is found, or alternatively whether it should mark the last
% position in the file that was read. (oustide you could mark that with
% ftel
% 
% [scan_start, scan_end, motor_mark] = find_scan(specfile, scan)
% Assumes specfile is alredy open. Makes no noise if the scan is not found, but
% returns scanline = -1.  
%
% scan_mark and motor_mark are the file position of the scan and (neareast preceding)
% motor position lines, respectively.
%
% In textscan, the format spec %[^\n] reads all characters other than
% newline.

if scann ~= floor(scann) && floor(10*scann)>0
    occurrance = floor(10*scann);
else
    occurrance = 1;
end

scan_start = [];
scan_data_start = [];
scan_end = [];
motor_start = [];
motor_end = [];

lfchar = sprintf('\n');
FREAD_CHUNK = 1e6;

% The leading '*' directs the output data type, the following *1 ensures
% single-byte characters.
% Note: loop through, but only keep the last motor_mark before scan.

n_found = 0;
byte_offset = 0;
% Cases:
%   1: Nothing found (in first loop)
%   2. scan_start not found. Get motor mark
%   3. scan_start found, not end.
%   4. both scan_start and scan_end found.
while(1)
    A = fread(specfile, FREAD_CHUNK, '*char*1')';
    endoflines = strfind(A, lfchar);
    % Process EITHER to the end of a line OR to EOF
    if ~feof(specfile)
        if numel(endoflines) == 0
            % fprintf('Problem with data file -- no end of lines in 10 MB
            % chunk
            return
        else
            end_chunk = endoflines(end);
            A = A(1:end_chunk);
        end
    end
    scan_marks = strfind(A, '#S');
    motor_marks = strfind(A, '#O0');
    if ~isempty(scan_start)
        if ~isempty(scan_marks)
            if isempty(scan_data_start)
                scan_data_start = byte_offset + regexp(A(scan_marks(1):end, '\n[^#]'), 'once');
            end
            scan_end = byte_offset + scan_marks(1)-1;
            % In this case I think we're done and can return
            return
        end
        % if scan_marks == [], then EITHER the file ends, which will be
        % detected after the (for) loop, OR the chunk spans some middle of the
        % scan, in which case the outer (while) loop will continue.
    end
    if ~isempty(motor_start) && isempty(motor_end) && ~isempty(scan_marks)
        motor_end = byte_offset + scan_marks(1) - 1;
    end
    for k = 1:length(scan_marks)
        this_scann = str2double(strtok(A(scan_marks(k)+2:scan_marks(k)+20)));
        if this_scann == scann
           n_found = n_found + 1;
           if n_found == occurrance
               scan_start = byte_offset + scan_marks(k)-1;
               % Find data start
               scan_data_start = scan_start + ...
                   regexp(A(scan_marks(k):end), '\n[^#]', 'once');
               
               % Find motor mark
               if ~isempty(motor_marks)
                   motor_start = byte_offset + motor_marks(find(motor_marks < scan_marks(k), 1, 'last')) - 1;
                   motor_end = byte_offset + scan_marks(find(scan_marks > (motor_start-byte_offset), 1, 'first')) - 1;
               end
               if numel(scan_marks) > k
                   scan_end = byte_offset + scan_marks(k+1) - 1;
                   return
               end
           end
        end
    end
    if isempty(scan_start) && ~isempty(motor_marks)
        motor_start = byte_offset + motor_marks(end) - 1;
        if ~isempty(scan_marks) && any(scan_marks > (motor_start-byte_offset))
           motor_end =  byte_offset + scan_marks(find(scan_marks > (motor_start-byte_offset), 1, 'first')) - 1;
        end
        % change motor_mark output to motor_marks, a 2-value vector giving
        % positions in the file that contain the motor deffs. Note the risk
        % that the motor definitions could be split accross reads (like the
        % scan.
    end
    
    if feof(specfile)
        break
    else
        byte_offset = byte_offset + end_chunk;
        fseek(specfile, byte_offset, -1);
    end
end

