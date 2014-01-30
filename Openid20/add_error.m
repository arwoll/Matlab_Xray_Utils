function error = add_error(error, code, msg)
% function error = add_error(error, code, msg)
%
% Motivation: Allows new errors to be added to the error array without
% losing information about previous non-fatal errors.
%
% If length(error) == 1 and error.code = 0, then the new error replaces the
% existing error. Otherwise the new error is added to the end of the error
% array. Specifcally code -> error(last+1).code = code and msg ->
% error(last+1).msg
%
if length(error) == 1 && error.code == 0
    error.code = code;
    error.msg = msg;
else
    error(end+1).code = code;
    error(end).msg = msg;
end