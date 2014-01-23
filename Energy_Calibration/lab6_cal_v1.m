function varargout = lab6_cal_v1(file, scann, ctr, varargin)
% Calibrate energy from a GID scan of si powder. Input is the spec data
% file, scan number, and a guess for the energy. Routine refines the peak
% positions and re-calculates the best-fit energy. The scan is assumed to
% include the 111, 220-, and 311 peaks -- from 20 to 55 degrees in nu at
% 8.6 keV
%
% Usage : 
% 1) si_ecal_v4(file, scann, ctr)   : interprets file as either a scandata
%   structure (from gidview) or spec structure (from openspec), and scann as
%   the guess for the energy in keV
%
% 2) si_ecal_v4(file, scann, ctr, E_guess) : 
%    file = spec data file
%    scann = scan number
%    E_guess = best guess for incident energy
%
% 3) pd = si_ecal_v4(...) : Output the peak data for each found peak

if ischar(file) && nargin==4
   s = openspec(file, scann);
   E_guess = varargin{1};
elseif isstruct(file) && nargin == 3
    if isfield(file, 'spec')
        s = file.spec;
    else
        s = file;
    end
    E_guess = ctr;
    ctr = scann;
else
    fprintf('lab6_cal_v1: Failed to interpret input parameters\n');
    return
end

if ~strcmp(s.mot1, 'del') && ~strcmp(s.mot1, 'tth')
    fprintf('lab6_cal_v1: works for del or tth scans only\n');
    return
end

% dircol = find(strcmp(s.headers, 'dir'));
if ischar(ctr)
    dir = double(s.data(strcmp(s.headers, ctr), :));
else
    dir = double(sum(s.mcadata(ctr, :), 1));
end
del = double(s.data(1,:));

pks = [1 1 1;
    2 0 0;
    2 1 0;
    2 1 1;
    2 2 0;
    3 0 0;
    3 1 0;
    3 1 1;
    2 2 2;
    3 2 0;
    3 2 1;
    4 0 0;
    3 2 2;
    4 1 1;
    3 3 1;
    4 2 0;
    4 2 1;
    3 3 2;
    5 0 0;
    4 3 1;
    3 3 3];

a_lab6 = 4.157;

d_cub = @(a, hkl) a/sqrt(hkl(1)^2 + hkl(2)^2 + hkl(3)^2);
ds = zeros(size(pks, 1), 1);
tth = ds;
for k = 1:size(pks, 1)
    ds(k) = d_cub(a_lab6,pks(k,:));
    tth(k) = 180/pi*2*asin(12.4./(E_guess*2*ds(k)));
end

com = zeros(length(tth), 1);
for k=1:length(ds)
    ranges{k} = (del>tth(k)-1) & (del<tth(k)+1);
    pd(k) = find_peak(del(ranges{k})', dir(ranges{k})');
    com(k) = pd(k).com;
end

yr = [0 max(dir)];

figure(3); clf
subplot(2,1,1)
plot(del, dir);
hold all
for k = 1:length(ds)
    plot([com(k) com(k)], yr, 'r--')
end
title 'LaB6 PXRD'
xlabel 'delta aka tth'
axis tight

y = sind(com/2);
x = 1./(2*ds);
lm3 = fit(x, y, 'poly1');
lambda = lm3.p1; E = 12.4/lambda;
y_calc = lm3(x);
subplot(2,1,2)
plot(x, y, 'bo', x, y_calc, 'r-');

title(['Slope = lambda = ', num2str(lambda), ' Ang, E = ',num2str(E), ' keV' ]) 
xlabel '1/2d'
ylabel 'sin(tth/2)'
fprintf('Best fit E = %f\n', 12.4/lambda);

tth_err = 2*asin(y_calc) - 2*asin(y);

if nargout >0 
    varargout{1} = pd;
end
if nargout > 1
    varargout{2} = [tth, tth_err];
end

