module HondurasTools
    # exports are in source files

    using Reexport

    @reexport using DataFrames, DataFramesMeta, Dates, CategoricalArrays
    @reexport using Skipper

    @reexport import CSV, JSONTables
    @reexport using JLD2

    @reexport using StatsBase, Statistics, Distributions
    @reexport using Lasso, GLM, MixedModels
    @reexport using StatsModels
    @reexport using Distributions
    @reexport using StandardizedPredictors, Effects

    @reexport using Graphs, MetaGraphs, GraphDataFrameBridge

    using StatsFuns:logistic
    export logistic

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

    # effects analysis
    include("EModel.jl")
    include("effects_utilities.jl")
    include("errors.jl")

    for x in [
        "analysis_utilities.jl",
        "variables.jl", "standardize.jl",
        "code_variables.jl",
    ]
        include("working/" * x)
    end

    # output paths
    npath = "new-analysis-report/objects/";
    ppath = (b = "css-paper/", t = "tables/", f = "figures/");

    # Reports paths
    prj = (
        pp = "./honduras-reports/",
        dev = "development/",
        ind = "indigeneity/",
        cop = "cooperation/",
        rel = "religion/",
        net = "network/",
        css = "CSS/",
        int = "intervention/",
        apx = "appendix/"
    )

    datapath = "clean_data/"

    # data date
    dte = "2023-11-20"

    export prj, npath, ppath, datapath, dte
end
