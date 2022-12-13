f="D:/2021/perfomix/perfomixspectro_prioritary-mixtures_long_ME.csv"
l=read.table(f,sep=";", header = T)


## IHS


# i20=which(l$season=="2019-2020")
i20=which(l$season=="2020-2021")
# l20=paste0(l[i20,"xy"],'-',l[i20,"id"],'*','sp.gz')
l20=paste0('*',l[i20,"xy"],'*','sp.gz')

for (i in 1:length(i20)) {
  # print(l20[i])
  c=Sys.glob(file.path("D:/2021/perfomix/Recolte_2021/CHS",l20[i]))
  if (length(c)<1) {cat(paste0(substr(l20[i],2,7),"\n"))}
}

