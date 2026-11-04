# Perception and norms

## Scope and status

`clean_perception!` is an optional respondent-level transformation for RCT perceptions of community behavior and social approval, together with related personal attitudes and reported behavior. It is loaded and exported by HondurasTools, but neither `clean_respondent` nor `make_data.jl` calls it. This guide documents the current implementation; it does not establish that every recode is appropriate for every wave or analysis.

Keep this step explicit. The function assumes a broad historical delivery schema, mutates its input, and makes decisions about denominators and missing responses that need to be checked against the questionnaire. It has not received the end-to-end validation of the newer outcome and HMB workflows. Integration into the main pipeline should wait for wave-specific input contracts and regression tests for these decisions.

These are perceptions of community practices and approval. They are distinct from Cognitive Social Structures reports about who is connected to whom.

## Distinguish the measures

| Output family | Interpretation | Example |
| --- | --- | --- |
| `*_perc` | Respondent's perception of community behavior; often a descriptive-norm measure | `avoid_preg_perc` from `j0300` |
| `*_moralperc` | Respondent's perception of community approval or disapproval; an injunctive-norm measure | `avoid_preg_moralperc` from `j0400` |
| `*_good`, `*_good_age`, `*_good_when` | Personal approval, knowledge, or a derived proxy; interpretation depends on the question | `girl_partner_good_age` from `i0800` |
| Related behavior columns | Respondent's reported behavior or a derived indicator | `avoid_preg` from `e0900` and `e1100` |

A perceived norm is not a village-level estimate of actual behavior. Likewise, personal knowledge and approval are not interchangeable. Suffixes describe the implementation's naming convention, not a validated measurement model.

Question polarity matters. For example, prenatal-care and fathers' involvement approval items ask about **not** performing the behavior; the baby-bathing approval item asks about not bathing immediately. The cleaner retains the question's approval direction rather than harmonizing every item to a common desirable-behavior scale. Check the exact wording before pooling, reversing, or comparing scores.

## Codebook and wave coverage

The bundled codebook records 49 J-prefixed entries in each of RCT waves 1, 2, and 3, and none in wave 4. This counts metadata entries, including non-measurement entries; it is not a count of validated scales. Examples such as `j0100`, `j0300`, `j0400`, `j2000a`, `j2900`, and `j3000` have `survey` labels `w1 baseline`, `w2 baseline`, and `all`, respectively. A wave entry does not imply every respondent was asked the question.

Inspect metadata and options before interpreting a value:

```julia
using HondurasTools
cb = load_codebook()
variable_info(cb, "j0300"; study="rct")
variable_options(cb, "j0300"; study="rct", wave=3)
variable_info(cb, "j0400"; study="rct", wave=3)
```

Companion I-, E-, F-, and C-section questions can have different eligibility rules, formats, and wave coverage. Empty metadata for repeated-question fields is not evidence that a cleaner's assumption is valid. See [Codebooks and provenance](codebooks.md) for the source release and external guides.

## Inputs and invocation

The intended input has wave suffixes removed, the raw question IDs listed below still present, and the respondent fields `child` and `gender` prepared. The implementation expects `child` to contain `"Yes"`/other labels and uses `gender` values `"man"` and `"woman"` when resolving birth-decision responses.

The function unconditionally renames the crosswalk columns. It also reads `f5100a`–`f5100i`, `i2500a`–`i2500k`, `f6000m`, `c0900a`, and `c0700d`. Missing columns cause errors; inserting all-missing columns is not a safe substitute because several recodes interpret missing as false. Some fields are parsed as numeric strings, so already numeric inputs may need adaptation. Unexpected response labels also need review.

`clean_respondent` performs general respondent preparation, but its output is not a guaranteed ready-to-use input for this optional cleaner. Inspect retained question IDs, types, response labels, and wave eligibility first. In particular, a failed perception-cleaning call may leave a partially renamed table.

After those checks, the explicit invocation is:

