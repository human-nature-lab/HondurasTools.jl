# peform MCA on data output from julia script
# based on work by Selena Lee

library("readr")
library("tibble")
library("FactoMineR")

wavemca <- function(dfpca_w) {

    dfpca_w_w1 <- dfpca_w[dfpca_w$wave == 1, ]
    dfpca_w_w3 <- dfpca_w[dfpca_w$wave == 3, ]

    bd_w1 <- dfpca_w_w1$wave
    bd_w3 <- dfpca_w_w3$wave
    wv_w1 <- dfpca_w_w1$wave
    wv_w3 <- dfpca_w_w3$wave

    dfpca_w_w1$building_id <- NULL
    dfpca_w_w3$building_id <- NULL
    dfpca_w_w1$wave <- NULL
    dfpca_w_w3$wave <- NULL

    # use resp-level vars as supplementary vars: peopleperroom, incomesuff
    res.mca_w1 = MCA(dfpca_w_w1, quanti.sup = c(14, 15))
    res.mca_w3 = MCA(dfpca_w_w3, quanti.sup = c(14, 15))
    res_w <- list(res.mca_w1, res.mca_w3)
    return(res_w)
}

mcaplots <- function(res, sfx) {
    sfx <- paste0("_", sfx)
    pth <- "honduras-reports/development/mca/"
    fext <- ".png"
    wx <- c(1,3)

    for (i in 1:2) {
        w <- wx[i]
        
        png(file = paste0(pth, "mca1_w", toString(w), sfx, fext))
            plot.MCA(res[[i]], invisible=c("var","quanti.sup"), cex=0.7)
        dev.off()
        
        png(file = paste0(pth, "mca2_w", toString(w), sfx, fext))
            plot.MCA(res[[i]], invisible=c("ind","quanti.sup"), cex=0.7)
        dev.off()
        
        png(file = paste0(pth, "mca3_w", toString(w), sfx, fext))
            plot.MCA(res[[i]], invisible=c("ind"))
        dev.off()

        png(file = paste0(pth, "mca_ellipse_w", toString(w), sfx, fext))
            plotellipses(res[[i]])
        dev.off()
    }
}

mca_df <- function(res, dfpca_w) {

    dfpca_w_w1 <- dfpca_w[dfpca_w$wave == 1, ]
    dfpca_w_w3 <- dfpca_w[dfpca_w$wave == 3, ]

    bd_w1 <- dfpca_w_w1$building_id
    bd_w3 <- dfpca_w_w3$building_id
    wv_w1 <- dfpca_w_w1$wave
    wv_w3 <- dfpca_w_w3$wave

    d1 <- c(res[[1]]$ind$coord[, 1], res[[2]]$ind$coord[, 1])
    d2 <- c(res[[1]]$ind$coord[, 2], res[[2]]$ind$coord[, 2])
    bd <- c(bd_w1, bd_w3)
    wv <- c(wv_w1, wv_w3)
    out <- tibble(building_id = bd, wave = wv, wealth_d1 = d1, wealth_d2 = d2)
}

## execute

dfpca_w <- read_csv("mca/df_mca.csv")
dfpca_i <- read_csv("mca/df_mca_i.csv")

res_w <- wavemca(dfpca_w)
res_i <- wavemca(dfpca_i) # imputed version

# dimdesc(res_w[[1]])

mcaplots(res_w, "reg")
mcaplots(res_i, "imp")

##

res <- res_w
sfx <- paste0("_", "imp")
pth <- "honduras-reports/development/mca/"
fext <- ".png"
wx <- c(1,3)

i <- 2
w <- wx[i]

png(file = paste0(pth, "mca1_w", toString(w), sfx, fext))
    plot.MCA(res[[i]], invisible=c("var","quanti.sup"), cex=0.7)
dev.off()

png(file = paste0(pth, "mca2_w", toString(w), sfx, fext))
    plot.MCA(res[[i]], invisible=c("ind","quanti.sup"), cex=0.7)
dev.off()

png(file = paste0(pth, "mca3_w", toString(w), sfx, fext))
    plot.MCA(res[[i]], invisible=c("ind"))
dev.off()

png(file = paste0(pth, "mca_ellipse_w", toString(w), sfx, fext))
    plotellipses(res[[i]])
dev.off()

##

df_w <- mca_df(res_w, dfpca_w)
df_w$imputed <- FALSE
df_i <- mca_df(res_i, dfpca_i)
df_i$imputed <- TRUE

out <- rbind(df_w, df_i)

length(out$wealth_d1[out$wave == 1])
length(out$wealth_d1[out$wave == 1 & out$imputed == FALSE])
mx <- 7000
cor(out$wealth_d1[out$wave == 1 & out$imputed == FALSE][1:mx], out$wealth_d1[out$wave == 3 & out$imputed == FALSE][1:mx])
cor(out$wealth_d2[out$wave == 1 & out$imputed == FALSE][1:mx], out$wealth_d2[out$wave == 3 & out$imputed == FALSE][1:mx])

cor(out$wealth_d1[out$wave == 1 & out$imputed == TRUE][1:mx], out$wealth_d1[out$wave == 3 & out$imputed == TRUE][1:mx])
cor(out$wealth_d2[out$wave == 1 & out$imputed == TRUE][1:mx], out$wealth_d2[out$wave == 3 & out$imputed == TRUE][1:mx])

# wave 1 dim 1 is in correct direction
# wave 3 dim 1 must be flipped


write_csv(out, "mca/wealth_index.csv")
