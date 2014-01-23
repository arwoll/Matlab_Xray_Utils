function result = bindata(dat,binsize)
% function result = bindata(dat,binsize)
% returns a binned version of dat, where adjacent binsize pts are averaged together
result=zeros(1,floor(length(dat)/binsize));
for k=1:length(result)
        result(k) = mean(dat( ((k-1)*binsize+1):(k*binsize)));
end