function a = afm_step_dens(imfile, height, imsize) 
%%% PLAN : load an afm image, call contour to find the total length of
%%% steps at a particular height -- the step density of a particular layer
%%% n. Return the effective area correction due to the step density times
%%% the afm_res, where afm_res is given as a percentage of the edge length
%%% of the image.
%%%
%%% imsize should be the length of the side of an image, in  microns


if ischar(imfile)
    a = imread(imfile);
else
    a = imfile;
end

% Assume a square image
px_size = imsize/size(a, 1);
afm_res = 0.005; 

maxa = 65535;

C = contourc(double(a),height*maxa * [1 1]); %spring09_g4_spot2

%%%%%%%%%% getting rid of unclosed contours

nclosed = 0;  unclosed = {}; nunclosed = 0;
polygons = {}; 

% Construct cell array from contour output: a 2xN array of vertices,
% in which the first column of each contour is the height of that contour
% and the number of vertices. For closed contours, x_N = x_1 and y_N = y_1
CONTOUR_LENGTH_THRESH = 30;
n = 1;
while n < size(C, 2)
    
    nvert = C(2,n);
    startxy = C(:,n+1);
    endxy = C(:,n+nvert);

    % Eliminate very small contours
    if nvert < CONTOUR_LENGTH_THRESH
        nunclosed = nunclosed + 1;
        unclosed{nunclosed} = C(:,n+1:n+nvert);
    else 
        nclosed = nclosed + 1;
        polygons{nclosed} = C(:,n+1:n+nvert);
    end
    n = n + nvert + 1;
end 

%%%%%%%%%%
%%%%%%%%% Calculate perimeter length (and area?)
%%%%%%%%%

polygons_seglen = zeros(length(polygons),1);
polygons_a = zeros(length(polygons),1);



figure(1);
imagesc(a)
colormap gray
hold on

for k = 1:length(polygons)
    h = plot(polygons{k}(1,:), polygons{k}(2,:),...
        'b-', 'linewidth', 1.3); p = polygons{k};
    
    pair_mean = (p(2,2:end)+p(2,1:(end-1)))/2;
    
    p_diff_x = diff(p(1,:));
    p_diff_y = diff(p(2,:));
    
    
    
    len_p = sum(sqrt(p_diff_y.^2 + p_diff_x.^2));

    polygons_seglen(k) = len_p;
    
    area_p = abs(sum(pair_mean .* p_diff_x));
    
    polygons_a(k) = area_p;
    set(h, 'Color', [1 0 0]);
end


len_p_real = sum(polygons_seglen)*px_size;
area_err = 100 * len_p_real * afm_res / imsize^2;

area_layer = sum(polygons_a)/numel(a); % numel = number of pixels


% fprintf('Pixels are %g on a side.\n', px_size);
% fprintf('Total perimeter length is %g microns\n', len_p_real);
fprintf('Enclosed area of is %.3g %%\n', 100 *area_layer);
fprintf('Assuming a 5nm resolution, this gives a coverage error of %.2g%%\n', ...
    area_err);

%%%%%%%%% plot

%plotting fitted polygons on top of islands

% hold on

for k=1:length(polygons)
    plot(polygons{k}(1,:), polygons{k}(2,:), 'r-', 'linewidth', 1.3); 
end
hold off




