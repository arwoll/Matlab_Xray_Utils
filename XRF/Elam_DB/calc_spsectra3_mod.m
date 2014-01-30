% Calculation of asbolute intensities from Pt and Bi. Includes detector
% solid angle, incident beam intensity and energy.
%%Incidence Beam & Geo

theta_inc = 2;

det_A = 9;     % mm^2
det_dist = 150; % mm
solid_angle = det_A / (4*pi*det_dist^2);

I0 = 3e10;  % photons/sec

E0 = 13.8; 


%% With mods specifically for Pt2Bi2O7 Pyrochlore
rho_pyro = 10.96; % g/cm3
e1 = n.Bi;
e2 = n.Pt;
e3 = n.O;
pt_frac = 2*ele(n.Pt).mw/(2*ele(n.Pt).mw + 2*ele(n.Bi).mw + 7*ele(n.O).mw);
bi_frac = 2*ele(n.Bi).mw/(2*ele(n.Pt).mw + 2*ele(n.Bi).mw + 7*ele(n.O).mw);

e1_rho = rho_pyro*bi_frac;
e2_rho = rho_pyro*pt_frac;

%%
figure(1);
% assumes globals "ele" and "n" from elamdb
t_pyro = 100e-7;   % cm

Elow = 8; Ehigh = 13.5;
delta_E = .01;
E = Elow : delta_E : Ehigh;
I1_cont = zeros(size(E));
I2_cont = I1_cont; 

Efwhm = 0.3;  % keV
Eres = gauss([0 Efwhm], (-3*Efwhm  :delta_E :3*Efwhm ));

[E1_dis, I1_dis] = elamjumplines_v3(e1, E0);
[E2_dis, I2_dis] = elamjumplines_v3(e2, E0);

[E1_dis, ord] = sort(E1_dis); I1_dis = I1_dis(ord);
[E2_dis, ord] = sort(E2_dis); I2_dis = I2_dis(ord);

first = find(E1_dis>Elow, 1);
for k = first:length(E1_dis)
    bin = find(E>E1_dis(k), 1);
    I1_cont(bin) = I1_cont(bin) + I1_dis(k);
end

first = find(E2_dis>Elow, 1);
for k = first:length(E2_dis)
    bin = find(E > E2_dis(k), 1);
    I2_cont(bin) = I2_cont(bin) + I2_dis(k);
end

I1_cont = delta_E*I0*solid_angle*conv(I1_cont, Eres, 'same')*e1_rho*t_pyro/sind(theta_inc);
I2_cont = delta_E*I0*solid_angle*conv(I2_cont, Eres, 'same')*e2_rho*t_pyro/sind(theta_inc);

pd1 = find_peak(E', I1_cont');
pd2 = find_peak(E', I2_cont');

fwhm = pd1.wr-pd1.wl; ch_com = round(pd1.ch_com);
pk_ind = ch_com-fwhm : ch_com+fwhm;
pd1_pk = find_peak(E(pk_ind)', I1_cont(pk_ind)');

fwhm = pd2.wr-pd2.wl; ch_com = round(pd2.ch_com);
pk_ind = ch_com-fwhm : ch_com+fwhm;
pd2_pk = find_peak(E(pk_ind)', I2_cont(pk_ind)');

plot(E, I1_cont, 'r-', E, I2_cont, 'k--', 'linewidth', 1.5)
xlabel 'Energy (keV)'
ylabel 'Intensity (absolute)'
legend({[ele(e1).sym ': ' num2str(pd1_pk.area/delta_E, '%.0f') ' cts at ' num2str(pd1.com, '%.2f')], ...
    [ele(e2).sym ': ' num2str(pd2_pk.area/delta_E, '%.0f') ' cts at ' num2str(pd2.com, '%.2f')]})
text(.02, .8, sprintf('E_0 = %.2fkeV\n{th}= %.0f', E0, theta_inc), 'Units', 'Normalized')
axis([Elow Ehigh 0 max([max(I1_cont) max(I2_cont)])])

title([['XRF Sim: I0 = ' num2str(I0, '%g') ' ph/s, '] ...
    num2str(t_pyro*1e7, '%g') 'nm Pt2Bi2O7'])
