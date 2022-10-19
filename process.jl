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

# load data
resp = [
    CSV.read(df, DataFrame; missingstring = "NA") for df in respondent_paths
];

@time resp = clean_respondent(
   resp, [1,2,3]; nokeymiss = true, selected = nothing
);

@time hh = clean_household(hh_paths; selected = nothing)

# microbiome data

cohort1pth = "COHORT_1/v1/hmb_respondents_cohort1_baseline_v1_E_FELTHAM_2022-09-08.csv";
cohort2pth = "COHORT_2/v1/hmb_respondents_cohort2_v1_E_FELTHAM_2022-09-08.csv";

@time mb = clean_microbiome(cohort1pth, cohort2pth);

dropmissing!(resp, :village_code);
dropmissing!(hh, :village_code);
dropmissing!(mb, :village_code);

select!(resp, Not([:household_id, :skip_glitch]))
select!(hh, Not([:household_id, :skip_glitch]))

rename!(hh, :survey_start => :hh_survey_start)
rename!(hh, :new_building => :hh_new_building)

dropmissing!(hh, :building_id)

sum(ismissing(hh.building_id))
sum(ismissing(resp.building_id))

sum(ismissing(hh.village_code))
sum(ismissing(resp.village_code))

sum(ismissing(hh.wave))
sum(ismissing(resp.wave))

dat = leftjoin(
    resp, hh,
    on = [
        :building_id, :village_code, :wave,
        :office, :municipality, :village_name
    ]
);

# for mb join, we need to handle the waves somehow
rename!(mb, :lives_in_village => :mb_lives_in_village, :works_in_village => :mb_works_in_village)
mdat = leftjoin(mb, @subset(dat, :wave .== 3), on = [:name, :village_code]);

# network data

con_paths = [
    "/WORKAREA/work/HONDURAS_GATES/E_FELTHAM/WAVE1/v8_2021-03/honduras_connections_WAVE1_v8.csv",
    "/WORKAREA/work/HONDURAS_GATES/E_FELTHAM/WAVE2/v5_2021-03/honduras_connections_WAVE2_v5.csv",
    "/WORKAREA/work/HONDURAS_GATES/E_FELTHAM/WAVE3/v3_2021-03/honduras_connections_WAVE3_v3.csv"
];

conns = [CSV.read(
        con_path, DataFrame; missingstring = "NA"
    ) for con_path in con_paths];

@time con = clean_connections(
    conns; alter_source = true, same_village = true
);

# unique(conns.relationship)
core = ["personal_private", "closest_friend", "free_time"];
health = ["health_advice_get", "health_advice_give"];

nf = begin
    mbcodes = sort(unique(mb.village_code)); # relevant villages
    rels = sort(unique(con.relationship));
    
    # union network
    nf = DataFrame();

    for w in 1:3
    
        # unionels = @subset(conns, :wave .== w); # all ties
        
        unionels = @subset(
            con, :wave .== w, :relationship .∈ Ref(core)
        ); # all ties

        # network calculations
        nfi = egoreducts(unionels, mbcodes, :village_code);
        nfi[!, :wave] .= w
        append!(nf, nfi)
    end

    nf
end

mdat = @chain nf begin
    select([:name, :village_code, :degree, :wave])
    unstack([:name, :village_code], :wave, :degree)
    rename(Symbol(1) => :degree_w1, Symbol(2) => :degree_w2, Symbol(3) => :degree_w3)
    dropmissing([:degree_w1, :degree_w3])
    @transform(:Δdegree = :degree_w3 - :degree_w1)
    leftjoin(mdat, _, on = [:village_code, :name])
end

# mdat = leftjoin(
#     mdat, select(@subset(nf, :wave .== 3), Not(:wave)), on = [:name, :village_code]
# );

mb = begin
    X = select(@subset(nf, :wave .== 1), [:name, :village_code, :degree])
    rename!(X, :degree => :degree_w1)
    leftjoin(mb, X, on = [:village_code, :name])
end

import JLD2
JLD2.save_object("mb_processed.jld2", mb)

mb_desc = describe(mb);
