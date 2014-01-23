function y = kT(tempC)
% function y = kT(tempC)
%   converts temperature (in deg C) to kT, for ease in evaluating rates...
y = (tempC+273.15)*0.025/300;