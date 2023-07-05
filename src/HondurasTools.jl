module HondurasTools

using DataFrames, DataFramesMeta
using CategoricalArrays
using Dates
using StatsBase, Statistics
using GraphTools
using Graphs

import CSV
import Base.get # method added in css_socio

include("utilities.jl")
include("cleaning_utilities.jl")
include("cleaning.jl")
include("clean_respondent.jl")
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
include("data.jl")

export 
    # cleaning
    clean_respondent, clean_microbiome, clean_household, clean_village,
    
    # networks
    clean_connections,
    process_edgelist, process_edgelist!,
    graph, egoreduction, egoreductions,
    handle_socio, reciprocated,
    initialize_networks_info, networksinfo!, nodedistances!,
    addsymmetric!, jointnetwork,
    
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
    unilen, interlen, tupleize, symmetrize!,
    
    # codebook
    load_mbvillages
    
    # re-export from GraphTools
    graph, sortedges!, symmetrize!, symmetrize, egoreduction, egoreductions, GraphTable, graphtable, nodemeasure!
end
