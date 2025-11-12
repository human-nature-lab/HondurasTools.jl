# Multiple Correspondence Analysis (MCA) for Honduras Wealth Index
# Wave 1 Reference Approach for Comparable Wealth Measures Across Waves
# Based on https://dhsprogram.com/topics/wealth-index/Wealth-Index-Construction.cfm
#
# This script:
# 1. Uses Wave 1 to define the wealth coordinate system (active individuals)
# 2. Projects Wave 3 households onto the Wave 1 system (supplementary individuals)
# 3. Creates comparable wealth indices across waves for tracking changes
# 4. Works correctly even if household composition differs between waves
# 5. Compares regular vs imputed data versions

# (NEED TO CHECK OVER THIS SCRIPT)

library("readr")
library("tibble")
library("FactoMineR")

# Perform MCA using Wave 1 as reference
#
# Wave 1 households define the wealth axes (active individuals)
# Wave 3 households are projected onto those axes (supplementary individuals)
# This creates a stable wealth metric comparable across waves
#
# Args:
#   dfpca_w: dataframe with wealth indicators, building_id, and wave columns
#
# Returns:
#   MCA object with Wave 1 defining axes, Wave 3 coordinates in $ind.sup
wavemca_reference <- function(dfpca_w) {

    # Split data by wave
    dfpca_w_w1 <- dfpca_w[dfpca_w$wave == 1, ]
    dfpca_w_w3 <- dfpca_w[dfpca_w$wave == 3, ]

    # Store IDs before removing (needed for output dataframe)
    bd_w1 <- dfpca_w_w1$building_id
    bd_w3 <- dfpca_w_w3$building_id

    # Remove ID and wave columns before MCA
    dfpca_w_w1$building_id <- NULL
    dfpca_w_w3$building_id <- NULL
    dfpca_w_w1$wave <- NULL
    dfpca_w_w3$wave <- NULL

    # Combine waves: Wave 1 first (active), then Wave 3 (supplementary)
    dfpca_combined <- rbind(dfpca_w_w1, dfpca_w_w3)
    n_w1 <- nrow(dfpca_w_w1)
    ind_sup <- (n_w1 + 1):nrow(dfpca_combined)  # Row indices for Wave 3

    # Perform MCA with:
    # - Columns 14 & 15 as supplementary quantitative vars (peopleperroom, incomesuff)
    # - Wave 3 individuals as supplementary (don't influence axes)
    res.mca <- MCA(dfpca_combined,
                   quanti.sup = c(14, 15),
                   ind.sup = ind_sup,
                   graph = FALSE)

    # Store building IDs in the result for later use
    res.mca$building_ids <- list(wave1 = bd_w1, wave3 = bd_w3)

    return(res.mca)
}

# Generate diagnostic plots for MCA results
#
# Creates plots showing:
#   - mca1: Individual factor map (Wave 1 only)
#   - mca2: Variable categories map
#   - mca3: Biplot with supplementary vars
#   - mca1_w1: Wave 1 individuals
#   - mca1_w3: Wave 3 individuals (supplementary)
#   - mca1_both: Both waves overlaid
#
# Args:
#   res: MCA result from wavemca_reference()
#   sfx: suffix for filename (e.g., "reg" for regular, "imp" for imputed)
mcaplots_reference <- function(res, sfx) {
    sfx <- paste0("_", sfx)
    pth <- "honduras-reports/development/mca/"
    fext <- ".png"

    # Plot 1: Wave 1 individuals only (active individuals)
    png(file = paste0(pth, "mca1_w1", sfx, fext))
        plot.MCA(res, invisible = c("var", "quanti.sup", "ind.sup"), cex = 0.7)
    dev.off()

    # Plot 2: Variable categories map
    png(file = paste0(pth, "mca2_vars", sfx, fext))
        plot.MCA(res, invisible = c("ind", "quanti.sup", "ind.sup"), cex = 0.7)
    dev.off()

    # Plot 3: Biplot with supplementary variables
    png(file = paste0(pth, "mca3_biplot", sfx, fext))
        plot.MCA(res, invisible = c("ind", "ind.sup"))
    dev.off()

    # Plot 4: Wave 3 individuals (supplementary)
    png(file = paste0(pth, "mca1_w3", sfx, fext))
        plot.MCA(res, invisible = c("var", "quanti.sup", "ind"), cex = 0.7)
    dev.off()

    # Plot 5: Both waves overlaid (to see distribution shifts)
    png(file = paste0(pth, "mca1_both", sfx, fext))
        plot.MCA(res, invisible = c("var", "quanti.sup"), cex = 0.7)
    dev.off()

    # Plot 6: Confidence ellipses
    png(file = paste0(pth, "mca_ellipse", sfx, fext))
        plotellipses(res)
    dev.off()
}

