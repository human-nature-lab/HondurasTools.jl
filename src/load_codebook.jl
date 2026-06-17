# load_codebook.jl

const _CB_PATH = joinpath(@__DIR__, "..", "codebook")

"""
    load_codebook(; path = <bundled codebook dir>)

Load the three machine-readable codebook CSVs and return a NamedTuple
`(; variables, options, derivations)` of DataFrames.

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
    return (; variables, options, derivations)
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
    df = cb.variables
    mask = isequal.(df.variable_id, varname) .& isequal.(df.study, study)
    !isnothing(wave) && (mask .&= isequal.(df.wave, wave))
    return df[mask, :]
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
    df = cb.options
    mask = isequal.(df.variable_id, varname) .& isequal.(df.study, study)
    !isnothing(wave) && (mask .&= isequal.(df.wave, wave))
    result = df[mask, :]
    return sort(result, :option_code)
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
    df = cb.variables
    mask = isequal.(df.variable_type, vtype) .& isequal.(df.study, study)
    return unique(df[mask, :variable_id])
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
    df = cb.variables
    mask = isequal.(df.level, level) .& isequal.(df.study, study)
    return unique(df[mask, :variable_id])
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
