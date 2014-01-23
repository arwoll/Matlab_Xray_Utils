function profile = debye(a, q)
% debye(a, q) returns the functional part of the fourier transform of a
% sphere. q is antipiated to be a 1D array of values
profile = 3*(sin(a*q)-a*q.*(cos(a*q)))./(a*q).^3;