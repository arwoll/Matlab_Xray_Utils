
%%% the following program accepts a tiff image (grayscale) of an AFM,
%%% measures the contour height of each island, discards the unclosed
%%% contours and contours whose number of points is less than some
%%% tolerance set by the user (this is determined by looking at how many
%%% points a typical inslad has and choosing some tolerance below that.
%%% After having the final polygons, it attempts to reduce the 


clc
clear all
close all

% a= imread('tvd3_spring09_g3_spot2_10x.tiff');
% a= imread('tvd3_spring09_g3_spot2.tiff');
% a= imread('tvd3_spring09_g3_spot4.tiff');
% a= imread('tvd3_spring09_g3_spot4_10x.tiff');
a= imread('tvd3_spring09_g4_spot2.tiff');
% a= imread('tvd3_spring09_g4_spot2_10x.tiff');
% a= imread('tvd3_spring09_g4_spot4_10x.tiff');
% a= imread('tvd3_spring09_g4_spot4.tiff');
% a= imread('tvd3_pfp_fots_s4_spot4.tiff');
% a= imread('tvd3_pfp_fots_s1_spot2.tiff');
% a= imread('tvd3_pfp_fots_s2_spot2.tiff');
% a= imread('tvd3_pfp_fots_s3_spot3.tiff');
% a= imread('tvd3_spring09_g7_spot2.tiff');
% a= imread('tvd3_spring09_g7_spot4.tiff');
% a= imread('tvd3_spring09_g8_spot4.tiff');

maxa = max(a(:));
% C = contour(double(a),[2.5e4 2.5e4]); %spring09_g4_spot2_10x
C = contour(double(a),[3.2e4 3.2e4]); %spring09_g4_spot2
% C = contour(double(a),[3.2e4 3.2e4]); %spring09_g3_spot4
% C = contour(double(a),[3.2e4 3.2e4]); %spring09_g3_spot2
% C = contour(double(a),[1.25e4 1.25e4]); %spring09_g3_spot2_10x
% C = contour(double(a),[2.5e4 2.5e4]); %spring09_g3_spot4_10x
% C = contour(double(a),[2.5e4 2.5e4]); %spring09_g4_spot4_10x
% C = contour(double(a),[3.2e4 3.2e4]); %spring09_g4_spot4
% C = contour(double(a),[1.75e4 1.75e4]); % for tvd3_fots-spring09_g4_spot4
% C = contour(double(a),[1.2e4 1.2e4]); %pfp_fots_s1_spot2
% C = contour(double(a),[4e4 4e4]); %pfp_fots_s2_spot2
% C = contour(double(a),[1.5e4 1.5e4]); %pfp_fots_s3_spot3
% C = contour(double(a),[0.53e4 0.53e4]); %spring09_g7_spot2
% C = contour(double(a),[0.3e4 0.3e4]); %spring09_g7_spot4
% C = contour(double(a),[0.4e4 0.4e4]); %spring09_g8_spot4

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
    elseif all(startxy == endxy)
        nclosed = nclosed + 1;
        polygons{nclosed} = C(:,n+1:n+nvert);
    else 
        nunclosed = nunclosed + 1;
        unclosed{nunclosed} = C(:,n+1:n+nvert);
    end
    n = n + nvert + 1;
end

%%%%%%%%%%%%
%%%%%%%%%%% avearging polygons using reducem

polygons_aver = {};
polygons_aver_cat = {};
tol = 3;

new_inc = 1;
for j=1:length(polygons)

    x=[]; y=[]; p5=[]; p4=[]; x1=[]; y1=[];
    p4 = polygons{j};
	[y, x] = reducem(p4(2,:)', p4(1,:)',tol);
    if length(y)>3
        %     p5 = [x';y'];
        [x1 y1] = poly2ccw(x',y');
        polygons_aver{new_inc} = [x1;y1]; %polygons_aver{new_inc} = [x';y'];
        polygons_aver_cat{new_inc} = [x1 NaN;y1 NaN]; %  polygons_aver_cat{new_inc} = [x' NaN;y' NaN];
        new_inc = new_inc+1;
    end
end
%     [px py] = poly2ccw(P(1,:),P(2,:));
%         V = [px ; py];

C_reduced = cell2mat(polygons_aver_cat);
%%%%%%%%%%
%%%%%%%%% calculating angles after reducem averaging

polygons_angler_a={};
polygons_seglen = {};

for i=1:size(polygons_aver,2)
    
    p_diff_x = []; p_diff_y=[]; p6=[]; 
    p6 = polygons_aver{i};
    
    p_diff_x = diff(p6(1,:));
    p_diff_y = diff(p6(2,:));
    ang_p6=zeros(1,length(p_diff_x));
    len_p6 = ang_p6;
    
    ang_p6 = atan2(p_diff_y,p_diff_x)*180/pi;
    len_p6 = sqrt(p_diff_y.^2 + p_diff_x.^2);
%     for j=1:length(ang_p6)
%         ang_p6(j) = atan2(p_diff_y(j),p_diff_x(j))*180/pi();
%         len_p6(j) = sqrt(p_diff_y(j)^2 + p_diff_x(j)^2);
%     end
polygons_angler_a{i} = ang_p6;
polygons_seglen{i} = len_p6;
end

% polygons_angler_a=polygons_angler;

%%%%%%%%%%%%%%%
% Calculating hist of islands weighted by their lengths using anlge diffs
nbins = 72;
polygons_prob=zeros(1,length(nbins));

for i=1:length(polygons_angler_a)    
prob =[];
[centers, prob] = facet_hist(polygons_angler_a{i}, polygons_seglen{i}, nbins);
polygons_prob = polygons_prob+prob;
end
polygons_centers = centers;

%%%%%%%%%%%%%%%

% eliminating angles based on length threshold 
  
inc = 1;
new_ang = {};
poly_seg = {};

for k=1:length(polygons_aver)
    Lth = (1/15)*sum(polygons_seglen{k});
    poly_seg{k}=[];
    x = polygons_aver{k}(1,:);
    y = polygons_aver{k}(2,:);
    new_x = []; new_y = [];
    for j=1:length(polygons_seglen{k})
        if polygons_seglen{k}(j) > Lth
            new_ang{k}(inc) = polygons_angler_a{k}(j);
            new_x = [new_x x(j) x(j+1) NaN];
            new_y = [new_y y(j) y(j+1) NaN];
            inc=inc+1;
        end
    end
    poly_seg{k} =[new_x; new_y];
    inc=1;
end

C_segments = cell2mat(poly_seg);
%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%
%Calculating interior angles using derived geometery

polygons_int={};

for i=1:size(polygons_angler_a,2) %i=1:size(new_ang,2) %i=1:size(polygons_angler_a,2)
    
    p9=[]; p10=[];
    p9=polygons_angler_a{i}; %new_ang{i};              %polygons_angler_a{i};
    
    if length(p9)<2
        p10 = 0.0;
    else
        for j=1:length(p9)
            if j==length(p9)
%                 p10(j) = 180-p9(j)+p9(j-(length(p9)-1));
                p10(j) = 180+p9(j)-p9(1);    %p10(j) = 180-p9(j)+p9(1);
                  if p10(j) > 360
                    p10(j) = p10(j)-360;
%                     elseif p10(j) > 180 && p10(j) < 360
%                     p10(j) = 360 - p10(j);
                    elseif p10(j) < -360
                    p10(j) = abs(p10(j)) - 360;
                    elseif p10(j) < 0 && p10(j) > -360
                    p10(j) = 360+p10(j);
                  end
            else
             p10(j) = 180+p9(j)-p9(j+1);   %p10(j) = 180-p9(j)+p9(j+1);
                  if p10(j) > 360
                    p10(j) = p10(j)-360;
%                     elseif p10(j) > 180 && p10(j) < 360
%                     p10(j) = 360 - p10(j);
                    elseif p10(j) < -360
                    p10(j) = abs(p10(j)) - 360;
                    elseif p10(j) < 0 && p10(j) > -360
                    p10(j) = 360+p10(j);
                 end
            end
        end
    end
    polygons_int{i}=p10;
end

%%%%%%%%%%%%%
% Calculating hist of islands weighted by their lengths and internal angles
nbinsa = 72;
polygons_proba=zeros(1,length(nbinsa));

for i=1:length(polygons_int)    
proba =[];
[centersa, proba] = facet_hist_a(polygons_int{i}, polygons_seglen{i}, nbinsa);
polygons_proba = polygons_proba+proba;
end
polygons_centersa = centersa;


%%%%%%%%%%%%%%%%%%%%
% calculating interior angles using code downloaded from web:
% http://people.sc.fsu.edu/~jburkardt/m_src/geometry/geometry.html

polygons_int_a={};
polygons_vert=[];

for i=1:size(polygons_aver,2)
    
    P = []; px =[]; py=[]; V = []; N=[]; angle =[]; 
    
    P = polygons_aver{i};
    
    if length(P)<2
        angle = 0.0;
    else
%         [px py] = poly2ccw(P(1,:),P(2,:));
        V = [P(1,:) ; P(2,:)];  %V = [px ; py];
        N=size(polygons_aver{i},2)-1;
        polygons_vert(i)=N;
        angle = polygon_angles_2d(N,V);
        angle = angle*180/pi();
    end
    %sum(angle*180/pi())
    polygons_int_a{i} = angle;
    
end

mean_vert = mean(polygons_vert);
std_vert=std(polygons_vert);

sprintf('The mean number of vertices is %0.5f ',mean_vert)
sprintf('The std of the number of vertices is %0.5f ',std_vert)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%% Taking angles from cell array into matrix array and getting rid of
%%%%%%% angles assigned values of zero because of bad fit to polygon. This
%%%%%%% is angles based on formula derived from geometery: polygons_int

polygons_int_mat = cell2mat(polygons_int);
polygons_int_mata = polygons_int_mat(polygons_int_mat~=0);

%%%%%%% Taking angles from cell array into matrix array and getting rid of
%%%%%%% angles assigned values of zero because of bad fit to polygon. This
%%%%%%% is angles based on program downloaded from web: polygons_int_a

polygons_int_a_mat = cell2mat(polygons_int_a);
polygons_int_a_mata = polygons_int_a_mat(polygons_int_a_mat~=0);

%%%%%%%%%%%%%%

%%%%%%%%% plot

%plotting fitted polygons on top of islands

figure
imagesc(a, [5000, 3.2e4])
colormap gray
hold on
plot(C_reduced(1,:),C_reduced(2,:),'k-','linewidth',1.5)


figure
imagesc(a, [5000, 3.2e4])
colormap gray
hold on
plot(C_reduced(1,:),C_reduced(2,:),'k-','linewidth',1.5)
% plot(C_segments(1,:),C_segments(2,:),'r-','linewidth',1.5)


% histogram of angles calculated from geometry
figure
hist(polygons_int_mata,72)

% histogram of angles calcualted from downloaded code
figure
hist(polygons_int_a_mata,72)

figure
bar(polygons_centers,polygons_prob)

figure
bar(polygons_centersa,polygons_proba)