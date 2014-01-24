function agbe_ecal(file, scann, ctr, varargin)
% Calibrate energy from a GID scan of si powder. Input is the spec data
% file, scan number, and a guess for the energy. Routine refines the peak
% positions and re-calculates the best-fit energy. The scan is assumed to
% include the 111, 220-, and 311 peaks -- from 20 to 55 degrees in nu at
% 8.6 keV
%
% Usage : 
% 1) si_ecal_v3(file, scann, ctr)   : interprets file as either a scandata
%   structure (from gidview) or spec structure (from openspec), and scann as
%   the guess for the energy in keV
%
% 2) si_ecal_v3(file, scann, ctr, E_guess) : 
%    file = spec data file
%    scann = scan number
%    E_guess = best guess for incident energy

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
    fprintf('agbe_ecal : Failed to interpret input parameters\n');
    return
end

if ~strcmp(s.mot1, 'nu')
    fprintf('agbe_ecal works for nu scans only\n');
    return
end

% dircol = find(strcmp(s.headers, 'dir'));
if ischar(ctr)
    dir = double(s.data(strcmp(s.headers, ctr), :));
else
    dir = double(sum(s.mcadata(ctr, :), 1));
end
nu = abs(double(s.data(1,:)));

a = 58.38;
calc_d = @(h,k,l) a/sqrt(h^2 + k^2 + l^2);
ds = [calc_d(1,0,0) calc_d(2, 0, 0) calc_d(3,0,0)]';
% si_ds = [calc_d(1,1,1) calc_d(2, 2, 0)]';

nus = 180/pi*2*asin(12.4./(E_guess*2*ds));
com = zeros(length(nus), 1);
for k=1:length(ds)
    ranges{k} = find((nu>nus(k)-1) .* (nu<nus(k)+1));
    pd(k) = find_peak(nu(ranges{k})', dir(ranges{k})', ...
        'back', [1 length(ranges{k})]);
    com(k) = pd(k).com;
end

yr = [0 max(dir)];

figure(3); clf
plot(nu, dir, [com(1) com(1)], yr, 'r--', ...
    [com(2) com(2)], yr, 'r--', ...
    [com(3) com(3)], yr, 'r--')

% plot(nu, dir, [com(1) com(1)], yr, 'r--', ...
%     [com(2) com(2)], yr, 'r--')

%nus = [26.4292 43.8525 51.9369]';
y = sind(com/2);
x = 1./(2*ds);
lm3 = fit(x, y, 'poly1');
figure(2);
plot(x, y, 'bo', x, lm3(x), 'r-');

fprintf('Best fit E = %f\n', 12.4/lm3.p1);

