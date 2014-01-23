function set_line_props(handle, varargin)
% function set_line_props(handle, varargin)
% Given an arbitrary number of line-property pairs, sets those properties
% for all children of a particular axes object

alllines = findall(handle, 'Type', 'line');
for k = 1:2:nargin-1
    set(alllines, varargin{k}, varargin{k+1});
end