# Known PDF extraction aliases, shared by bundled and legacy codebook loaders.
function _normalize_outcome_type(x)
    ismissing(x) && return missing
    value = replace(strip(string(x)), r"\s+" => " ")
    value = get(Dict("knowled ge and attitudes" => "knowledge and attitudes",
                     "intervent ion knowled ge" => "intervention knowledge"), value, value)
    value in ("practice", "knowledge and attitudes", "intervention knowledge") ||
        throw(ArgumentError("Unknown outcome_type $(repr(value)); correct the codebook before recoding"))
    return value
end

# Wave is encoded in derivation IDs; unsuffixed entries apply to all waves.
function _outcome_index(derivs; default_study="rct")
    _require_columns(derivs, [:variable_id, :outcome_type], "outcome codebook")
    index = Dict{Tuple{String,String,Union{Nothing,Int}},String}()
    for row in eachrow(derivs)
        ismissing(row.outcome_type) && continue
        study = "study" in names(derivs) ? string(row.study) : default_study
        id = strip(string(row.variable_id))
        suffix = match(r"_w(\d+)$", id)
        wave = isnothing(suffix) ? nothing : parse(Int, suffix.captures[1])
        base = replace(id, r"_w\d+$" => "")
        key = (study, base, wave)
        value = _normalize_outcome_type(row.outcome_type)
        haskey(index, key) && index[key] != value &&
            throw(ArgumentError("Conflicting outcome classifications for $key"))
        index[key] = value
    end
    return index
end

# load_codebook.jl

const _CB_PATH = joinpath(@__DIR__, "..", "codebook")

"""
    load_codebook(; path = <bundled codebook dir>)

Load the three machine-readable codebook CSVs and return a NamedTuple containing:
- `variables`, `options`, `derivations` — raw DataFrames
- `gvariables`, `goptions` — GroupedDataFrames keyed on `[:study, :variable_id]`
  for O(1) per-variable lookups
- `gvar_by_type`, `gvar_by_level` — GroupedDataFrames for type/level queries
- `outcome_type_map` — pre-built `Dict{String,String}` mapping base variable name
  to outcome_type, for unambiguous RCT classifications (compatibility view)
- `outcome_type_index` — classifications keyed by `(study, base variable, wave)`;
  `nothing` denotes a wave-independent derivation

The bundled codebooks (at `HondurasTools/codebook/`) are the default.
Pass `path` to override with an external directory.

# Schema
- `variables`   — one row per variable-wave; fields: study, variable_id, wave, level,
                   variable_type, question_type, survey, repeated_question, question_text_en, ...
- `options`     — one row per variable-wave-option; fields: study, variable_id, wave,
                   option_code, label_en, label_en_male, label_es, label_es_male
- `derivations` — one row per derived/outcome variable; fields: study, variable_id,
                   outcome_type, denominator, derivation, source_questions, notes
"""
function load_codebook(; path::AbstractString = _CB_PATH)
    variables   = CSV.read(joinpath(path, "variables.csv"),   DataFrame; missingstring = "")
    options     = CSV.read(joinpath(path, "options.csv"),     DataFrame; missingstring = "")
    derivations = CSV.read(joinpath(path, "derivations.csv"), DataFrame; missingstring = "")

    # normalize internal whitespace in outcome_type (guards against PDF-extraction artifacts)
    derivations.outcome_type = map(derivations.outcome_type) do x
        _normalize_outcome_type(x)
    end

    # pre-index for O(1) per-variable lookups
    gvariables    = groupby(variables, [:study, :variable_id])
    goptions      = groupby(sort(options, :option_code), [:study, :variable_id])
    gvar_by_type  = groupby(variables, [:study, :variable_type])
    gvar_by_level = groupby(variables, [:study, :level])

    outcome_type_index = _outcome_index(derivations)
    # Compatibility view: retain only unambiguous RCT classifications.
    outcome_type_map = Dict{String,String}()
    for base in unique([k[2] for k in keys(outcome_type_index) if k[1] == "rct"])
        types = unique([v for (k, v) in outcome_type_index if k[1] == "rct" && k[2] == base])
        length(types) == 1 && (outcome_type_map[base] = only(types))
    end

    return (; variables, options, derivations,
              gvariables, goptions, gvar_by_type, gvar_by_level,
              outcome_type_map, outcome_type_index)
