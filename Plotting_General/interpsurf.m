function [nx,ny,nz] = interpsurf(x,y,z, fact)
%function [nx,ny,nz] = interpsurf(x,y,z, fact)
% x,y,z must all be the same dimentions
% fact is a 2-element vector containing the interp factors for cols and rows
%
% size(nx) 
%    [size(nx,1)*fact(1)  size(nx, 2)*fact(2)]%
nx1 = zeros([size(x,1).*fact(1)-1 size(x,2)]);
ny1 = zeros(size(nx1));
nx = zeros(size(x).*fact-1);
ny = zeros(size(nx));
nz = zeros(size(nx));

rows = size(x,1); cols = size(x, 2);
nrows = size(nx,1); ncols = size(nx, 2);
for k = 1:cols
    nx1(:,k) = interp1((0:fact(1):(rows-1)*fact(1))+1, x(:,k), 1:nrows);
    ny1(:,k) = y(1,k);
%    nz1
end
ny(1,:) = interp1((0:fact(2):(cols-1)*fact(2))+1, ny1(k,:), 1:ncols);
for k = 1:nrows
    nx(k,:) = interp1((0:fact(2):(cols-1)*fact(2))+1, nx1(k,:), 1:ncols);
    ny(k,:) = ny(1,:);
end

nz = griddata(x,y,z, nx, ny);
    