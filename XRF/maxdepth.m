function y = maxdepth(wd, dia, theta)
%function y = maxdepth(wd, dia, theta)
%
% Returns the maximum scan depth in confocal XRF, given the working distance (wd),
% polycapillary diameter (dia), and the angle between the surface and polycapillary
% (in degrees)
r = dia/2.0;
phi = atan(r/wd);
surface_to_corner = wd/cos(phi);
th = theta*pi/180.0;
elev = th-phi;

y = surface_to_corner*sin(elev);
