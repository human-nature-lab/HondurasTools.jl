# make_data.jl
# example script for cleaning, processing, and writing the raw Honduras data
# These functions are agnostic to the specific variables requested from the specific datasets.
# If running in REPL, should open the REPL from top level of project directory

import Pkg;
Pkg.activate(".")
Pkg.instantiate()

using DataFrames, DataFramesMeta, Dates
import CSV
using HondurasTools

# waves included in the data requested
# the paths should be in the same order as waves
waves = [1, 2, 3];

basepath = "../" # "/WORKAREA/work/HONDURAS_GATES/E_FELTHAM/";
writepath = "clean_data/";

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

mbpath = "/WORKAREA/work/HONDURAS_MICROBIOME/E_FELTHAM/";

cohort1pth = "COHORT_1/v1/hmb_respondents_cohort1_baseline_v1_E_FELTHAM_2022-09-08.csv";
cohort2pth = "COHORT_2/v1/hmb_respondents_cohort2_v1_E_FELTHAM_2022-09-08.csv";

con_paths = [
    "WAVE1/v8_2021-03/honduras_connections_WAVE1_v8.csv",
    "WAVE2/v5_2021-03/honduras_connections_WAVE2_v5.csv",
    "WAVE3/v3_2021-03/honduras_connections_WAVE3_v3.csv"
];

# village paths

village_paths = [
    "WAVE1/v8_2021-03/honduras_villages_WAVE1_v8.csv",
    "WAVE2/v5_2021-03/honduras_villages_WAVE2_v5.csv",
    "WAVE3/v3_2021-03/honduras_villages_WAVE3_v3.csv"    
];

# load data

resp = [
    CSV.read(basepath * x, DataFrame; missingstring = "NA") for x in respondent_paths
];

@time resp = clean_respondent(resp, waves);

hh = [CSV.read(basepath * x, DataFrame; missingstring = "NA") for x in hh_paths];
@time hh = clean_household(hh, waves);

# microbiome data

mb1, mb2 = [
    CSV.read(mbpath * x, DataFrame; missingstring = "NA") for x in [cohort1pth, cohort2pth]
];

@time mb = clean_microbiome(mb1, mb2);

# village data

vdfs = [
    CSV.read(
        basepath * vpth, DataFrame; missingstring = "NA"
    ) for vpth in village_paths
];

vdf = clean_village(vdfs, waves);

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

#= filter to relevant data desired
- filter data_source to 1
- remove alter_source since it is already filtered to 1
=#

@subset!(resp, :data_source .== 1);
select!(resp, Not(:data_source));
select!(con, Not(:alter_source));

# write
if "clean_data" ∉ readdir()
    mkdir("clean_data")
end

CSV.write(writepath * "respondent_data_" * string(today()) * ".csv", resp);
CSV.write(writepath * "household_data_" * string(today()) * ".csv", hh);
CSV.write(writepath * "village_data_" * string(today()) * ".csv", vdf);
CSV.write(writepath * "microbiome_data_"  * string(today()) * ".csv", mb);
CSV.write(writepath * "connections_data_"  * string(today()) * ".csv", con);
