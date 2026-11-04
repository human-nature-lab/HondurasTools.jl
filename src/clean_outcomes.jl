# clean_outcomes.jl

"""
    clean_outcomes(dfs, waves; codebook = nothing, namedict = nothing, study = "rct")

Clean outcome/treatment DataFrames for the selected `study` (default `"rct"`).

Strips wave suffixes, combines waves, and renames `respondent_master_id` → `name`.
If a `codebook` is provided, also:
- Classifies outcome columns by codebook outcome_type
- Recodes outcome columns to `Union{Missing, Bool}` via `recode_outcome`
- Categorizes `village_code`
- Converts `resp_target`, `friend_treatment`, `household_target` → `Union{Missing, Bool}`

`codebook` can be a `NamedTuple` from `load_codebook()` (preferred) or a bare
`DataFrame` with columns `variable_id` and `outcome_type` (legacy).
"""
function clean_outcomes(
    dfs::Vector{DataFrame},
    waves;
    codebook = nothing,
    namedict = nothing,
    study::AbstractString = "rct"
)

    if isnothing(namedict)
        namedict = Dict{Symbol, Symbol}()
    end

    _validate_waves(dfs, waves, "clean_outcomes"; required=[:respondent_master_id])
    df = strip_and_combine_waves!(dfs, waves)

    rename!(df, :respondent_master_id => :name);
    namedict[:name] = :respondent_master_id;

    if !isnothing(codebook)
        _recode_outcomes!(df, codebook; study)
    end

    return df
end

export clean_outcomes

"""
    _recode_outcomes!(df, codebook)

Internal: use codebook to classify and recode outcome columns in `df`.

`codebook` may be:
- A `NamedTuple` from `load_codebook()` — uses `codebook.derivations` with named
  columns `variable_id` and `outcome_type`.
- A bare `DataFrame` with columns `variable_id` and `outcome_type` (legacy format).

Classifications match study and row wave; unsuffixed derivations apply to all waves.
Missing classification for an observed wave of a known outcome raises an error.
Outcome types "practice", "knowledge and attitudes", and "intervention knowledge"
are recoded to `Union{Missing, Bool}`.

Also handles:
- `village_code` → CategoricalArray
- `resp_target`, `friend_treatment`, `household_target` → Union{Missing, Bool}
- `rep_age`, `preg` → `Union{Missing, Bool}` via `recode_outcome`
- `age_at_survey` → `Union{Missing, Int}`
"""
function _recode_outcomes!(df::DataFrame, codebook; study::AbstractString="rct")
    index = codebook isa NamedTuple ? codebook.outcome_type_index :
        _outcome_index(codebook; default_study=study)
    _require_columns(df, [:wave], "outcome recoding")
    for col in names(df)
        any(k -> k[1] == study && k[2] == col, keys(index)) || continue
        covered = [haskey(index, (study, col, Int(w))) ||
                   haskey(index, (study, col, nothing)) for w in df.wave]
        any(i -> !covered[i] && !ismissing(df[i, col]), eachindex(covered)) &&
            throw(ArgumentError("No $study codebook classification for some observed waves of $col"))
        df[!, col] = recode_outcome(df[!, col])
    end

    # Categorize village_code
    if "village_code" in names(df)
        df.village_code = categorical(df.village_code)
    end

    # Boolify treatment indicators
    # (resp_target and household_target are variable_type="outcome" in the codebook
    # but are 0/1 columns treated as indicators here)
    for v in ["resp_target", "friend_treatment", "household_target"]
        if v in names(df)
            df[!, Symbol(v)] = map(df[!, Symbol(v)]) do x
                ismissing(x) && return missing
                x in (0, 1) || throw(ArgumentError("$v must contain only 0, 1, or missing; got $x"))
                return Bool(x)
            end
        end
    end

    # Demographic variables with standard survey coding (0/1/2/999, "NA")
    for v in [:rep_age, :preg]
        if string(v) in names(df)
            df[!, v] = recode_outcome(df[!, v])
        end
    end

    # Numeric string columns with "NA" → Union{Missing, Int}
    for v in [:age_at_survey]
        if string(v) in names(df)
            df[!, v] = [ismissing(x) || strip(string(x)) == "NA" ?
                missing : parse(Int, strip(string(x))) for x in df[!, v]]
        end
    end
end
