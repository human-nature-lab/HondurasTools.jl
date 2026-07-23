# clean_outcomes.jl

"""
    clean_outcomes(dfs, waves; codebook = nothing, namedict = nothing)

Clean outcome/treatment DataFrames from the Honduras CSS study.

Strips wave suffixes, combines waves, and renames `respondent_master_id` → `name`.
If a `codebook` is provided, also:
- Classifies outcome columns by codebook outcome_type
- Recodes outcome columns to `Union{Missing, Bool}` via `recode_outcome`
- Categorizes `village_code`
- Converts `resp_target`, `friend_treatment`, `household_target` → `Bool`

`codebook` can be a `NamedTuple` from `load_codebook()` (preferred) or a bare
`DataFrame` with columns `variable_id` and `outcome_type` (legacy).
"""
function clean_outcomes(
    dfs::Vector{DataFrame},
    waves;
    codebook = nothing,
    namedict = nothing
)

    if isnothing(namedict)
        namedict = Dict{Symbol, Symbol}()
    end

    df = strip_and_combine_waves!(dfs, waves)

    rename!(df, :respondent_master_id => :name);
    namedict[:name] = :respondent_master_id;

    if !isnothing(codebook)
        _recode_outcomes!(df, codebook)
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

Wave suffixes (`_w1`, `_w2`, etc.) are stripped from `variable_id` before matching.
Outcome types "practice", "knowledge and attitudes", and "intervention knowledge"
are recoded to `Union{Missing, Bool}`.

Also handles:
- `village_code` → CategoricalArray
- `resp_target`, `friend_treatment`, `household_target` → Bool
- `rep_age`, `preg` → `Union{Missing, Bool}` via `recode_outcome`
- `age_at_survey` → `Union{Missing, Int}`
"""
function _recode_outcomes!(df::DataFrame, codebook)
    # Use pre-built map from load_codebook() when available; otherwise build it
    outcome_type_map = if codebook isa NamedTuple
        codebook.outcome_type_map
    else
        derivs = codebook
        m = Dict{String, String}()
        for row in eachrow(derivs)
            varname = strip(string(row.variable_id))
            otype = row.outcome_type
            ismissing(otype) && continue
            base = replace(varname, r"_w\d+$" => "")
            m[base] = strip(string(otype))
        end
        m
    end

    # Recode outcome columns
    outcome_types = Set(["practice", "knowledge and attitudes", "intervention knowledge"])
    n = 0
    for col in names(df)
        if haskey(outcome_type_map, col) && outcome_type_map[col] in outcome_types
            df[!, col] = recode_outcome(df[!, col])
            n += 1
        end
    end
    println("Recoded $n outcome columns to Bool")

    # Categorize village_code
    if "village_code" in names(df)
        df.village_code = categorical(df.village_code)
    end

    # Boolify treatment indicators
    # (resp_target and household_target are variable_type="outcome" in the codebook
    # but are 0/1 columns treated as indicators here)
    for v in ["resp_target", "friend_treatment", "household_target"]
        if v in names(df)
            df[!, Symbol(v)] = Bool.(df[!, Symbol(v)])
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
