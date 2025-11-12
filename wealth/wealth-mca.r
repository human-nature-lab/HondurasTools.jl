# Multiple Correspondence Analysis (MCA) for Honduras Wealth Index
# Performs MCA on household wealth indicators from julia script output
# Based on work by Selena Lee
# Based on https://dhsprogram.com/topics/wealth-index/Wealth-Index-Construction.cfm
#
# This script:
# 1. Performs MCA separately for Wave 1 and Wave 3 data
# 2. Uses supplementary quantitative variables (peopleperroom, incomesuff)
# 3. Generates diagnostic plots for both waves
# 4. Extracts wealth index dimensions (d1, d2) for downstream analysis
# 5. Compares regular vs imputed data versions

library("readr")
library("tibble")
library("FactoMineR")

# Perform MCA on wave-specific data
#
# Args:
#   dfpca_w: dataframe with wealth indicators, building_id, and wave columns
#
# Returns:
#   list containing two MCA result objects (wave 1, wave 3)
wavemca <- function(dfpca_w) {

    # Split data by wave
    dfpca_w_w1 <- dfpca_w[dfpca_w$wave == 1, ]
    dfpca_w_w3 <- dfpca_w[dfpca_w$wave == 3, ]

    # Remove ID and wave columns before MCA (not used in analysis)
    dfpca_w_w1$building_id <- NULL
    dfpca_w_w3$building_id <- NULL
    dfpca_w_w1$wave <- NULL
    dfpca_w_w3$wave <- NULL

    # Perform MCA with columns 14 & 15 as supplementary quantitative variables
    # These are resp-level vars: peopleperroom, incomesuff
    res.mca_w1 = MCA(dfpca_w_w1, quanti.sup = c(14, 15))
    res.mca_w3 = MCA(dfpca_w_w3, quanti.sup = c(14, 15))

    # Return results as list: [wave 1, wave 3]
    res_w <- list(res.mca_w1, res.mca_w3)
    return(res_w)
}

# Generate diagnostic plots for MCA results
#
# Creates 4 types of plots for each wave:
#   - mca1: Individual factor map (points only)
#   - mca2: Variable categories map
#   - mca3: Biplot with supplementary vars
#   - mca_ellipse: Confidence ellipses
#
# Args:
#   res: list of MCA results from wavemca()
#   sfx: suffix for filename (e.g., "reg" for regular, "imp" for imputed)
mcaplots <- function(res, sfx) {
    sfx <- paste0("_", sfx)
    pth <- "honduras-reports/development/mca/"
    fext <- ".png"
    wx <- c(1,3)  # waves to plot

    for (i in 1:2) {
        w <- wx[i]

        # Plot 1: Individual factor map (hide variables and quant. supplementary)
        png(file = paste0(pth, "mca1_w", toString(w), sfx, fext))
            plot.MCA(res[[i]], invisible=c("var","quanti.sup"), cex=0.7)
        dev.off()

        # Plot 2: Variable categories map (hide individuals and quant. supplementary)
        png(file = paste0(pth, "mca2_w", toString(w), sfx, fext))
            plot.MCA(res[[i]], invisible=c("ind","quanti.sup"), cex=0.7)
        dev.off()

        # Plot 3: Biplot with supplementary variables visible
        png(file = paste0(pth, "mca3_w", toString(w), sfx, fext))
            plot.MCA(res[[i]], invisible=c("ind"))
        dev.off()

        # Plot 4: Confidence ellipses around categories
        png(file = paste0(pth, "mca_ellipse_w", toString(w), sfx, fext))
            plotellipses(res[[i]])
        dev.off()
    }
}

