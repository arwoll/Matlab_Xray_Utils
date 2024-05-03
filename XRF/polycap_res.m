function y = polycap_res(parms, energy)
% Explicit model for polycapillary resolution function.  The idea is that
% its resolution is proportional to critical angle, or inversely proportional
% to energy.  This means it will diverge at 0.  To control where that
% divergence happens, we have a parameter b...
a = parms(1);
b = parms(2);
y = (10.0+b)*a./(energy+b);