# Regenerate synthetic fixtures with the actual FactoMineR package:
# R_LIBS=/tmp/honduras-wealth-r-library Rscript test/generate_wealth_reference.R
# Optional first argument: output directory. No participant data are used.
args <- commandArgs(trailingOnly = TRUE)
outdir <- if (length(args)) args[1] else "test/fixtures/wealth_factominer"
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)
stopifnot(requireNamespace("FactoMineR", quietly = TRUE))
options(digits = 17)
set.seed(20261104)

make_wave <- function(n, wave, shift) {
    latent <- rnorm(n, mean = shift)
    data.frame(
        building_id = seq_len(n), wave = wave,
        tv = ifelse(runif(n) < plogis(latent), "yes", "no"),
        floor = c("earth", "wood", "tile")[findInterval(latent + rnorm(n), c(-0.5, 0.7)) + 1L],
        water = ifelse(runif(n) < plogis(latent + 0.3), "piped", "well"),
        roof = c("thatch", "metal", "concrete")[findInterval(latent + rnorm(n), c(-0.7, 1)) + 1L]
    )
}
base <- rbind(make_wave(80, 1L, 0), make_wave(50, 3L, 0.6))
cases <- list(complete = base, missing = base, constant = base, rare = base)
cases$missing$floor[c(5, 18, 31, 85, 94)] <- NA
cases$missing$water[c(6, 19, 32, 86, 95)] <- NA
cases$constant$fixed <- "same"
cases$rare$floor[c(7, 87)] <- "rare_material"
indicators <- c("tv", "floor", "water", "roof")

write_table <- function(x, file) {
    write.csv(x, file.path(outdir, file), row.names = FALSE, na = "__MISSING__")
}
for (case in names(cases)) {
    raw <- cases[[case]]
    cols <- c(indicators, if (case == "constant") "fixed")
    x <- as.data.frame(lapply(raw[cols], factor))
    active <- which(raw$wave == 1L)
    supplementary <- which(raw$wave == 3L)
    scores <- raw[c("building_id", "wave")]
    eigenvalues <- data.frame()
    for (wave in c(1L, 3L)) {
        rows <- which(raw$wave == wave)
        fit <- FactoMineR::MCA(droplevels(x[rows, , drop = FALSE]),
                              ncp = 2, graph = FALSE, na.method = "NA")
        scores[rows, c("within_d1", "within_d2")] <- fit$ind$coord[, 1:2]
        eigenvalues <- rbind(eigenvalues, data.frame(
            wave = wave, dimension = 1:2, eigenvalue = fit$eig[1:2, 1],
            # Recent FactoMineR versions retain only ncp rows in $eig.
            # Recover total inertia from the reported explained percentage.
            total_inertia = 100 * fit$eig[1, 1] / fit$eig[1, 2]
        ))
    }
    # Exercise the same supplementary-individual approach as the legacy script.
    reference <- FactoMineR::MCA(x, ind.sup = supplementary, ncp = 2,
                                 graph = FALSE, na.method = "NA")
    scores[active, c("common_d1", "common_d2")] <- reference$ind$coord[, 1:2]
    scores[supplementary, c("common_d1", "common_d2")] <- reference$ind.sup$coord[, 1:2]
    # Also verify scoring future data from a standalone fitted model.
    fitted <- FactoMineR::MCA(droplevels(x[active, , drop = FALSE]),
                              ncp = 2, graph = FALSE, na.method = "NA")
    predicted <- predict(fitted, newdata = x[supplementary, , drop = FALSE])$coord[, 1:2]
    scores[active, c("predict_d1", "predict_d2")] <- fitted$ind$coord[, 1:2]
    scores[supplementary, c("predict_d1", "predict_d2")] <- predicted
    write_table(raw, paste0(case, "_input.csv"))
    write_table(scores, paste0(case, "_scores.csv"))
    write_table(eigenvalues, paste0(case, "_eigenvalues.csv"))
}
writeLines(c(
    "Synthetic reference fixtures; no participant data.",
    "Generator: test/generate_wealth_reference.R; seed: 20261104",
    paste("FactoMineR:", packageVersion("FactoMineR")),
    trimws(capture.output(sessionInfo()), which = "right")
), file.path(outdir, "provenance.txt"))
cat("Wrote FactoMineR fixtures to", outdir, "\n")
