%% bragg_calcs.m

fprintf('\n\nIn startup: defining get_tth(E[keV], d[Ang]), get_q(E, tth[deg]), \nget_d(E, tth) and get_E(tth, d)\n');
get_tth = @(E, d) 180/pi*2*asin(12.4./(E*2*d));
get_d = @(E, tth) 12.4/(E*2*sind(tth/2.0));
get_q = @(E, tth) 2*pi*E*2*sind(tth/2.0)/12.4;
get_E = @(tth, d) 12.4./(2*d*sind(tth/2.0));
get_tth_q = @(E, q) 180/pi * 2*asin(q * 12.4/ (4*pi*E));

