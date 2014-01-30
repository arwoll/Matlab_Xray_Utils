function [textline, varargout] = find_line(specfile, headstr)
% function [textline, [index, file_position]] = find_line(specfile, headstr)
% Searches a pre-opened textfile, fid=specfile, for a line whos first token
% matches any string in the string or cell array headstr, returning
% the remainder of that line.  If the optional 2nd and third arguments
% are given, also returns the index of the element in headstr which matched and 
% the file position of the line which matched.
%
% The main use of the fancy additions is in find_scan, internal to
% openspec, where we want to find the desired scan, but also flag
% changes in the motor configuration. 
%
% Assumes specfile is already open

textline = -1;
if nargout == 3
    varargout{1} = [];
    varargout{2} = [];
end

% The following textscan format string gives foo{1} the first token, foo{2} the
% remainder of the line, and foo{3} the newline(s) (>1 if the following line is
% empty). This seemed to result in at least a factor of three speedup from the
% superceded version which used fgetl.  (Obviously, it's still not as fast as using
% an index file ala spec.)
SCAN_STR = '%s%[^\n]%[\n]';
mark = ftell(specfile);
[foo, next_mark] = textscan(specfile, SCAN_STR, 1); 
while ~isempty(foo) && ~any(strcmp(foo{1}, headstr))
    mark = next_mark;
    [foo, next_mark] = textscan(specfile, SCAN_STR, 1);
end
if ~isempty(foo)
    if length(foo)>1
        textline = char(foo{2});
    end
    if nargout == 3
        varargout{1} = find(strcmp(foo{1}, headstr));
        varargout{2} = mark;
    end
end
