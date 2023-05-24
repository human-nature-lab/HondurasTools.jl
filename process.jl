# process.jl
# example script for cleaning, processing, and writing the raw Honduras data
# These functions are agnostic to the specific variables requested from the specific datasets.

using DataFrames, DataFramesMeta, Dates
import CSV
using HondurasTools

# waves included in the data requested
# the paths should be in the same order
waves = [1, 2, 3];

basepath = "/WORKAREA/work/HONDURAS_GATES/E_FELTHAM/";
writepath = basepath * "clean_data/";

hh_paths =  [
    "WAVE1/v8_2021-03/honduras_households_WAVE1_v8.csv",
    "WAVE2/v5_2021-03/honduras_households_WAVE2_v5.csv",
    "WAVE3/v3_2021-03/honduras_households_WAVE3_v3.csv"
];
    
respondent_paths = [
    "WAVE1/v8_2021-03/honduras_respondents_WAVE1_v8.csv",
    "WAVE2/v5_2021-03/honduras_respondents_WAVE2_v5.csv",
    "WAVE3/v3_2021-03/honduras_respondents_WAVE3_v3.csv",
];

cohort1pth = "COHORT_1/v1/hmb_respondents_cohort1_baseline_v1_E_FELTHAM_2022-09-08.csv";
cohort2pth = "COHORT_2/v1/hmb_respondents_cohort2_v1_E_FELTHAM_2022-09-08.csv";

con_paths = [
    "WAVE1/v8_2021-03/honduras_connections_WAVE1_v8.csv",
    "WAVE2/v5_2021-03/honduras_connections_WAVE2_v5.csv",
    "WAVE3/v3_2021-03/honduras_connections_WAVE3_v3.csv"
];

# village paths

village_paths = [
    
]

# load data

resp = [
    CSV.read(basepath * x, DataFrame; missingstring = "NA") for x in respondent_paths
];

@time resp = clean_respondent(
   resp, waves; nokeymiss = true, selected = nothing
);

hh = [CSV.read(basepath * x, DataFrame; missingstring = "NA") for x in hh_paths];
@time hh = clean_household(hh; selected = nothing);

# microbiome data

mb1, mb2 = [
    CSV.read(basepath * x, DataFrame; missingstring = "NA") for x in [cohort1pth, cohort2pth]
];

@time mb = clean_microbiome(mb1, mb2);

# village data

vdfs = [
    CSV.read(
        basepath * vpth, DataFrame; missingstring = "NA"
    ) for vpth in village_paths
];

vdf = clean_village(vdfs, waves)

# network data

conns = [CSV.read(
        basepath * con_path, DataFrame; missingstring = "NA"
    ) for con_path in con_paths];

@time con = clean_connections(
    conns,
    waves;
    alter_source = true,
    same_village = true,
    removemissing = true
);

# filter to relevant data desired

# response filters
# filter to data_source = 1
@subset!(dat, :data_source .== 1);
select!(dat, Not(:data_source));

# write

CSV.write(writepath * "resp_data_" * string(today()), resp);
CSV.write(writepath * "household_data_" * string(today()), hh);
CSV.write(writepath * "village_data_" * string(today()), vdf);
CSV.write(writepath * "microbiome_data_"  * string(today()), mdat);
CSV.write(writepath * "connections_data_"  * string(today()), con);
