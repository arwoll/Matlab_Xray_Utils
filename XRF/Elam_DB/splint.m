function y=splint(inputs,x)
% Splint  function ported from Numerical recipes fortran code to Matlab.
% Numerical Recipes, 1986, p. 89
%
% inputs: A 2D matrix with:
%         column 1: logarithm of tabulated Energies (eV)
%         column 2: 1st spline parameter (value)
%         column 3: 2nd spline parameter (2nd derivative I think)
%
% x: log of the energy (eV) at which you want to know the cross-section
%
% y: the log of the spline-interpolated value at x.
% 
% Here is an example call to splint with tabulated atomic cross sections
% from the data in the Elam database:
%
% log_sigma = splint(ele(element).photo(:,1:3), log_E0);
% 
% exp(log_sigma) is the photo-absorption cross-section in cm^2/gm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 
% These lines are close to original code, but painful due to the integer
% operations
% klo=1;
% khi=length(xa);
% 
% while ((khi-klo)>1)
%     k=double(int16((khi-klo)/2))
%     if xa(k)>x
%         khi=k;
%     else
%         klo=k;
%     end
% end

xa = inputs(:,1);
ya = inputs(:,2);
y2a = inputs(:,3);

% This is the Matlab way to do the above...
klo = find(xa<x);
klo = klo(end);
khi = find(xa>x, 1);

h=xa(khi)-xa(klo);
if h == 0
    fprintf ('bad xa input\n') 
    return
end
a=(xa(khi)-x)/h;
b=(x-xa(klo))/h;
y=a*ya(klo)+b*ya(khi)+...
    ((a^3-a)*y2a(klo)+(b^3-b)*y2a(khi))*(h^2)/6;