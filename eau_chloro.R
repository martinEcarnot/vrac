library(R.matlab)
library(rnirs)
library(nirsextra)

ncomp=10

if (0)  {
  ## EAu
  f="C:\\Users\\seedmeister\\Documents\\Martin\\R\\eau_Montpellier2012_calib.mat"
  x=readMat(f)
  dat=sp2df(x$Xsais[[1]],x$Ysais[[1]])
  colnames(dat$x)=x$Xsais[[3]]
  rownames(dat)=x$Xsais[[2]]
  dat=dat[-which(dat$y<0),]
  dat=dat[-which(dat$x[,500]<0.4),]
  iout=as.numeric(c("102","154", "119", "185"))  # avec filtre fm4=lapply(fm[1:3],function (x) {x[x$ncomp==4 & x$rep==1,]}); fm4$y$rownam[which(abs(fm4$fit$y1-fm4$y$y1) >20)] a parit de tous les spectres
  dat=dat[-iout,]
  
  # for (i in seq(1,1000,50)) {
  # p=rbind(list('adj',''),list('red',c(50,40,1)),list('snv',''),list('sder',c(1,3,65)))
  p=rbind(list('adj',''),list('red',c(100,40,1)),list('snv',''),list('sder',c(1,3,85)))
  # p=rbind(list('adj',''),list('red',c(50,40,1)))
  dat$xp=pre(dat$x,p)
  n=nrow(dat)
  seg= segmkf(n = n, K = 5, typ = "random", nrep = 8)
  fm=cvfit(dat$xp,dat$y, fun=plsr,segm=seg, ncomp=8)
  # fm=cvfit(dat$xp,dat$y, fun=lwplsr,segm=seg, ncomp=10, ncompdis=10, k=n, h=2)
  
  z <- mse(fm, ~ ncomp + rep)
  # plotmse(z,nam="rmsep" )
  print(min(mse(fm, ~ ncomp)$rmsep))
  # print(mse(fm, ~ ncomp))
  # }
  
  # fm4=lapply(fm[1:3],function (x) {x[x$ncomp==4,]})
  fm4=lapply(fm[1:3],function (x) {x[x$ncomp==4 & x$rep==1,]})
  plot(fm4$fit$y1,fm4$y$y1)
}


## Chloro
f="C:\\Users\\seedmeister\\Documents\\Martin\\R\\chlorophylle2011.mat"
# x=readMat(f)
dat=sp2df(x$Xsaist[[1]],x$Ysaist[[1]])
colnames(dat$x)=x$Xsaist[[3]]
rownames(dat)=1:nrow(dat$x)  #x$Xsaist[[2]]
iout=109
dat=dat[-iout,]

# for (i in seq(1,1000,50)) {
# p=rbind(list('adj',''),list('red',c(50,40,1)),list('snv',''),list('sder',c(1,3,65)))
p=rbind(list('adj',''),list('red',c(80,1200,1)),list('snv',''),list('sder',c(1,3,85)))
# p=rbind(list('adj',''),list('red',c(80,1200,1)),list('snv',''))
# p=rbind(list('adj',''),list('red',c(50,40,1)))
dat$xp=pre(dat$x,p)
n=nrow(dat)
seg= segmkf(n = n, K = 5, typ = "random", nrep = 20)
fm=cvfit(dat$xp,dat$y, fun=plsr,segm=seg, ncomp=10)
# fm=cvfit(dat$xp,dat$y, fun=lwplsr,segm=seg, ncomp=10, ncompdis=10, k=n, h=2)

z <- mse(fm, ~ ncomp ) 
plotmse(z,nam="rmsep" )
print(min(mse(fm, ~ ncomp)$rmsep))
# print(mse(fm, ~ ncomp))
# }

# fm4=lapply(fm[1:3],function (x) {x[x$ncomp==4,]})
fm4=lapply(fm[1:3],function (x) {x[x$ncomp==4 & x$rep==1,]})
plot(fm4$fit$y1,fm4$y$y1)


fm=pls(dat$xp,dat$y, ncomp=10)

Tu <- .projscor(fm, .matrix(dat$xp[1,]))
beta <- t(fm$C)

nc=8
ypred=fm$ymeans + Tu[,1:nc, drop = FALSE] %*% beta[1:nc, , drop = FALSE]



stop()

# Scanne l'apparition d'un nouveau fichier
setwd("C:\\Users\\seedmeister\\Pictures")
old_files <- list.files(pattern = "\\.jpg$") #character(0)
plot(0,type='n',axes=FALSE,ann=FALSE)
while(TRUE){
  new_files <- setdiff(list.files(pattern = "\\.jpg$"), old_files)
  sapply(new_files, function(x) {
    
    plot(0,type='n',axes=FALSE,ann=FALSE)
    text(1,0, sprintf('%3.1f%%',runif(1)),cex = 10)
    # do stuff
  })
  old_files = c(old_files, new_files)
  Sys.sleep(3) # wait half minute before trying again
}

library(jpeg)
f="C:\\Users\\seedmeister\\Pictures\\stock-photo-portrait-of-amazement-siberian-husky-dog-opened-mouth-surprised-on-isolated-black-background-front-599221973.jpg"
im=readJPEG(f)

plot(0,type='n',axes=FALSE,ann=FALSE)
text(1,0, sprintf('%3.1f%%',0.6),cex = 20)
rasterImage(im,0,0,1,1)




# Fonction .projscore de rnirs
.projscor <- function(fm, X) {
  
  ## fm = Output of functions pca or pls, 
  ## or of the PCA or PLS algorithm functions
  
  T <- .center(.matrix(X), fm$xmeans) %*% fm$R
  
  rownam <- row.names(X)
  colnam <- paste("comp", seq_len(dim(T)[2]), sep = "")
  
  dimnames(T) <- list(rownam, colnam)
  
  T
  
}

.center <- function(X, center = matrixStats::colMeans2(X)) 
  t((t(X) - c(center)))


.xmean <- function(X, weights = NULL, row = FALSE) {
  
  X <- .matrix(X, row = row)
  n <- dim(X)[1]
  
  if(is.null(weights))
    weights <- rep(1 / n, n)
  else
    weights <- weights / sum(weights)
  
  colSums(weights * X)   
  
}


.matrix <- function(X, row = TRUE,  prefix.colnam = "x") {
  
  if(is.vector(X)) 
    if(row) 
      X <- matrix(X, nrow = 1)
    else
      X <- matrix(X, ncol = 1)
    
    if(!is.matrix(X)) 
      X <- as.matrix(X)
    
    if(is.null(row.names(X))) 
      row.names(X) <- seq_len(dim(X)[1])
    
    if(is.null(colnames(X)))
      colnames(X) <- paste(prefix.colnam, seq_len(dim(X)[2]), sep = "")
    
    X
    
}