# Extract MCA coordinates and create tidy dataframe for analysis
#
# Extracts the first two MCA dimensions (wealth indices) and combines
# with building IDs and wave information for both waves
#
# Args:
#   res: list of MCA results from wavemca()
#   dfpca_w: original dataframe with building_id and wave columns
#
# Returns:
#   tibble with columns: building_id, wave, wealth_d1, wealth_d2
mca_df <- function(res, dfpca_w) {

    # Split original data by wave to retrieve IDs
    dfpca_w_w1 <- dfpca_w[dfpca_w$wave == 1, ]
    dfpca_w_w3 <- dfpca_w[dfpca_w$wave == 3, ]

    # Extract building IDs and wave numbers
    bd_w1 <- dfpca_w_w1$building_id
    bd_w3 <- dfpca_w_w3$building_id
    wv_w1 <- dfpca_w_w1$wave
    wv_w3 <- dfpca_w_w3$wave

    # Extract first two MCA dimensions (wealth indices) and combine waves
    d1 <- c(res[[1]]$ind$coord[, 1], res[[2]]$ind$coord[, 1])  # dimension 1
    d2 <- c(res[[1]]$ind$coord[, 2], res[[2]]$ind$coord[, 2])  # dimension 2
    bd <- c(bd_w1, bd_w3)
    wv <- c(wv_w1, wv_w3)

    # Create tidy output dataframe
    out <- tibble(building_id = bd, wave = wv, wealth_d1 = d1, wealth_d2 = d2)
    return(out)
}

## ============================================================================
## EXECUTION: Main analysis workflow
## ============================================================================

# Load input data
dfpca_w <- read_csv("mca/df_mca.csv")      # regular data
dfpca_i <- read_csv("mca/df_mca_i.csv")    # imputed data (for missing values)

# Perform MCA on both datasets
res_w <- wavemca(dfpca_w)  # regular version
res_i <- wavemca(dfpca_i)  # imputed version

# Optional: examine dimension descriptions (commented out)
# dimdesc(res_w[[1]])

# Generate diagnostic plots for both versions
mcaplots(res_w, "reg")  # regular data plots
mcaplots(res_i, "imp")  # imputed data plots

## ============================================================================
## EXPLORATORY: Manual plot generation for specific wave
## (This section appears to be test/exploratory code - consider removing if not needed)
## ============================================================================

# Note: This duplicates mcaplots() functionality for a specific case
# Uses regular results (res_w) but labels with "imp" suffix (possible error?)
res <- res_w
sfx <- paste0("_", "imp")
pth <- "honduras-reports/development/mca/"
fext <- ".png"
wx <- c(1,3)

# Generate plots for wave 3 only (i=2 corresponds to wave 3)
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

## ============================================================================
## OUTPUT: Extract wealth indices and save results
## ============================================================================

# Extract MCA coordinates into dataframes
df_w <- mca_df(res_w, dfpca_w)
df_w$imputed <- FALSE  # flag for regular data
df_i <- mca_df(res_i, dfpca_i)
df_i$imputed <- TRUE   # flag for imputed data

# Combine both versions into single output
out <- rbind(df_w, df_i)

# Diagnostic: check sample sizes
length(out$wealth_d1[out$wave == 1])
length(out$wealth_d1[out$wave == 1 & out$imputed == FALSE])

# Calculate cross-wave correlations to assess stability of wealth indices
# Limited to first 7000 observations for matched sample comparison
mx <- 7000

# Regular data: correlation between wave 1 and wave 3
cor(out$wealth_d1[out$wave == 1 & out$imputed == FALSE][1:mx], out$wealth_d1[out$wave == 3 & out$imputed == FALSE][1:mx])  # dimension 1
cor(out$wealth_d2[out$wave == 1 & out$imputed == FALSE][1:mx], out$wealth_d2[out$wave == 3 & out$imputed == FALSE][1:mx])  # dimension 2

# Imputed data: correlation between wave 1 and wave 3
cor(out$wealth_d1[out$wave == 1 & out$imputed == TRUE][1:mx], out$wealth_d1[out$wave == 3 & out$imputed == TRUE][1:mx])   # dimension 1
cor(out$wealth_d2[out$wave == 1 & out$imputed == TRUE][1:mx], out$wealth_d2[out$wave == 3 & out$imputed == TRUE][1:mx])   # dimension 2

# Important note about dimension orientation:
# Wave 1 dim 1 is in correct direction (higher = wealthier)
# Wave 3 dim 1 must be flipped (sign reversed) to match wave 1 orientation
# This is a known issue with MCA where dimension signs can flip between analyses

# Write final wealth index to file
write_csv(out, "mca/wealth_index.csv")
