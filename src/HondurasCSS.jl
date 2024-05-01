module HondurasCSS

import Base.getindex

import Pkg
using Reexport

# add "." when running these here, "." for external usage
# (total of two dots)
Pkg.develop(path = "./HondurasTools.jl"); # general functions, definitions
Pkg.develop(path = "./NiceDisplay.jl"); # tables, figures, quarto

@reexport using HondurasTools
@reexport using NiceDisplay

import HondurasTools.sortedges!

# other dependencies
using GeometryBasics
using Random

import MultivariateStats # stressfocus.jl
import NiceDisplay.LinearAlgebra:norm

using KernelDensity

#=
Only include packages that are not already exported by HondurasTools
and NiceDisplay
=#

# CairoMakie, AlgebraOfGraphics # exported from NiceDisplay
# DataFrames, DataFramesMeta # exported from NiceDisplay

# modeling
@reexport using GLM
@reexport using MixedModels

# @reexport using Lasso
@reexport using Effects
# StandardizedPredictors # no longer using this

using StatsFuns: logistic, logit
export logistic, logit

files_fg = "figures/" .* [
    "plotting.jl",
    "figure_utilities.jl", "stressfocus.jl",
    "unitbarplot.jl",
    "backgroundplot.jl",
    "rocplot.jl",
    "effectsplot.jl",
    "biplot.jl", "interface_plot.jl",
    "roc-style.jl", "roc-pred.jl",
    "tiedist.jl", "pairdist.jl",
    "clustdiff.jl",
    "individualpredictions!.jl",
    "bivariate_perceiver.jl",
    "coefplot.jl",
    "distanceplot.jl",
    "stage2_figure.jl",
    "riddle_plot!.jl",
    "homophily_plot.jl",
    # paper figures
    "figure2.jl"
];
for x in files_fg; include(x) end

files_an = "analysis/" .* [
    "accuracies.jl", "accuracy_functions.jl", "bootmargins.jl",
    "riddles_functions.jl",
    "riddles_functions_pbs.jl",
    "parametricbootstrap2.jl",
    "tpr_fpr_functions_pbs.jl",
    "stage2.jl",
    "homophily.jl",
    "effects!.jl",
    "newstrap.jl"
];

for x in files_an; include(x) end

files_g = [
    "EModel.jl", "errors.jl",
    "effects_utilities.jl", "analysis_utilities.jl",
    "variables.jl"
];

for x in files_g; include(x) end

files_p = "process/" .* [
    "clean_css.jl", "css_process_raw.jl",
    "cssdistances_without_ndf.jl", "cssdistances.jl",
    "groundtruth.jl"
];

for x in files_p; include(x) end

end # module HondurasCSS