end

export load_codebook

"""
    variable_info(cb, varname; wave = nothing, study = "rct")

Return all rows in `cb.variables` for `varname`, optionally filtered by wave and study.
"""
function variable_info(
    cb::NamedTuple,
    varname::AbstractString;
    wave = nothing,
    study::AbstractString = "rct"
)
    key = (study = study, variable_id = varname)
    haskey(cb.gvariables, key) || return cb.variables[1:0, :]
    rows = DataFrame(cb.gvariables[key])
    isnothing(wave) ? rows : rows[isequal.(rows.wave, wave), :]
end

export variable_info

"""
    variable_options(cb, varname; wave = nothing, study = "rct")

Return option codes and labels for `varname` from `cb.options`, sorted by `option_code`.

Note: `option_code` reflects survey display order, which may differ from the desired
analytical ordering for ordered categoricals. Use the returned labels as a starting
point and reorder manually if needed.
"""
function variable_options(
    cb::NamedTuple,
    varname::AbstractString;
    wave = nothing,
    study::AbstractString = "rct"
)
    key = (study = study, variable_id = varname)
    haskey(cb.goptions, key) || return cb.options[1:0, :]
    rows = DataFrame(cb.goptions[key])   # already sorted by option_code at load time
    isnothing(wave) ? rows : rows[isequal.(rows.wave, wave), :]
end

export variable_options

"""
    variables_by_type(cb, vtype; study = "rct")

Return unique `variable_id`s where `variable_type == vtype` for the given study.

Common types: "survey", "derived", "admin", "treatment", "identifier", "outcome",
              "intro", "flag"
"""
function variables_by_type(
    cb::NamedTuple,
    vtype::AbstractString;
    study::AbstractString = "rct"
)
    key = (study = study, variable_type = vtype)
    haskey(cb.gvar_by_type, key) || return String[]
    return unique(cb.gvar_by_type[key].variable_id)
end

export variables_by_type

"""
    variables_by_level(cb, level; study = "rct")

Return unique `variable_id`s at a given data level for the given study.

Levels: "respondent", "household", "village", "connection", "outcome"
"""
function variables_by_level(
    cb::NamedTuple,
    level::AbstractString;
    study::AbstractString = "rct"
)
    key = (study = study, level = level)
    haskey(cb.gvar_by_level, key) || return String[]
    return unique(cb.gvar_by_level[key].variable_id)
end

export variables_by_level

"""
    make_ordered_categorical(cb, variable_id, data_col; wave = nothing, study = "rct")

Build an ordered `CategoricalArray` for `data_col` using option labels from `cb.options`,
sorted by `option_code`. With `wave=nothing`, every wave must have identical
labels and ordering; otherwise specify a wave explicitly.

Intended for new variables not yet in `code_variables!`. For existing cleaned variables,
verify that option labels match the cleaned values (raw labels may differ in case or
wording from post-cleaning values).
"""
function make_ordered_categorical(
    cb::NamedTuple,
    variable_id::AbstractString,
    data_col;
    wave = nothing,
    study::AbstractString = "rct"
)
    opts = variable_options(cb, variable_id; wave, study)
    isempty(opts) && error("No options found for variable_id=$(variable_id), study=$(study)")
    orders = [collect(g.label_en) for g in groupby(opts, :wave)]
    any(labels -> any(ismissing, labels) || !allunique(labels), orders) &&
        throw(ArgumentError("Option labels must be nonmissing and unique within each wave"))
    all(labels -> isequal(labels, first(orders)), orders) ||
        throw(ArgumentError("Option labels/order differ across waves; specify wave explicitly"))
    lvls = first(orders)
    return categorical(data_col; levels = lvls, ordered = true)
end

export make_ordered_categorical
