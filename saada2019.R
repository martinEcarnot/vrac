# Spectres SAADA 2019
# Essai de discri de genotypes

library(rnirs)
library(dplyr)
library(sampling)
# source('Script_R_2020/SIGNE_maha0.R')
source("~/Documents/INRA/R/pre.R")
source("~/Documents/INRA/melanges/2019/segmFact.R")

d='/home/ecarnot/Documents/INRA/melanges/2019'
sp=read.table(file.path(d,'saada2019_spectres.txt'), header=T, row.names=1, sep=';', dec='.')

# Enleve ce qui n'est pas de SAADA
sp=sp[-seq(1,29),]
sp=sp[grep("es",rownames(sp), invert=T),]

md=read.table(file.path(d,'SAADA prepa semis_code champ19.csv'),header=T,  sep=';')

# On duplique les infos de md sur sp
colnames(sp)=1e7/as.numeric(gsub("X","",colnames(sp)))
sp=data.frame(x=I(as.matrix(sp)))
class(sp$x)="matrix"
rownames(sp)[3988]=gsub("-","-8",rownames(sp)[3988])
rownames(sp)[666]=gsub("7.","7",rownames(sp)[666])
rownames(sp)[3705]=gsub("73","7",rownames(sp)[3705])

sp=cbind(code.champ=as.numeric(sub("\\-.*", "", rownames(sp))), plante=sub(".*-", "", rownames(sp)),sp)

sp$plante=as.factor(trimws(gsub("\\(1\\)","",sp$plante)))

sp=cbind(sp,left_join(sp,md,by ="code.champ")[,4:9])

mono=sp[grep("monogénotype",sp$culture),]




# Pré
# p=rbind(list('red',c(1300, 1, 2)),list('snv',''),list('sder',c(2,3,11)))
p=rbind(list('red',c(100,1,2)),list('snv',''),list('sder',c(2,3,41)))
mono$xp=pre(mono$x,p)
comp=15
rpca=pca(mono$xp,ncomp=comp)
plotxy(rpca$Tr[, c(1,2)],group=mono$rep)

stop()
# Discri
ngeno=nlevels(mono$Genotype1)
segm=segmFact(mono, var=list("Genotype1","plante"),nel=list(ngeno,rep(4,ngeno)), nrep=10 )
fm <- fitcv(mono$xp, mono$Genotype1,fun = plsdalm,  ncomp = 15,  segm = segm)

z <- err(fm, ~ ncomp)
plotmse(z, nam = "errp")
min(z$errp)

# Avec 2 geno
r=list()
c=1
for (i in 1:ngeno) {
  for (j in 1:ngeno) {
    print(i)
    g1=levels(mono$Genotype1)[i]
    g2=levels(mono$Genotype1)[j]
    ideux=mono$Genotype1 %in% c(g1,g2)
    mono2=droplevels(mono[ideux,])
    ngeno2=nlevels(mono2$Genotype1)
    segm=segmFact(mono2, var=list("Genotype1","plante"),nel=list(ngeno2,rep(4,ngeno2)), nrep=2 )
    fm <- fitcv(mono2$xp, mono2$Genotype1,fun = plsdalm,  ncomp = 10,  segm = segm)
    r[[c]]=fm
    c=c+1
  }
}

z <- err(fm, ~ ncomp)
# plotmse(z, nam = "errp")
# i6=fm$y$ncomp==5
# table(fm$y$x1[i6],fm$fit$x1[i6])

load(file = "~/Documents/INRA/R/sorties_saada2019")
rdf=data.frame(minerr=single(length(r)))
for (i in 1:length(r)) {
  z <- err(r[[i]], ~ ncomp)
  rdf$minerr[i]=z[which(z$errp == min(z$errp))[1], 4]
}

fm4=lapply(fm,function (x) {x[x$ncomp==4,]})

