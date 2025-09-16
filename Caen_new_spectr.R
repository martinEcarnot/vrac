# Calib Feuilles Caen 2019
library(dplyr)
library(sampling)
require(pls)
source("~/Documents/INRA/R/asd_read_dir.R")
source("~/Documents/INRA/R/signe/Script_R_2020/sp2df.R")
source("~/Documents/INRA/R/pre.R")

l=read.delim('/home/ecarnot/Documents/INRA/R/liste_pretraitements.txt', comment.char = '#', header=F)
eval(parse(text=paste0("p=",l[[1]])))

d='/home/ecarnot/Documents/INRA/ASD/Calibration Caen Montpellier sur ble/Nouveau_spectres_Caen/N Feuilles - Calibration - Spectres/'
x=asd_read_dir(d);
x=x[grep("test",rownames(x), invert=T),]
x=x[x[,1]<1,]
# x=x[as.numeric(substr(rownames(x),9,10))>2 & as.numeric(substr(rownames(x),9,10))<8,]  # On ne garde que les spectres du milieu de la feuille
rownames(x)=gsub("od","",rownames(x))
yfull=data.frame(N=NA,ID=substr(rownames(x),1,5))

y=read.table(file.path(d,'/../N Feuilles - Calibration - %N.csv'),header=T,dec=",",sep=";")
y$ID=as.factor(paste(y$Modalité,y$Bloc))
yfull$N=left_join(yfull,y,by ="ID")$X.N  # Pour dupliquer y sur chaque ligne de yfull
# yfull$N=merge(yfull,y,by="ID")$X.N       !!!!!   merge ne garde pas l'ordre de départ !!!!!

dat=sp2df(x,y=yfull$N)
dat$ID=yfull$ID

seg=lapply(levels(dat$ID), function(x) which(dat$ID==x))
dat$xp=pre(dat$x,p)
rpls=plsr(y~xp,10,data=dat,validation="CV",segments=seg)
plot(RMSEP(rpls))
print(SER2(rpls$validation$pred[,1,],dat$y)$SE,digit=3)
print(SER2(rpls$validation$pred[,1,],dat$y)$R2,digit=3)

 # Spectres moyens
xm=lapply(levels(dat$ID), function(x) colMeans(dat$x[which(dat$ID==x),]))
xm=unlist(xm)
dim(xm)=c(2151,length(xm)/2151)
ym=aggregate(dat, list(dat$ID), mean)
datm=sp2df(t(xm),ym$y,nam = ym$Group.1)
datm$xp=pre(datm$x,p)
rplsm=plsr(y~xp,10,data=datm,validation="LOO")
plot(RMSEP(rplsm))
print(min(SER2(rplsm$validation$pred[,1,],datm$y)$SE))
print(SER2(rplsm$validation$pred[,1,],datm$y)$SE,digit=3)
print(SER2(rplsm$validation$pred[,1,],datm$y)$R2,digit=3)

stop()

 # Si on fait une CV avec calib sur non-moyenné, et valid sur moyenné
predcvm=matrix(nrow=23,ncol=10)
for (i in 1:23) {
  ival=which(dat$ID %in% rownames(datm$x)[i])
  # print(rownames(dat[-ival,]))
  rplsi=plsr(y~xp,10,data=dat[-ival,])
  # print(rownames(datm$x)[i])
  predcvm[i,]=predict(rplsi,datm$xp)[i,1,]
}


# Si on fait une CV avec calib sur moyenné, et valid sur non-moyenné
predcvm=matrix(nrow=nrow(dat),ncol=10)
for (i in 1:23) {
  ival=which(dat$ID %in% rownames(datm$x)[i])
  # print(rownames(dat[-ival,]))
  rplsi=plsr(y~xp,10,data=datm[-i,])
  # print(rownames(datm$x)[i])
  predcvm[ival,]=predict(rplsi,dat$xp)[ival,1,]
}



# Prediction de l'ASD MTP
N_MTP=read.table('/home/ecarnot/Documents/INRA/ASD/Calibration Caen Montpellier sur ble/Nouveau_spectres_Caen/N feuilles - prediction - MTP.csv', header=T, sep=";", dec=".")
N_MTP$ID=substr(N_MTP$nom_spectre,1,8)
ym=aggregate(N_MTP, list(N_MTP$ID), mean)
SER2(ym$N_MTP,y$X.N[-3])
