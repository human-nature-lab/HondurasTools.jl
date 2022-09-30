# processing

using DataFrames, DataFramesMeta, GLM, Statistics, StatsBase
using MixedModels, CategoricalArrays, Dates
import CSV

using Graphs, MetaGraphs
# using CairoMakie, AlgebraOfGraphics

using HondurasTools

# respondent data

outcomes_w3_pth = "/WORKAREA/work/HONDURAS_GATES/E_FELTHAM/WAVE3/v3_2021-03/honduras_outcomes_WAVE3_v3.csv";

hh_paths =  [
    "/WORKAREA/work/HONDURAS_GATES/E_FELTHAM/WAVE1/v8_2021-03/honduras_households_WAVE1_v8.csv",
    "/WORKAREA/work/HONDURAS_GATES/E_FELTHAM/WAVE2/v5_2021-03/honduras_households_WAVE2_v5.csv",
    "/WORKAREA/work/HONDURAS_GATES/E_FELTHAM/WAVE3/v3_2021-03/honduras_households_WAVE3_v3.csv"
];

respondent_paths = [
    "/WORKAREA/work/HONDURAS_GATES/E_FELTHAM/WAVE1/v8_2021-03/honduras_respondents_WAVE1_v8.csv",
    "/WORKAREA/work/HONDURAS_GATES/E_FELTHAM/WAVE2/v5_2021-03/honduras_respondents_WAVE2_v5.csv",
    "/WORKAREA/work/HONDURAS_GATES/E_FELTHAM/WAVE3/v3_2021-03/honduras_respondents_WAVE3_v3.csv",
];

@time resp = clean_respondent(
    respondent_paths; nokeymiss = true, selected = nothing
);

@time hh = clean_household(hh_paths; selected = nothing)

# microbiome data

cohort1pth = "COHORT_1/v1/hmb_respondents_cohort1_baseline_v1_E_FELTHAM_2022-09-08.csv";
cohort2pth = "COHORT_2/v1/hmb_respondents_cohort2_v1_E_FELTHAM_2022-09-08.csv";

@time mb = clean_microbiome(cohort1pth, cohort2pth);

dropmissing!(mb, :village_code);
mbr = leftjoin(mb, r3, on = [:name, :village_code]);

nrow(mb)
sum(.!ismissing.(mb.risk_score))

# network data

con_paths = [
    "/WORKAREA/work/HONDURAS_GATES/E_FELTHAM/WAVE1/v8_2021-03/honduras_connections_WAVE1_v8.csv",
    "/WORKAREA/work/HONDURAS_GATES/E_FELTHAM/WAVE2/v5_2021-03/honduras_connections_WAVE2_v5.csv",
    "/WORKAREA/work/HONDURAS_GATES/E_FELTHAM/WAVE3/v3_2021-03/honduras_connections_WAVE3_v3.csv"
];

@time con = clean_connections(
    con_paths; alter_source = true, same_village = true
);

# unique(conns.relationship)
core = ["personal_private", "closest_friend", "free_time"];
health = ["health_advice_get", "health_advice_give"];

nf = begin
    mbcodes = sort(unique(mb.village_code)); # relevant villages
    rels = sort(unique(conns.relationship));
    
    # union network
    nf = DataFrame();

    for w in 1:3
    
        unionels = @subset(conns, :wave .== w); # all ties
        
        unionels = @subset(
            conns, :wave .== w, :relationship .∈ Ref(core)
        ); # all ties

        # network calculations
        nfi = egoreducts(unionels, mbcodes, :village_code);
        nfi[!, :wave] .= w
        append!(nf, nfi)
    end

    nf
end

mb = leftjoin(mbr, @subset(nf, :wave .== 3), on = [:name, :village_code]);
r3 = leftjoin(r3, @subset(nf, :wave .== 3), on = [:name, :village_code]);

mb = begin
    X = select(@subset(nf, :wave .== 1), [:name, :village_code, :degree])
    rename!(X, :degree => :degree_w1)
    leftjoin(mb, X, on = [:village_code, :name])
end

import JLD2
JLD2.save_object("mb_processed.jld2", mb)

mb_desc = describe(mb);
