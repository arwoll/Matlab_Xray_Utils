E0 = 15; 

Elow = 8; Ehigh = 16;
delta_E = .02;
E = Elow : delta_E : Ehigh;
Imc = zeros(size(E));
Ipc = Imc; 

Efwhm = 0.3;  % keV
Eres = gauss([0 Efwhm], (-3*Efwhm  :delta_E :3*Efwhm ));

[Em, Im] = elamjumplines_v3(n.Hg, E0);
[Ep, Ip] = elamjumplines_v3(n.Pb, E0);

[Em, ord] = sort(Em); Im = Im(ord);
[Ep, ord] = sort(Ep); Ip = Ip(ord);

first = find(Em>Elow, 1);
for k = first:length(Em)
    bin = find(E>Em(k), 1);
    Imc(bin) = Imc(bin) + Im(k);
end

first = find(Ep>Elow, 1);
for k = first:length(Ep)
    bin = find(E > Ep(k), 1);
    Ipc(bin) = Ipc(bin) + Ip(k);
end

Ihg = conv(Imc, Eres, 'same');
Ipb = conv(Ipc, Eres, 'same');

plot(E, Ihg, 'r-', E, Ipb, 'k-', 'linewidth', 1.5)
xlabel 'Energy'
ylabel 'Intensity (relative)'
legend( {'Hg', 'Pb'})
text(8.2, 62, sprintf('E_0 = %2.0fkeV', E0))
axis([Elow Ehigh 0 70])