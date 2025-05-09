# HondurasTools.jl

module HondurasTools
    # exports are in source files

    using Reexport

    @reexport using DataFrames, DataFramesMeta, Dates, CategoricalArrays
    @reexport using Skipper

    @reexport import CSV, JSONTables
    # @reexport using JLD2
    using BSON

    @reexport using StatsBase, Statistics, Distributions
    @reexport using StatsModels
    @reexport using LinearAlgebra

    @reexport using Graphs, MetaGraphs, GraphDataFrameBridge

    import Distances.haversine

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
    include("risk_process.jl")

    # updated in my fork of the package
    # so just use that
    # include("graphdataframe.jl")

    # data processing
    include("process_respondent.jl")
    include("process_household.jl")
    include("process_village.jl")
    include("processing.jl")
    include("household_pairs.jl")
    include("household_distances.jl")
    include("prepare_for_bson.jl")

    # network utilities
    include("addsymmetric.jl")
    include("jointnetwork.jl")
    include("constraint.jl")
    include("tiestrength.jl")

    # network processing
    include("networkinfo.jl")

    include("neighbors.jl")

    include("variables.jl")
    include("standardize.jl")
    include("code_variables.jl")

    # output paths
    npath = "new-analysis-report/objects/";

    datapath = "clean_data/"

    # data date
    dte = "2024-02-18"

    # household distances
    export household_distances, distance_df
    export add_building_info!, hh_distances
    export prepare_for_bson

    export npath, datapath, dte
end
