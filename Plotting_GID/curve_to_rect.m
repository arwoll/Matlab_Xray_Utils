function [rtz, norm, varargout] = curve_to_rect(q_par, q_perp, cvz, rect_qpar, rect_qperp)
%function [rtz, norm] = curve_to_rect(q_par, q_perp, cvz, rect_qpar,rect_qperp)
%   Distributes counts from a curvilinear grid (cvz) - for example x-ray data collected
%   in angular space -  into a rectilinear grid -- e.g. reciprocal space. 
%
%           q_par, q_perp, and cvz are M x N MATRICES
%           q_par, q_perp represent the Q coordinates of the CENTER of
%           pixels whose intensities are stored in cvz. 
%           rect_qpar and rect_qperp are monotonically increasing, 
%                   equal-spaced VECTORS determining the new grid
%
%           Optional output arguments xmap, ymap are the matrices of
%           locations of cvz in pixel units of the new grid. 
%           I used these as a check. 
%
%           NOTE: Since xwid is calculated as xmap(i+1,j) - xmap(i,j), then
%           this difference should be non-zero. THIS will only be true if
%           the first index of q_par is varying. Likewize, values should
%           vary more quickly along the 2nd index of q_perp. As of Jan
%           2014, this means that q_par, q_perp, and cvz are the transpose
%           of the outputs from open_gid_v4, since the 1D diode array
%           pixels are loaded into a single column.
%
%           NOTE TOO: when calling, say, imagesc(x,y,z), the "x" range maps
%           to the 2ND, not first index of z. This is because matrices are
%           stored in column format, and are plotted to correspond to how
%           they are visualized in memory - with the 1st index increasing
%           vertically downward. The result is that the output argument of
%           this function, rtz, whose first index corresponds to increasing
%           values of rect_qpar, should be transposed before plotting, so
%           that the 2ND index will correspond to rect_qpar in the command:
%               >>imagesc(rect_qpar, rect_qperp, rtz') or 
%               >>imagesc(rect_qpar,rect_qperp, log(rtz'./norm'+1))
%
%           WARNING: The algorithm implicitly assumes that largest source
%           pixel is no larger than TWO destination pixels in either linear
%           dimension. In other words, destination pixels should err on the
%           side of being too large, rather than too small.
%
%   Algorithm:
%       Step 1 : Compute xmap, ymap, which containt the values of q_par and q_perp, but
%                represented in pixel units of the target coordinates
%                rect_qpar, rect_qperp. In other words, xmap(i,j) = 3.4
%                means that q_par(i,j) lands 2/5 of the q_distance between
%                rect_qpar(3) and rect_qpar(4).
%       Step 2 : Use the procedure described by Barna et al (RSI v.70
%                p. 2927, 1999) to distribute intensity from each source
%                pixel i,j into each of 9 destination pixels around the
%                xmap(i,j) and ymap(i,j). Keep track of how
%                many source "pixels" are placed into each bin in the
%                variable, "norm".   Note also that if
%                xmap(i,j)-floor(xmap(i,j)) > 0.5, the "center" pixel of
%                the 9 destination pixels is floor(xmap+0.5).
%
%       (Outside this function): The normalized intensity in each new pixel
%                can be obtained asI = rtz./norm, but with the caveat that
%                zero values of "norm" should be changed to ones first,
%                norm(rtz == 0) = 1.0;
%
%   Example: Beginning with q_par, q_perp, and z
%        min_qpar = min(q_par(:));
%        max_qpar = max(q_par(:));
%        min_qperp = min(q_perp(:));
%        max_qperp = max(q_perp(:));
%        max_qpar_size = max(max(diff(q_par, 1,2)));
%        max_qperp_size = max(max(abs(diff(q_perp, 1,1))));
%
%        rect_qpar = min_qpar - max_qpar_size/2.0 : max_qpar_size : max_qpar + max_qpar_size/2.0 ; 
%        rect_qperp = min_qperp -max_qperp_size/2.0: max_qperp_size : max_qperp + max_qperp_size/2.0;
%      
%        [rtz, norm] = curve_to_rect(q_par', q_perp', z', rect_qpar, rect_qperp);
%
%        norm(rtz == 0) = 1.0;
%        imagesc(rect_qpar, rect_qperp, log(rtz'./norm'+1)); 
%        axis xy
%
%        xlabel(['Q_{||} [' char(197) '^{-1}]'])
%        ylabel(['Q_{\perp} [' char(197) '^{-1}]'])

out_width = length(rect_qpar);
out_height = length(rect_qperp);
rtz = zeros(out_width, out_height);
norm = rtz;

dims = size(cvz);
if any(size(q_par)~= dims) || any(size(q_perp) ~= dims)
    error('input matrices are not identical in size')
end

width = dims(1); height = dims(2);

rect_width  = rect_qpar(2) - rect_qpar(1);
rect_height = rect_qperp(2)- rect_qperp(1);
rect_qpar_shift = rect_qpar - rect_width/2.0;
rect_qperp_shift = rect_qperp - rect_height/2.0;

xmap = zeros(size(cvz));
ymap = xmap;

for i = 1:width 
    for j = 1:height
        highpx_x = find(q_par(i,j) > rect_qpar_shift, 1);
        highpx_y = find(q_perp(i,j) > rect_qperp_shift, 1);
        if isempty(highpx_x) || isempty(highpx_y)
            error('q_par or q_perp out of range of rect_qpar or rect_qperp');
        end
        % An additional check would be that q_par(i,j) <
        % rect_qpar_shift(highpx_x+1) etc.
        xmap(i, j) = highpx_x - 0.5 + ...
            (q_par(i,j) - rect_qpar_shift(highpx_x))/rect_width;
        ymap(i, j) = highpx_y - 0.5 + ...
            (q_perp(i,j) - rect_qperp_shift(highpx_y))/rect_height;
    end
end

% x_cen = floor(xmap + 0.5);
% y_cen = floor(ymap + 0.5);

col = zeros(1,3); 
row = col;
for i = 1:width 
    for j = 1:height
        x = xmap(i, j);
        y = ymap(i, j);
        % The following is necessary so that comparison is always made to
        % the closest pixel. E.g. a pixel centered at 2.9 should be
        % distributed into pixels 2, 3, and 4; the center pixel is 3, not
        % 2.
        
        x1 = floor(x + 0.5);  
        y1 = floor(y + 0.5);
        
        % Note that the following step is where the indices of the input
        % are being linked to the indices of the output. Specifically it
        % will create overlap between the neighboring source pixels (i-1,
        % i, and i+1, j) into neighboring destination pixels (k-1,k,k+1,
        % m). Imagine that q_par does NOT vary along its first index. Then,
        % the calculation of xwid, which compares xmap(i, j) to
        % xmap(i-1,j), will be close  to zero, ruining the mixing below.
        
        if (i>1) 
            xwid = abs(x - xmap(i-1, j));
        else
            xwid = abs(xmap(i+1,j ) - x);
        end
        if (j>1)
            ywid = abs(y - ymap(i, j-1));
        else
            ywid = abs(ymap(i,j+1) - y);
        end
        
        % Unsure of following -- probably a catch for border or bad pixels
        if (ywid>5.0) || (xwid>5.0) 
            fprintf('Warning: Pixel (%d, %d) is over 5 wide or tall\n', i,j);
            xwid = 1.0; ywid = 1.0;
        end
        
        % Barna (1999() mistakenly writes these as "min" rather than "max" 
        col(1) = max(0.5 - (x - x1 + 0.5)/xwid, 0.0);
        col(3) = max(0.5 + (x - x1 - 0.5)/xwid, 0.0);
        col(2) = 1.0 - col(1) - col(3);
        row(1) = max(0.5 - (y - y1 + 0.5)/ywid, 0.0);
        row(3) = max(0.5 + (y - y1 - 0.5)/ywid, 0.0);
        row(2) = 1.0 - row(1) - row(3);
        
        for k = -1:1
            for m = -1:1
                if (x1+k > 0 && x1+k <= out_width)  && ...
                        (y1+m > 0 && y1+m <= out_height)
                    rtz(x1+k, y1+m)  = rtz(x1+k, y1+m)  + cvz(i,j)*col(k+2)*row(m+2);
                    norm(x1+k, y1+m) = norm(x1+k, y1+m) + col(k+2)*row(m+2);
                end
            end
        end

    end
end

if nargout > 2 && nargout == 4
   varargout{1} = xmap;
   varargout{2} = ymap;
end

end

