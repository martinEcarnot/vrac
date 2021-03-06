library(rnirs)
library(nirsextra)

load("C:\\Users\\robot\\Documents\\Martin\\vrac\\fm_eau_chloro_Ecole_Ferry")



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
    text(1,0.5, sprintf('Chlorophylle = %3.0f',ypred_chloro*10),cex = 4)
    text(1,-0.5, sprintf('Eau = %3.0f',ypred_eau),cex = 4)
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