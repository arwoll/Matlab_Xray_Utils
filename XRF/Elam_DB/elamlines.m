function [Line_Energies Line_Intensities]=spec(element,kev)

global n ele

alledges=length(ele(element).edge);

if alledges == 1 return
end

Line_Energies = [ ];
Line_IntYields = [ ];
skev=log(kev*1000);

for ln=1:alledges
    if ele(element).edge(ln).e/1000<kev && isstruct(ele(element).edge(ln).lines)
        LE=[ele(element).edge(ln).lines.e]/1000;
        LI=[ele(element).edge(ln).lines.i];
        Yield=[ele(element).edge(ln).yield]*LI;
        Line_Energies=[Line_Energies LE];
        Line_IntYields=[Line_IntYields Yield];    
    end
end

abs=splint(ele(element).photo(:,1:3),skev);
absorbance=exp(abs);
Line_Intensities=[Line_IntYields]*absorbance