function remainder = find_id20_mdaline(mdafile, line_id_str)
% function remainder = find_id20_mdaline(mdafile, line_id_str) Searches a
% pre-opened textfile, fid=mdafile, for a line beginning with '#' and which
% contains line_id_str, returning the line minus the leading #.  If
% line_id_str is empty, just find the next line with #.
%
% The main use of the fancy additions is in find_scan, internal to
% openspec, where we want to find the desired scan, but also flag
% changes in the motor configuration. 
%
% Assumes mdafile is already open

remainder = -1;

% The following textscan format string gives foo{1} the first token, foo{2} the
% remainder of the line, and foo{3} the newline(s) (>1 if the following line is
% empty). This seemed to result in at least a factor of three speedup from the
% superceded version which used fgetl.  (Obviously, it's still not as fast as using
% an index file ala spec.)
%SCAN_STR = '%[^\n]';
foo = fgetl(mdafile);
%  foo = textscan(mdafile, SCAN_STR, 1);

if ~isempty(line_id_str)
    while ischar(foo) && ((~isempty(foo) && foo(1) ~= '#') || isempty(strfind(foo, line_id_str)))
        foo = fgetl(mdafile);
    end
    if ~ischar(foo)
        return
    end
    beg = strfind(foo, line_id_str)+length(line_id_str);
else
    beg = 1;
end
if ischar(foo)
    remainder = strtrim(foo(beg:end));
end
