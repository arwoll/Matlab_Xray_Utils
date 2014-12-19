% Calculation of asbolute intensities from Pt and Bi. Includes detector
% solid angle, incident beam intensity and energy.

theta_inc = 2;

det_A = 9;     % mm^2
det_dist = 150; % mm
solid_angle = det_A / (4*pi*det_dist^2);

I0 = 3e10;  % photons/sec

E0 = 13.8; 

%% With mods specifically for Pt2Bi2O7 Pyrochlore
rho_hf02 = 9.68; % g/cm3
e1 = n.Hf;
hf_frac = ele(n.Hf).mw/(ele(n.Hf).mw + 2*ele(n.O).mw);

e1_rho = rho_hf02*hf_frac;

%%
figure(2)
% assumes globals "ele" and "n" from elamdb
t_hf0 = 45e-7;   % cm



Elow = 7; Ehigh = E0+.5;
delta_E = .01;
E = Elow : delta_E : Ehigh;
I1_cont = zeros(size(E));

Efwhm = 0.2;  % keV
Eres = gauss([0 Efwhm], (-3*Efwhm  :delta_E :3*Efwhm ));

[E1_dis, I1_dis] = elamjumplines_v3(e1, E0);
[E1_dis, ord] = sort(E1_dis); I1_dis = I1_dis(ord);

first = find(E1_dis>Elow, 1);
for k = first:length(E1_dis)
    bin = find(E>E1_dis(k), 1);
    I1_cont(bin) = I1_cont(bin) + I1_dis(k);
end

I1_dis = I0*solid_angle*I1_dis*e1_rho*t_hf0/sind(theta_inc);
I1_cont = delta_E*I0*solid_angle*conv(I1_cont, Eres, 'same')*e1_rho*t_hf0/sind(theta_inc);

pd1 = find_peak(E', I1_cont');

fwhm = pd1.wr-pd1.wl; ch_com = round(pd1.ch_com);
pk_ind = ch_com-fwhm : ch_com+fwhm;
pd1_pk = find_peak(E(pk_ind)', I1_cont(pk_ind)');

plot(E, I1_cont, 'r-', 'linewidth', 1.5)
xlabel 'Energy (keV)'
ylabel 'Intensity (absolute)'
legend({[ele(e1).sym ': ' num2str(pd1_pk.area/delta_E, '%.0f') ' cts at ' num2str(pd1.com, '%.2f')]})
text(.02, .8, sprintf('E_0 = %.2fkeV\n{th}= %.0f', E0, theta_inc), 'Units', 'Normalized')
axis([Elow Ehigh 0 max(I1_cont)])

title([['XRF Sim: I0 = ' num2str(I0, '%g') ' ph/sec, '] ...
    num2str(t_hf0*1e7, '%g') 'nm HfO2'])
