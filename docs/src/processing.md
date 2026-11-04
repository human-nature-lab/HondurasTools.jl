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
| `clean_microbiome(mb1, mb2)` | Adds cohort indicators, retains the union of cohort columns (absent values become missing), and drops missing village/person identifiers by default. |
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

## Validation and partial responses

Donation amounts in microbiome data accept numeric integers and integer strings. Missing or unparseable text becomes missing; fractional numeric amounts raise an error. The donation column may be absent.

Outcome treatment flags preserve missing values and require nonmissing codes to be 0 or 1. Known OCR errors in outcome classifications are normalized by the codebook loader; unknown classifications raise an error rather than silently skipping recoding.

For a terminal risk response without its preceding-stage response, the terminal risk score is retained while the unavailable green and purple scores remain missing. This does not reconstruct unobserved choices.

## Repeated HMB administrations

The two-table call still means cohort 1 baseline and cohort 2. For follow-up data, specify the codebook administration IDs explicitly:

```julia
mb = clean_microbiome([baseline, followup, cohort2], [1, 2, 3])
```

Outputs retain `cohort` and `administration`. Person/cohort/administration is the observation key, including for risk scoring and its join back to survey data. Repeated people across administrations are retained; duplicate observations within an administration raise an error. Inputs to this cleaner are copied. Missing identifiers are dropped with `nokeymiss=true`; otherwise records remain, but missing person identifiers are not assigned risk scores. Do not join repeated observations on person alone.

## Input contracts

Wave-based cleaners require a nonempty table list, a matching vector of distinct integer RCT waves 1–4, and structural columns in each table. Wave suffixes may be present on required columns where the cleaner supports suffix removal. Missing required columns raise an `ArgumentError` naming the cleaner and columns.

| Cleaner | Required input columns |
| --- | --- |
| Respondent | `respondent_master_id`, `village_code`, `building_id`, `data_source`, `complete`, `survey_start`, `date_of_birth`, `gender` |
| Household | Person, village, and building IDs per table; combined delivery also needs `l0400`, `l0500`, `l1000`, `l1100`, `l1500`, `l1600`, `village_name`, `municipality`, `office` |
| Connections | `village_code`, `ego`, `alter`, `question`, `relationship`, `alter_source`, `same_building`, `same_village`, `a2701`, `a2702` |
| Outcomes | `respondent_master_id`; outcome and treatment columns may be absent |
| HMB | `respondent_master_id`, `village_code`, `lives_in_village`, `works_in_village`; donation and other guarded survey items may be absent |
| Village | Village ID and wealth-index columns; combined delivery also requires cemetery/location, electricity, and summary columns used by the cleaner |
| IH/cooperation | The full delivery schema; validation lists missing columns explicitly |

These checks validate column availability, not every value or every conditional dependency. A present optional field can still require a companion field (for example, HMB cognitive score and cognitive status).
