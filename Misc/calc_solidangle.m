function sig = calc_solidangle(A, D)
%function sig = calc_solidangle(area, distance)
% Returns the fractional solid angle subtended by an object with area A a
% distance D from a source. Assumes a circular disk area A
theta = atan(sqrt(A/pi) ./ D);
sig = (1 - cos(theta))/2;


