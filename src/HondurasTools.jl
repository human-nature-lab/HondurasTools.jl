module HondurasTools

using DataFrames, DataFramesMeta
using CategoricalArrays
using Dates
using StatsBase, Statistics
using Graphs, MetaGraphs, GraphDataFrameBridge
using CategoricalArrays, Skipper

import CSV
import Base.get # method added in css_socio

rms = ["Don't know", "Don't Know", "Dont_Know", "Refused", "Removed"];
freqscale = ["Never", "Rarely", "Sometimes", "Always"];
goodness = ["Bad", "Neither", "Good"];

include("utilities.jl")
include("cleaning_utilities.jl")
include("cleaning.jl")
include("clean_respondent.jl")
include("clean_perception.jl")
include("clean_household.jl")
include("clean_microbiome.jl")
include("clean_connections.jl")
include("clean_village.jl")
include("updatevalues!.jl")
include("clean_css.jl")
include("prepare_css.jl")
include("css_socio.jl")
include("handle_socio.jl")
include("process_edgelist.jl")
include("risk_process.jl")
include("addsymmetric.jl")
include("jointnetwork.jl")
include("loaddata.jl")
include("networktools.jl")
include("groundtruth.jl")
include("clean_ihr.jl")

include("networkinfo.jl")
include("cssdistances.jl")
include("graphdataframe.jl")
include("sortedges!.jl")
include("EModel.jl")
include("effects_utilities.jl")

include("grabmissing!.jl")
include("leveljoins!.jl")
include("groupdescribe.jl")
include("cleaningtools.jl")

export 
    # cleaning
    clean_respondent, clean_microbiome, clean_household, clean_village,
    clean_perception!, 
    clean_ihr, code_cop!, code_ihr!, updatevalues!,
    node_fund, g_fund,
    
    # networks
    clean_connections,
    handle_socio, reciprocated,
    nodedistances!,
    addsymmetric!, shiftkin!, jointnetwork,
    
    # css
    prepare_css, # old
    clean_css!,
    groundtruth,
    assign_kin!,

    # data
    transformunitvalues,
    
    # utilities
    updatevalues!,
    sortedges!, symmetrize!,
    unilen, interlen, symmetrize!,
    # tupleize
    
    # codebook
    load_mbvillages,

    # networkinfo
    network_info!, join_ndf_cr!, modudict, node_fund, g_fund,
    # cssdistances
    perceiver_distances!,
    
    sortedges!,

    # utilities
    tryindex,
    sunique, 
    sa,
    irrelreplace!, binarize!,

   # graphs
   names, MetaGraph,
   DataFrame

   include("errors.jl")

    using Reexport

    @reexport using DataFrames, DataFramesMeta, Dates, CategoricalArrays

    @reexport import CSV, JSONTables
    @reexport using StatsModels
    @reexport using StandardizedPredictors, Effects

    @reexport using Skipper

    @reexport using StatsBase, Statistics, Distributions
    @reexport using Lasso, GLM, MixedModels

    @reexport using Graphs, MetaGraphs, GraphDataFrameBridge
    @reexport using Distributions

    @reexport using JLD2

    using StatsFuns:logistic
    export logistic

    # exports are in the files
    for x in [
        "analysis_utilities.jl", "variables.jl", "standardize.jl", "code_variables.jl", "variable_update.jl", "socionew.jl"
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
        apx = "appendix/"
    )

    # data date
    dte = "2023-11-15"
    export prj, npath, ppath, dte
end
