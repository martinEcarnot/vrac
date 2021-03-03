# Scanne l'apparition d'un nouveau fichier
setwd("C:\\ProgramData\\ASD\\Indico Pro\\Projects\\ecoleFerry_2021")
old_files <- list.files(pattern = "\\.asd$") #character(0)
plot(0,type='n',axes=FALSE,ann=FALSE)
while(TRUE){
  new_files <- setdiff(list.files(pattern = "\\.asd$"), old_files)
  sapply(new_files, function(x) {
    
    plot(0,type='n',axes=FALSE,ann=FALSE)
    text(1,0, sprintf('%3.1f%%',runif(1)),cex = 10)
    # do stuff
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