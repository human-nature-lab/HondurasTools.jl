# check el chilar lists

import Pkg; Pkg.activate(".");

using DataFrames, DataFramesMeta
import CSV

using HonCog

include("dataprocess.jl")

pth = "/WORKAREA/work/HONDURAS_GATES/E_FELTHAM/CSS/pilot_data";

files = [
    "CSS_edge_export_2022-08-23.csv",
    "CSS_raw_data_2022-08-23.csv",
    "CSS_pilot_data_2022-08-23.csv",
    "hw4_pilot_edges_e_feltham_2022-08-23.csv",
    # "extra_rows_2022-09-02.csv",
    "hw4_pilot_respondents_e_feltham_2022-08-23.csv"
];

key, raw, pd, edges, resp = [
    CSV.read(pth * "/" * file, DataFrame) for file in files
];

key = process_key(key);

css_relationships = [
    # "town_leaders"
    "mother"
    "father"
    "sibling"
    "child_over12_other_house"
    "partner"
    "personal_private"
    "free_time"
    # "trust_borrow_money"
    # "trust_lend_money"
    # "health_advice_get"
    # "health_advice_give"
    # "not_get_along"
    # "provider"
    # "religious_service"
    # "closest_friend"
];

#### EDGES

# edges seems to be just the filtered sociocentric network

process_edges!(edges, css_relationships)

names(pd)

# does this match socio?
# find socio data for el chilar

#### RAW

names(raw)

raw.eg0100_r01[1]
raw.eg0100_r02[1]

raw.eg0500_r01[1]
raw.eg0500_r01[2]

nm = names(raw);

## raw data appears to be one row for each survey
# we have a list of forty pairs
# and the responses as separate columns

out = process_raw(raw, key)

# edge id / ego alter know

eids = sort(unique(out.edge_id))
perceivers = sort(unique(out.perceiver))

@subset(out, :edge_id .== eids[4])

sb = sort(@subset(out, (:question .== 1) .| (:question .== 2)), [:perceiver, :edge_id])


for pid in perceivers
    for eid in eids
        xx = @subset(sb, :edge_id .== eid, :perceiver .== pid)
    end
end

# estimate of the number of responses that we should have:
length(unique(raw.respondent_master_id)) * 40 * 6
# which is roughly what we actually get
nrow(out)

nrow(pd) * 6

# eg0100 ... eg0600
# r01 ... r80

ln = raw.eg9999[1];
lnp = split(ln, ";");

intersect(lnp, pd.edge_id)

setdiff(out.edge_id, pd.edge_id)

unique(out.edge_id)
unique(pd.edge_id)

CompSet = Vector{Tuple{String, String}};

compset = CompSet();

for r in eachrow(pd)
    push!(compset, (r.respondent_master_id, r.edge_id))
end

compset_out = CompSet();

for r in eachrow(out)
    push!(compset_out, (r.perceiver, r.edge_id))
end

compset_out = unique(compset_out)

# these are missing from pd
compset_diff = setdiff(compset_out, compset);

out_idx = Int[]
for tpl in compset_diff
    append!(
        out_idx,
        findfirst((out.perceiver .== tpl[1]) .& (out.edge_id .== tpl[2]))
    )
end

(nrow(out) - (nrow(pd) * 6)) / 6
outmis = out[out_idx,:]
