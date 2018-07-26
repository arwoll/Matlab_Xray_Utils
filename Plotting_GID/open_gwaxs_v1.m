function [rect_qpar, rect_qperp, rect_z] = open_gwaxs_v1(specfile,scann, ptn, E, varargin)
% function make_gidplot_v1(matfile, E, varargin) 
%   if present, varargin must be a 2-value vector with intensity ranges to
%   user for the plot

% Newest version of openmca in gidview as of Dec 2010 incorporates Delta
% value into Ecal...
Beamy = 959;
Beamx = 127;
D_sam_det = 129.2316;
D_pix = 0.07113;
DETSIZE = [1024 1024];
delta_q = [];

i1norm = [];

delrange = [.05 360];

nvarargin = nargin - 4;
for k = 1:2:nvarargin
    switch varargin{k}
        case 'i1norm'
            i1norm = varargin{k+1};
        case 'delta_q'
            delta_q = varargin{k+1};
        case 'delrange'
            if length(varargin{k+1}) ~= 2
               warndlg('if present, delrange is an ordered, two-element array -- ignored');
            end
            delrange = sort(varargin{k+1});
        otherwise
            warndlg(sprintf('Unrecognized variable %s',varargin{k}));
    end
end

specd = openspec(['raw/' specfile], scann);
if specd.npts > 1 % multiple explosures -- obtained with ascan, etc
    if ~strcmp(specd.mot1, 'samth')
        fprintf('Oops -- open_gwaxs_v1 only works with a samth scans and corr\n')
        exit
    end
    imfilename = sprintf('%s_%03d_%03d_c.tif', specfile, scann, ptn);
    normcts = double(specd.data(find(strcmp(specd.headers, 'I1'), 1, 'first'), ptn));
    alpha = double(specd.var1(ptn)); 
else % single exposures -- obtained with corr N t
    imfilename = sprintf('%s_%03d_c.tif', specfile, scann);
    alpha = double(specd.motor_positions(strcmpi(specd.motor_names, 'samth')));
    normcts = double(specd.data(find(strcmp(specd.headers, 'I1'), 1, 'first'), 1));
end

im = imread(['raw/Corrected/' imfilename]);


pxn = (1:1024)';
h = (Beamy - pxn) * D_pix;
x = (pxn - Beamx) * D_pix;
del = atand(h/D_sam_det);
del_select = del > delrange(1) & del < delrange(2);
del = repmat(del(del_select), 1, DETSIZE(2));
DETSIZE(1) = size(del, 1);
nu = repmat(atand(x'/D_sam_det), DETSIZE(1), 1);


k = 2*pi*E/12.39842;

beta = del - alpha;

cosnu = cosd(nu);
cosb = cosd(beta);
cosa = cosd(alpha);
sina = sind(alpha);

q_par = k*(2*(nu>=0)-1).*sqrt(cosa^2 + cosb.^2 - 2*cosa*cosb.*cosnu);
q_perp = k*(sina + sind(beta));

% delta sub-range must be used here
z = double(im(del_select, :, :));

%%
min_qpar = min(q_par(:));
max_qpar = max(q_par(:));
min_qperp = min(q_perp(:));
max_qperp = max(q_perp(:));
max_qpar_size = max(max(diff(q_par, 1,2)));
max_qperp_size = max(max(abs(diff(q_perp, 1,1))));

if ~isempty(delta_q)
    max_qpar_size = delta_q;
    max_qperp_size = delta_q;
end

if isempty(i1norm)
    i1norm = mean(normcts);
end
norm_ic = i1norm./ normcts;

rect_qpar = min_qpar - max_qpar_size/2.0 : max_qpar_size : max_qpar + max_qpar_size/2.0 ; 
rect_qperp = min_qperp -max_qperp_size/2.0: max_qperp_size : max_qperp + max_qperp_size/2.0;
[rect_z, norm_remap] = curve_to_rect(q_par', q_perp', z', rect_qpar, rect_qperp);
norm_remap(rect_z == 0) = 1.0;
rect_z = rect_z'./norm_remap' * norm_ic;


