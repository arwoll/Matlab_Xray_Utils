function result = newer(file1, file2)
% function result = newer(file1, file2)
%   Returns true only if file1 and file2 both exist, and file1 is newer
%   than file2
    if exist(file1) && exist(file2)
        file1dir = dir(file1); 
        file2dir = dir(file2);
        result = datenum(file1dir.date)>datenum(file2dir.date);
    else
        result = 0
    end