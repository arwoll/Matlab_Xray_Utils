% Calculation of asbolute intensities from Pt and Bi. Includes detector
% solid angle, incident beam intensity and energy.

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
% assumes globals "ele" and "n" from elamdb
t_pyro = 1e-7;   % cm


det_A = 9;     % mm^2
det_dist = 150; % mm
solid_angle = det_A / (4*pi*det_dist^2);
I0 = 3e10;  % photons/sec

E0 = 13.65; 

Elow = 8; Ehigh = 13.5;
delta_E = .02;
E = Elow : delta_E : Ehigh;
I1_cont = zeros(size(E));
I2_cont = I1_cont; 

Efwhm = 0.2;  % keV
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

I1_cont = I0*solid_angle*conv(I1_cont, Eres, 'same')*e1_rho*t_pyro;
I2_cont = I0*solid_angle*conv(I2_cont, Eres, 'same')*e2_rho*t_pyro;

pd1 = find_peak(E', I1_cont');
pd2 = find_peak(E', I2_cont');


plot(E, I1_cont, 'r-', E, I2_cont, 'k-', 'linewidth', 1.5)
xlabel 'Energy (keV)'
ylabel 'Intensity (absolute)'
legend({[ele(e1).sym ': ' num2str(pd1.counts, '%.0f') ' cts at ' num2str(pd1.com, '%.2f')], ...
    [ele(e2).sym ': ' num2str(pd2.counts, '%.0f') ' cts at ' num2str(pd2.com, '%.2f')]})
text(.02, .8, sprintf('E_0 = %.2fkeV', E0), 'Units', 'Normalized')
axis([Elow Ehigh 0 max([max(I1_cont) max(I2_cont)])])

%title_str = ['Absolute Intensity calc, I0 = ' num2str(I0, '%g') 'ph/sec, t_{eff} = ' num2str(t_pyro*1e7, 'g') 'nm'];
title([['Absolute Intensity calc, I0 = ' num2str(I0, '%g') ' ph/sec, '] ...
    num2str(t_pyro*1e7, '%g') 'nm Pyrochlore'])
