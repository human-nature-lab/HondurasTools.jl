# HondurasTools.jl

module HondurasTools
    # exports are in source files

    using Reexport

    @reexport using DataFrames, DataFramesMeta, Dates, CategoricalArrays
    @reexport using Skipper

    @reexport import CSV, JSONTables
    @reexport using JLD2

    @reexport using StatsBase, Statistics, Distributions
    @reexport using StatsModels
    @reexport using Distributions, LinearAlgebra

    @reexport using Graphs, MetaGraphs, GraphDataFrameBridge

    # utilities
    include("utilities.jl")
    include("leveljoins!.jl")
    include("groupdescribe.jl")
    include("sortedges!.jl")

    # data cleaning
    include("cleaningtools.jl")
    include("cleaningutilities.jl")
    include("clean_respondent.jl")
    include("clean_perception.jl")
    include("clean_household.jl")
    include("clean_microbiome.jl")
    include("clean_connections.jl")
    include("clean_outcomes.jl")
    include("clean_village.jl")
    include("clean_ihr.jl")
    include("clean_css.jl")
    include("risk_process.jl")

    include("graphdataframe.jl")

    # data processing
    include("process_respondent.jl")
    include("process_household.jl")
    include("process_village.jl")
    include("processing.jl")

    # network utilities
    include("addsymmetric.jl")
    include("jointnetwork.jl")

    # network processing
    include("groundtruth.jl")
    include("networkinfo.jl")
    include("cssdistances_without_ndf.jl")
    include("cssdistances.jl")

    include("neighbors.jl")

    files_working = "working/" .* [
        "variables.jl", "standardize.jl",
        "code_variables.jl",
    ];
    for x in files_working; include(x) end

    # output paths
    npath = "new-analysis-report/objects/";

    datapath = "clean_data/"

    # data date
    dte = "2023-11-20"

    export npath, datapath, dte
end
