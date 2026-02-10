# clean_outcomes.jl

"""
    clean_outcomes(dfs, waves; codebook = nothing, namedict = nothing)

Clean outcome/treatment DataFrames from the Honduras CSS study.

Strips wave suffixes, combines waves, and renames `respondent_master_id` → `name`.
If a `codebook` DataFrame is provided (from the outcomes codebook CSV), also:
- Classifies outcome columns by codebook outcome_type
- Recodes outcome columns to `Union{Missing, Bool}` via `recode_outcome`
- Categorizes `village_code`
- Converts `resp_target` and `friend_treatment` to `Bool`
"""
function clean_outcomes(
    dfs::Vector{DataFrame},
    waves;
    codebook::Union{Nothing, DataFrame} = nothing,
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

Codebook format: column 1 = variable name (with wave suffix, e.g. `bf_excl_w3`),
column 2 = outcome_type. Outcome types "practice", "knowledge and attitudes",
and "intervention knowledge" are recoded to `Union{Missing, Bool}`.
"""
function _recode_outcomes!(df::DataFrame, codebook::DataFrame)
    cb_varname_col = names(codebook)[1]
    cb_type_col = names(codebook)[2]

    # Build lookup: strip wave suffix from codebook names → outcome_type
    outcome_type_map = Dict{String, String}()
    for row in eachrow(codebook)
        varname = string(row[cb_varname_col])
        otype = row[cb_type_col]
        ismissing(otype) && continue
        base = replace(varname, r"_w\d+$" => "")
        outcome_type_map[base] = string(otype)
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
    for v in [:resp_target, :friend_treatment]
        if string(v) in names(df)
            df[!, v] = Bool.(df[!, v])
        end
    end
end
