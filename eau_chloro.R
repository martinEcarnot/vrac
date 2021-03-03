library(R.matlab)
library(rnirs)
library(nirsextra)


# EAu
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

# Chloro
# f="C:\\Users\\seedmeister\\Documents\\Martin\\R\\chlorophylle2011.mat"
# x=readMat(f)
