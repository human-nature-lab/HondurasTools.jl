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
  to outcome_type (used by `_recode_outcomes!`)

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
        ismissing(x) ? x : replace(strip(string(x)), r"\s+" => " ")
    end

    # pre-index for O(1) per-variable lookups
    gvariables    = groupby(variables, [:study, :variable_id])
    goptions      = groupby(sort(options, :option_code), [:study, :variable_id])
    gvar_by_type  = groupby(variables, [:study, :variable_type])
    gvar_by_level = groupby(variables, [:study, :level])

    # pre-build outcome_type_map so _recode_outcomes! doesn't rebuild on every call
    outcome_type_map = Dict{String, String}()
    for row in eachrow(derivations)
        ismissing(row.outcome_type) && continue
        base = replace(strip(string(row.variable_id)), r"_w\d+$" => "")
        outcome_type_map[base] = strip(string(row.outcome_type))
    end

    return (; variables, options, derivations,
              gvariables, goptions, gvar_by_type, gvar_by_level,
              outcome_type_map)
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
sorted by `option_code`.

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
    lvls = collect(opts.label_en)
    return categorical(data_col; levels = lvls, ordered = true)
end

export make_ordered_categorical
