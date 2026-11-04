# Processing and analysis

## Inputs and outputs

`make_data.jl` is a delivery-specific template. Supply one DataFrame per wave and a corresponding wave vector, in the same order. The RCT cleaners combine wave tables after harmonizing columns; uncollected variables can remain missing. Missingness alone does not establish whether a question was asked: consult the study-specific codebook.

```julia
using HondurasTools
waves = [1, 2, 3]
paths = ["raw/respondents_w1.csv", "raw/respondents_w2.csv", "raw/respondents_w3.csv"]
raw = [CSV.read(path, DataFrame; missingstring="NA") for path in paths]
resp = clean_respondent(raw, waves; nokeymiss=false, onlycomplete=false)
subset!(resp, :data_source => ByRow(==("Census, survey")))
```

Paths above are illustrative. The template also processes household, village, connection, and microbiome tables and writes one dated CSV per level. It does not automatically join those outputs.

## Cleaning defaults

| Function | Default behavior and constraints |
| --- | --- |
| `clean_respondent(resp, waves)` | Does not require complete surveys or nonmissing key fields by default. Recodes `data_source` to text labels and `respondent_master_id` to `name`. |
| `clean_household(hh, waves)` | Drops rows missing `village_code` or `building_id` by default. |
| `clean_village(vdfs, waves)` | Harmonizes and recodes village tables; assumes expected delivery columns. |
| `clean_connections(conns, waves)` | Filters to the same village by default; `alter_source` filtering is off by default. |
| `clean_microbiome(mb1, mb2)` | Adds cohort indicators, retains the intersection of cohort columns, and drops missing village/person identifiers by default. |
| `clean_outcomes(dfs, waves)` | Combines tables and renames person IDs. Outcome recoding requires `codebook=cb`. |
| `clean_ihr(cop, ihr)` | Cleans cooperation and IH tables; requires the expected full schema. |

`nokeymiss=true` in `clean_respondent` removes rows missing village code, gender, date of birth, or building ID. `onlycomplete=true` restricts to completed surveys. Neither is enabled in the template.

For connections, `same_village=true` drops missing same-village indicators and keeps code 1. `alter_source=true` keeps raw code 1. `removemissing=true` calls `disallowmissing!` on ego, alter, question, alter source, and relationship: it rejects remaining missing values rather than dropping all incomplete rows. Required columns must still be present even when filtering is disabled. The cleaner converts source codes to labels after filtering.

Some recoding operations check whether variables exist, but other operations access columns unconditionally. Support for arbitrary subsets of requested variables is not guaranteed.

## Identifiers and joins

Cleaned respondent IDs use `name`; household processing uses `building_id`. Do not assume a building is a stable household across waves. Include wave and village identifiers where the intended unit requires them, and check key uniqueness before joining. The respondent cleaner removes the legacy `household_id` column.

Microbiome data are separate from the RCT wave tables. Choose and document how to handle changed villages between administrations before joining on person and village. The package includes `codebook/microbiome_villages.csv`; study-specific sample restrictions remain analysis decisions.

An edgelist omits people without recorded ties. Construct the vertex population from the appropriate respondent roster when isolates matter, and apply compatible inclusion criteria to both tables.

## Further analysis

Longitudinal utilities include `respprocess`, `householdprocess`, and `villageprocess`, with `respwave`, `hhwave`, and `villwave` for wave-specific outputs. Their carry-forward and variable-selection choices require review for the analysis; do not assume every variable is time-invariant.

Network utilities include `jointnetwork`, `addsymmetric!`, `tiestrength`, `constraint`, and neighbor-data helpers. Inspect their API documentation and required graph/table structure before use. The old `src/process_edgelist.jl` file is not included by the module and is not a supported exported entry point.
