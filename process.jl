# processing

using DataFrames, DataFramesMeta
using CategoricalArrays, Dates
import CSV
using PrettyTables
# using Graphs, MetaGraphs

using HondurasTools

# useful networks
# unique(conn)

core = ["personal_private", "closest_friend", "free_time"];
health = ["health_advice_get", "health_advice_give"];

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

mb1, mb2 = [CSV.read(x, DataFrame; missingstring = "NA") for x in [cohort1pth, cohort2pth]]

# 19 villages that are in the study
microbiome_villages = load_mbvillages();

@time mb = clean_microbiome(mb1, mb2);

mb[!, :mbset] = mb.village_code .∈ Ref(microbiome_villages.village_code)

## remove entries on key variables

dropmissing!(resp, :village_code);
dropmissing!(hh, :village_code);
dropmissing!(mb, :village_code);

dropmissing!(hh, :building_id);

select!(resp, Not([:household_id, :skip_glitch]));
select!(hh, Not([:household_id, :skip_glitch]));

rename!(hh, :survey_start => :hh_survey_start);
rename!(hh, :new_building => :hh_new_building);


##

dat = leftjoin(
    resp, hh,
    on = [
        :building_id, :village_code, :wave,
        :office, :municipality, :village_name
    ]
);

## response filters

@subset!(dat, (:wave .== 3) .& (:data_source .== 1));
select!(dat, Not(:data_source));

## microbiome data join

# for mb join, we need to handle the waves somehow
rename!(
    mb,
    :lives_in_village => :mb_lives_in_village,
    :works_in_village => :mb_works_in_village
)

mdat = leftjoin(mb, dat, on = [:name, :village_code]);

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
    conns,
    [1, 2, 3];
    alter_source = true,
    same_village = true,
    removemissing = true
);

nf = let
    # filter con to the mb village codes
    mbcodes = sort(unique(mb.village_code));
    rels = sort(unique(con.relationship));
    
    # union network
    nf = DataFrame();

    for w in 1:3
    
        # unionels = @subset(conns, :wave .== w); # all ties
        
        unionels = @subset(
            con, :wave .== w, :relationship .∈ Ref(core)
        ); # all ties

        # network calculations
        nfi = egoreductions(unionels, mbcodes, :village_code);
        nfi[!, :wave] .= w
        append!(nf, nfi)
    end

    nf
end

ldrvars = [:b1000a, :b1000b, :b1000c, :b1000d, :b1000e, :b1000f, :b1000g, :b1000h];

for e in ldrvars
    resp[!, e] = replmis.(resp[!, e])
end

rename!(
    resp,
    :b1000a => :hlthprom,
    :b1000b => :commuityhlthvol,
    :b1000c => :communityboard, # (village council, water board, parents association)
    :b1000d => :patron, # (other people work for you)
    :b1000e => :midwife,
    :b1000f => :religlead,
    :b1000g => :council, # President/leader of indigenous council
    :b1000h => :polorglead, # Political organizer/leader
    # :b1000i => None of the above
)


## WRITE
import JLD2; JLD2.save_object("userfiles/mb_processed.jld2", [mdat, nf, con]);

## USE FOR SOME PURPOSES
nf = @chain nf begin
    select([:name, :village_code, :degree, :wave])
    unstack([:name, :village_code], :wave, :degree)
    rename(
        Symbol(1) => :degree_w1,
        Symbol(2) => :degree_w2,
        Symbol(3) => :degree_w3
    )
    # dropmissing([:degree_w1, :degree_w3])
    @transform(:Δdegree = :degree_w3 - :degree_w1)
end

mb_desc = describe(mb);

##