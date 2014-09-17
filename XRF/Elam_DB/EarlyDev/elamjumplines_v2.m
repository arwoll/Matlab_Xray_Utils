function [Line_Energies Line_Intensities]=elamjumplinesVERSTWO(element,kev)
%for given incoming kev, outputs line inergies and intensities 
%as calculated with fluorescence yield and absorbance at a given kev, using data
%tabulated in Elam

global n ele

if element < 3 return
end

Line_Energies = [ ];
Line_IntYields = [ ];
Jumps = [ ];
Line_JumpYields = [ ];
skev=log(kev*1000);

alledges=find([ele(element).edge(1:end).e]<kev*1000);

for ln=alledges
    if isstruct(ele(element).edge(ln).lines)
       Jump=[ele(element).edge(ln).jump];
       Jumps=[Jumps Jump];
       Jumpstot=sum(Jumps)';
    end 
end

for ln=alledges
    if ele(element).edge(ln).e/1000<kev && isstruct(ele(element).edge(ln).lines)
        LE=[ele(element).edge(ln).lines.e]/1000;
        LI=[ele(element).edge(ln).lines.i];
        Yield=[ele(element).edge(ln).yield]*LI;
        Jumpper=[ele(element).edge(ln).jump]/Jumpstot;
        JumpYield=[Yield]*Jumpper;
        Line_Energies=[Line_Energies LE];
        Line_JumpYields=[Line_JumpYields JumpYield];
     end
end

abs=splint(ele(element).photo(:,1:3),skev);
absorbance=exp(abs);
Line_Intensities=[Line_JumpYields]*absorbance;