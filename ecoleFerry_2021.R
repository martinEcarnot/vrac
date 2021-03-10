library(rnirs)
library(nirsextra)

load("C:\\Users\\robot\\Documents\\Martin\\vrac\\fm_eau_chloro_Ecole_Ferry")
# 
# d="C:\\ProgramData\\ASD\\Indico Pro\\Projects\\multi_especes"
# sp=asd_read_dir(d)
# spp_eau=pre(sp,p_eau)
# load("fm_eau_chloro_Ecole_Ferry")
# Tu <- .projscor(fm_eau, .matrix(spp_eau))
# beta <- t(fm_eau$C)
# 
# nc=8
# ypred=fm_eau$ymeans + Tu[,, drop = FALSE] %*% beta[,, drop = FALSE]
# 



# Scanne l'apparition d'un nouveau fichier
setwd("C:\\ProgramData\\ASD\\Indico Pro\\Projects\\ecoleFerry_2021")
old_files <- list.files(pattern = "\\.asd$") #character(0)
plot(0,type='n',axes=FALSE,ann=FALSE)
while(TRUE){
  new_files <- setdiff(list.files(pattern = "\\.asd$"), old_files)
  sapply(new_files, function(x) {

    sp = asd_read(new_files)
    x = sp$spectrum/sp$reference
    
    # Eau
    spp_eau=pre(rbind(x,x),p_eau)[1,]
    Tu <- .projscor(fm_eau, .matrix(spp_eau))
    beta <- t(fm_eau$C)
    ypred_eau=fm_eau$ymeans + Tu[,, drop = FALSE] %*% beta[,, drop = FALSE]
    if (ypred_eau<0) ypred_eau=-ypred_eau
    
    # Chloro
    spp_chloro=pre(rbind(x,x),p_chloro)[1,]
    Tu <- .projscor(fm_chloro, .matrix(spp_chloro))
    beta <- t(fm_chloro$C)
    ypred_chloro=fm_chloro$ymeans + Tu[,, drop = FALSE] %*% beta[,, drop = FALSE]
    if (ypred_chloro<0) ypred_chloro=-ypred_chloro
    
    plot(0,type='n',axes=FALSE,ann=FALSE)
    text(1,0.5, sprintf('Chlorophylle = %3.0f',ypred_chloro*10),cex = 5)
    text(1,-0.5, sprintf('Eau = %3.0f',ypred_eau),cex = 5)
  })
  old_files = c(old_files, new_files)
  Sys.sleep(3) # wait half minute before trying again
}

# library(jpeg)
# f="C:\\Users\\seedmeister\\Pictures\\stock-photo-portrait-of-amazement-siberian-husky-dog-opened-mouth-surprised-on-isolated-black-background-front-599221973.jpg"
# im=readJPEG(f)
# 
# plot(0,type='n',axes=FALSE,ann=FALSE)
# text(1,0, sprintf('%3.1f%%',0.6),cex = 20)
# rasterImage(im,0,0,1,1)