function rois  = calc_yieldres(rois_in, labels, norm_val)
% rois_in : roi structure array generated from mcaview
% labels : element labels to act on, e.g. {'Ti', 'Cu'}
% norm_val : value to multiply to rois_in.y

[Es, IX] = sort([rois_in.e_com]);
rois = rois_in(IX);
if ~isfield(rois, 'y_norm')
    rois(1).y_norm = [];
end
if ~isfield(rois, 'y_fwhm')
    rois(1).y_fwhm = [];
end
if ~isfield(rois, 'y_mx')
    rois(1).y_mx = [];
end
if ~isfield(rois, 'E')
    rois(1).E = [];
end

for ele = labels
    indices = strcmp({rois.sym}, ele);
    if ~any(indices)
        continue
    end
    for index = find(indices)
        rois(index).y_norm = rois(index).y*norm_val;
        pd = find_peak(rois(index).x, rois(index).y_norm);
        rois(index).y_fwhm = pd.fwhm;
        rois(index).y_mx = max(rois(index).y_norm);
        rois(index).E = rois(index).e_com;
    end
end