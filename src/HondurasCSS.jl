"""
HondurasCSS

Module for analyzing social cognitive data from Honduras research project.
Provides tools for processing, analyzing, and visualizing network perception data.
"""
module HondurasCSS

# Standard library imports
import Base.getindex

# Package management
# Note: For reproducibility, use MixedModels v4.14.0 (pre-xtol_zero_abs)
# Pkg.add(name="MixedModels", version="4.14.0")

# Core dependencies with re-exports
using Reexport
@reexport using HondurasTools
@reexport using NiceDisplay
@reexport using NiceDisplay.Graphs
@reexport using NiceDisplay.GraphMakie

# Modeling packages
@reexport using GLM
@reexport using MixedModels
@reexport using Effects

# Statistical and visualization packages
using GeometryBasics
using Random
using KernelDensity
using StatsFuns: logistic, logit
using ColorVectorSpace

# Specific imports
import HondurasTools.sortedges!
import MultivariateStats
import NiceDisplay.LinearAlgebra: norm
import GLM.Normal

# Additional exports
export logistic, logit

import BSON

# File organization by category
const CORE_FILES = [
    "EModel.jl",
    "errors.jl",
    "effects_utilities.jl",
    "analysis_utilities.jl",
    "variables.jl"
]

const FIGURE_FILES = [
    "plotting.jl",
    "figure_utilities.jl",
    "stressfocus.jl",
    "unitbarplot.jl",
    "backgroundplot.jl",
    "rocplot.jl",
    "effectsplot.jl",
    "biplot.jl",
    "interface_plot.jl",
    "roc-style.jl",
    "roc-pred.jl",
    "tiedist.jl",
    "pairdist.jl",
    "clustdiff.jl",
    "individualpredictions!.jl",
    "bivariate_perceiver.jl",
    "coefplot.jl",
    "distanceplot.jl",
    "stage2_figure.jl",
    "riddle_plot!.jl",
    "homophily_plot.jl",
    # Paper figures
    "figure1.jl",
    "figure_bivar.jl",
    "figure4_alt.jl",
    "figure4.jl",
    "interaction.jl",
    "contrasttable.jl",
    "roc_space.jl"
]

const ANALYSIS_FILES = [
    "accuracies.jl",
    "accuracy_functions.jl",
    "bootmargins.jl",
    "riddles_functions.jl",
    "riddles_functions_pbs.jl",
    "parametricbootstrap2.jl",
    "tpr_fpr_functions_pbs.jl",
    "stage2.jl",
    "homophily.jl",
    "effects!.jl",
    "newstrap.jl"
]

const PROCESS_FILES = [
    "clean_css.jl",
    "css_process_raw.jl",
    "cssdistances_without_ndf.jl",
    "cssdistances.jl",
    "groundtruth.jl"
]

# Load files by category
for file in CORE_FILES
    include(file)
end

for file in FIGURE_FILES
    include(joinpath("figures", file))
end

for file in ANALYSIS_FILES
    include(joinpath("analysis", file))
end

for file in PROCESS_FILES
    include(joinpath("process", file))
end

# Load additional standalone files
include("tie_properties.jl")
include("referencegrid.jl")
include("j_calculations.jl")
include("margincalculations.jl")
include("bootellipse.jl")
include("ratetradeoff.jl")
include("adjustedcoeftable.jl")
include(joinpath("figures", "roc_distance.jl"))
include("tpr_fpr.jl")
include(joinpath("process", "utilities.jl"))

# Final processing functions (generates the working data)
include("process/final processing.jl")

export HondurasConfig, hondurasconfig
export main, demographics, create_combined_demographics, create_css_data

const pers_vars = [
    :extraversion,
    :agreeableness,
    :conscientiousness,
    :neuroticism,
    :openness_to_experience,
];

export pers_vars


end # module HondurasCSS