```julia
# prepared_resp is a delivery-specific DataFrame satisfying the requirements above.
perception = deepcopy(prepared_resp)
name_map = Dict{Symbol,Symbol}()
clean_perception!(perception; namedict=name_map)

# Optional: apply supported categorical orderings after inspecting output values.
code_variables!(perception)
```

Keep using `perception` after the call. Do not assign the function's return value to it: the current implementation ends with a vector of variable names, not the modified DataFrame. Calling it twice on the same table also fails because the raw columns have already been renamed. `name_map` maps renamed output columns back to raw IDs; it is not a complete lineage map for derived variables.

## Recoding and missingness

The implementation generally replaces `"Don't know"`, `"Don't Know"`, `"Dont_Know"`, `"Refused"`, and `"Removed"` with missing, but subsequent operations can turn those missing values into false. The following are existing behaviors to audit, not recommended universal rules:

| Operation | Current behavior |
| --- | --- |
| Partnership/childbearing approval age | Derives `*_good` as age `< 18` |
| Prenatal and postnatal timing | Derives care indicators from months `<= 3` and days `<= 7` |
| Immediate bathing | Derives `baby_bath_1dy` from elapsed days `< 1` |
| Selected approval/knowledge items | Nonmissing selection becomes true and missing becomes false, including `postnatal_good`, `baby_skin_good`, `fajero_good_1`, `fajero_good_2`, and `laxatives_good` |
| Skin-to-skin behavior | All component selections missing stays missing; a sole `"No"` is false; other observed combinations are true |
| Laxative behavior | For respondents identified as having children, missing `f6000m` becomes `"No"`; the field is then converted to Boolean |
| Diarrhea treatment | For respondents reporting recent diarrhea, missing treatment and perceived-treatment selections become `"No"`; this eligibility restriction is also applied to perception items |
| Handwashing/smoke knowledge items | Selection presence is treated as true and missing as false |
| Approval of partner violence | `men_hit_good` is true if any observed reason is approved, false if observed reasons are all false, and missing if all reasons are missing |

Retain original responses and compare distributions by wave and eligibility group. In particular, distinguish a structurally unasked question, an unselected checkbox, a refusal, and an observed negative response before adopting these results.

`code_variables!` applies `Never < Rarely < Sometimes < Always` to selected perception columns and `Bad < Neither < Good` to selected approval columns. It does not cover every output, reverse negative-polarity items, or build composite norm scores. The `cb` keyword does not make these hardcoded perception orderings wave-specific.

The exported `percvars` list is a convenience list, not an exhaustive output schema: it omits the diarrhea-treatment block and some derived indicators. Inspect `names(perception)` when selecting outputs.

## Implemented source-to-output crosswalk

This table records the active renames in `rename_perception!`. Derived columns and additional component inputs described above are not represented as one-to-one renames.

