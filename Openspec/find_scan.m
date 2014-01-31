function [scanline, scan_mark, motor_mark] = ffind_scan(specfile, scann)
% [scanline, scan_mark, motor_mark] = find_scan(specfile, scan)
% Assumes specfile is alredy open. Makes no noise if the scan is not found, but
% returns scanline = -1.  
%
% scan_mark and motor_mark are the file position of the scan and (neareast preceding)
% motor position lines, respectively.
%
% In textscan, the format spec %[^\n] reads all characters other than newline (none
% of which are present since find_line strips them from scanline).
scanline = '';
scan_mark = -1;
motor_mark = -1;

lfchar = sprintf('\n');
MAX_SCANN_LEN = 20;

% The leading '*' directs the output data type, the following *1 ensures
% single-byte characters.
A = fread(specfile, inf, '*char*1')';

scan_marks = strfind(A, '#S');
motor_marks = strfind(A, '#O0');
endoflines = strfind(A, lfchar);

nscans = numel(scan_marks);
scans = zeros(nscans, 1);

% Note that this could be faster by kicking out after the scan number is
% found. I leave it in to anticipate being able to handle multiple
% occurances of the same scan number.
for k=1:nscans
    firstchar = scan_marks(k)+2;
    lastchar = firstchar+MAX_SCANN_LEN;
    scans(k)= str2double(strtok( A(firstchar:lastchar) ));
end

matches = scan_marks(scann == scans);
if isempty(matches)
    %fprintf('Scan %d not found\n', scann);
    return
elseif numel(matches) > 1
    fprintf('Warning: Using 1st of %d distinct scans with scan number %d\n', ...
        numel(matches), scann);
    scan_mark = mathces(1)-1;
else
    scan_mark = matches-1;
end
if ~isempty(motor_marks)
    motor_mark = motor_marks(find(motor_marks < scan_mark, 1, 'last')) - 1;
end
next_eol = endoflines(find(endoflines > scan_mark, 1, 'first'));
foo = textscan(A(scan_mark+3:next_eol), '%*d %[^\n]');
scanline = foo{1}{1};
