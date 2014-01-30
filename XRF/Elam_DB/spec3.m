function [M_Energies M_Lines]=spec3(elements, densities, kev)

global n ele

M_Energies = [];
M_Lines = [];

for k=1:length(elements)
    [energy lines]=elamjumplines_v3(elements(k), kev);
    M_Energies=[M_Energies energy];
    M_Lines = [M_Lines lines*densities(k)];
end

%bar(M_Energies, M_Lines);
%xlabel('KeV')
%ylabel('intensity')