| Raw question ID | Renamed column |
| --- | --- |
| `j0100` | `girl_partner_moralperc` |
| `i0800` | `girl_partner_good_age` |
| `j0200` | `girl_baby_moralperc` |
| `i1000` | `girl_baby_good_age` |
| `j0300` | `avoid_preg_perc` |
| `e0900` | `avoid_preg_ever` |
| `e1100` | `avoid_preg_now` |
| `j0400` | `avoid_preg_moralperc` |
| `j0500` | `folic_perc` |
| `e1400` | `folic_now` |
| `e1500` | `folic_1wk` |
| `i1200` | `folic_good_when` |
| `j0600` | `prenatal_care_perc` |
| `f1900r01` | `prenatal_care_any` |
| `f2000` | `prenatal_care_when` |
| `j0700` | `prenatal_care_moralperc` |
| `i1300` | `prenatal_care_good_when` |
| `j0800` | `homebirth_perc` |
| `f2700r01` | `wherebirth` |
| `i1500` | `birth_good_where` |
| `j0900` | `homebirth_moralperc` |
| `j1000` | `birthdecision_perc` |
| `f2800` | `birthdecision` |
| `j1100` | `postnatal_care_perc` |
| `f3600` | `postnatal_care_any` |
| `f3700` | `postnatal_care_when` |
| `i1900d` | `postnatal_good` |
| `j1200` | `baby_bath_perc` |
| `j1300` | `baby_bath_moralperc` |
| `f4800p1` | `baby_bath` |
| `j1400` | `baby_skin_perc` |
| `j1500` | `baby_skin_moralperc` |
| `i1900a` | `baby_skin_good` |
| `j1600` | `fajero_perc` |
| `f5000` | `fajero` |
| `i1900c` | `fajero_good_1` |
| `i2200g` | `fajero_good_2` |
| `j1700` | `chupon_perc` |
| `j1800` | `chupon_moralperc` |
| `f7000` | `chupon` |
| `j1900` | `laxatives_perc` |
| `i1900b` | `laxatives_good` |
| `c0500` | `diarrhea_3wk` |
| `j2000a` | `diarrhea_antibiotic_perc` |
| `j2000b` | `diarrhea_zinc_perc` |
| `j2000c` | `diarrhea_specialfluid_perc` |
| `j2000d` | `diarrhea_antidiarrhea_perc` |
| `j2000e` | `diarrhea_laxative_perc` |
| `j2000f` | `diarrhea_deworm_perc` |
| `j2000g` | `diarrhea_homeremedy_perc` |
| `j2000h` | `diarrhea_chupon_perc` |
| `j2000i` | `diarrhea_massage_perc` |
| `j2000j` | `diarrhea_stopfood_perc` |
| `j2000k` | `diarrhea_stopliquid_perc` |
| `j2000l` | `diarrhea_extrafood_perc` |
| `j2000m` | `diarrhea_extraliquid_perc` |
| `j2000n` | `diarrhea_govtfluid_perc` |
| `j2000o` | `diarrhea_comliquid_perc` |
| `j2000r` | `diarrhea_other_perc` |
| `c0900b` | `diarrhea_antibiotic` |
| `c0900c` | `diarrhea_zinc` |
| `c0700a` | `diarrhea_specialfluid` |
| `c0900d` | `diarrhea_antidiarrhea` |
| `c0900f` | `diarrhea_laxative` |
| `c0900g` | `diarrhea_deworm` |
| `c0900e` | `diarrhea_homeremedy` |
| `c0900h` | `diarrhea_chupon` |
| `c0900i` | `diarrhea_massage` |
| `c0900j` | `diarrhea_stopfood` |
| `c0900k` | `diarrhea_stopliquid` |
| `c0900m` | `diarrhea_extraliquid` |
| `c0700b` | `diarrhea_govtfluid` |
| `c0700c` | `diarrhea_comliquid` |
| `c0900n` | `diarrhea_other` |
| `j2100` | `wash_perc` |
| `i2900b` | `wash_good` |
| `j2200` | `avoid_smoke_perc` |
| `i2900d` | `avoid_smoke` |
| `j2300` | `father_check_perc` |
| `f2600` | `father_check` |
| `j2400` | `father_check_moralperc` |
| `i3200` | `father_check_good` |
| `j2500` | `father_wait_perc` |
| `f2900` | `father_wait` |
| `j2600` | `father_wait_moralperc` |
| `i3300` | `father_wait_good` |
| `j2700` | `father_care_sick_perc` |
| `j2800` | `father_care_sick_moralperc` |
| `i3400` | `father_care_sick_good` |
| `j2900` | `men_hit_perc` |
| `j3000` | `men_hit_moralperc` |
| `i0300` | `men_hit_neglect_good` |
| `i0400` | `men_hit_house_good` |
| `i0500` | `men_hit_argue_good` |
| `i0600` | `men_hit_food_good` |
| `i0700` | `men_hit_sex_good` |

## Before making this a default pipeline step

Establish the supported question set for each wave and delivery, preserve skip/refusal distinctions, verify the direction and denominator of each measure, and test the complete path from raw input through categorical coding. Until then, use this as a separately reviewed analysis transformation.

See the [API reference](api.md) for the function entry and [Processing and analysis](processing.md) for the general cleaning workflow.