# Extract MCA coordinates and create tidy dataframe for analysis
#
# Extracts coordinates from both active (Wave 1) and supplementary (Wave 3) individuals
# Both waves are now in the same coordinate system and directly comparable
#
# Args:
#   res: MCA result from wavemca_reference()
#   dfpca_w: original dataframe (only used to get wave numbers)
#
# Returns:
#   tibble with columns: building_id, wave, wealth_d1, wealth_d2
mca_df_reference <- function(res, dfpca_w) {

    # Extract Wave 1 coordinates (active individuals)
    d1_w1 <- res$ind$coord[, 1]
    d2_w1 <- res$ind$coord[, 2]

    # Extract Wave 3 coordinates (supplementary individuals)
    d1_w3 <- res$ind.sup$coord[, 1]
    d2_w3 <- res$ind.sup$coord[, 2]

    # Get building IDs from stored values
    bd_w1 <- res$building_ids$wave1
    bd_w3 <- res$building_ids$wave3

    # Create wave indicators
    wv_w1 <- rep(1, length(bd_w1))
    wv_w3 <- rep(3, length(bd_w3))

    # Combine both waves
    d1 <- c(d1_w1, d1_w3)
    d2 <- c(d2_w1, d2_w3)
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

# Perform MCA using Wave 1 reference approach
res_w <- wavemca_reference(dfpca_w)  # regular version
res_i <- wavemca_reference(dfpca_i)  # imputed version

# Optional: examine dimension descriptions
# dimdesc(res_w)

# Generate diagnostic plots for both versions
mcaplots_reference(res_w, "reg")  # regular data plots
mcaplots_reference(res_i, "imp")  # imputed data plots

## ============================================================================
## OUTPUT: Extract wealth indices and save results
## ============================================================================

# Extract MCA coordinates into dataframes
df_w <- mca_df_reference(res_w, dfpca_w)
df_w$imputed <- FALSE  # flag for regular data
df_i <- mca_df_reference(res_i, dfpca_i)
df_i$imputed <- TRUE   # flag for imputed data

# Combine both versions into single output
out <- rbind(df_w, df_i)

# Diagnostic: check sample sizes
cat("Total observations:", nrow(out), "\n")
cat("Wave 1 (regular):", sum(out$wave == 1 & !out$imputed), "\n")
cat("Wave 3 (regular):", sum(out$wave == 3 & !out$imputed), "\n")
cat("Wave 1 (imputed):", sum(out$wave == 1 & out$imputed), "\n")
cat("Wave 3 (imputed):", sum(out$wave == 3 & out$imputed), "\n")

# Calculate cross-wave correlations to assess stability
# For matched households only (households present in both waves)
# This requires matching by building_id

# Get matched households for regular data
matched_regular <- merge(
    df_w[df_w$wave == 1, c("building_id", "wealth_d1", "wealth_d2")],
    df_w[df_w$wave == 3, c("building_id", "wealth_d1", "wealth_d2")],
    by = "building_id",
    suffixes = c("_w1", "_w3")
)

cat("\nMatched households (regular):", nrow(matched_regular), "\n")
cat("Correlation of wealth_d1 between waves:",
    cor(matched_regular$wealth_d1_w1, matched_regular$wealth_d1_w3), "\n")
cat("Correlation of wealth_d2 between waves:",
    cor(matched_regular$wealth_d2_w1, matched_regular$wealth_d2_w3), "\n")

# Same for imputed data
matched_imputed <- merge(
    df_i[df_i$wave == 1, c("building_id", "wealth_d1", "wealth_d2")],
    df_i[df_i$wave == 3, c("building_id", "wealth_d1", "wealth_d2")],
    by = "building_id",
    suffixes = c("_w1", "_w3")
)

cat("\nMatched households (imputed):", nrow(matched_imputed), "\n")
cat("Correlation of wealth_d1 between waves:",
    cor(matched_imputed$wealth_d1_w1, matched_imputed$wealth_d1_w3), "\n")
cat("Correlation of wealth_d2 between waves:",
    cor(matched_imputed$wealth_d2_w1, matched_imputed$wealth_d2_w3), "\n")

# Calculate mean changes for matched households
cat("\nMean change in wealth_d1 (regular):",
    mean(matched_regular$wealth_d1_w3 - matched_regular$wealth_d1_w1), "\n")
cat("Mean change in wealth_d2 (regular):",
    mean(matched_regular$wealth_d2_w3 - matched_regular$wealth_d2_w1), "\n")

# Write final wealth index to file
write_csv(out, "mca/wealth_index_reference.csv")

cat("\nWealth index saved to: mca/wealth_index_reference.csv\n")
