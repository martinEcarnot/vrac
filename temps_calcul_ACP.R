
start_time <- Sys.time()

library(rnirs)
xr=matrix(rnorm(4000000),ncol=200)
xu=matrix(rnorm(2000000),ncol=200)
fm=pca(xr, xu, 100)

print(str(xr))
print(str(xu))
print(Sys.time() - start_time)
