d='\\\\stocka2\\agap-ble\\Ble\\ASD\\multi_especes'
sp=asd_read_dir(d)
fm=plsr(dat$xp,dat$y,pre(sp,p), ncomp=6)
fm4=lapply(fm[1:3],function (x) {x[x$ncomp==5,]})
fm4$fit$y1
