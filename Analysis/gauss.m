function y = gauss(pars, X)
% function y = gauss(pars, X)
%   pars(1) : X0
%   pars(2) : FWHM
% Returns a normalized gaussian function centered on pars(1) and with full-width
% at half maximum pars(2). (FWHM = 2.35482*sigma. A guassian is typically
% defined exp(-0.5*(x/sigma)^2), sigma is the second moment of the
% disttibution.
X0 = pars(1);
sigma = pars(2)/2.35482;
y = 1.0/(sigma*sqrt(2*pi))*exp(-0.5*((X-X0)/sigma).^2);
% 
% FWHM_TO_SIGMA = 2.35482;
% area = pars(1);bk = pars(2); cen=pars(3); fwhm=pars(4);  
% sigma = fwhm/FWHM_TO_SIGMA;
% 
% %y = 1.0/(sigma*sqrt(2*pi))*exp(-0.5*((X-cen)/sigma).^2);
% 
% prefactor = area/(sigma*sqrt(2*pi));
% exponential = exp(-0.5*((xdata-cen)/sigma).^2);
% y=bk+prefactor*exponential;
% if nargout > 1
%     J = zeros(length(xdata),length(pars));
%     J(:,3) = prefactor*(xdata-cen)./sigma^2.*exponential;
%     J(:,1) = 1/(sigma*sqrt(2*pi))*exponential;
%     J(:,4) = 1/FWHM_TO_SIGMA*prefactor*exponential.*( -1/sigma + (xdata-cen).^2/sigma^3);
%     J(:,2) = ones(1, length(xdata));
% end
% if nargin > 2
%     y = y.* wts;
%     if nargout > 1
%             J=J.*[wts wts wts wts];
%     end