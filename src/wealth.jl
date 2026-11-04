export WealthMCA, fit_wealth, score_wealth, wealth_indices, write_wealth_indices

"""
    WealthMCA

Fitted indicator MCA model returned by [`fit_wealth`](@ref). Stores named
indicators, observed category levels, category proportions, scoring coefficients,
retained eigenvalues, total inertia, missing-value policy, and orientation anchor.
Treat its arrays as read-only. No survey data or identifiers are stored.
"""
struct WealthMCA
    indicators::Vector{Symbol}
    categories::Vector{Vector{Any}}
    proportions::Vector{Float64}
    coefficients::Matrix{Float64}
    eigenvalues::Vector{Float64}
    total_inertia::Float64
    missing_policy::Symbol
    anchor::NamedTuple
end

function _wealth_columns(df, indicators)
    isempty(indicators) && throw(ArgumentError("Specify at least one categorical indicator"))
    allunique(indicators) || throw(ArgumentError("Indicators must be unique"))
    absent = setdiff(indicators, propertynames(df))
    isempty(absent) || throw(ArgumentError("Missing indicator columns: $absent"))
end

function _wealth_indicator(df, indicators, categories, missing_policy; unknown=:error)
    unknown in (:error, :missing) || throw(ArgumentError("unknown must be :error or :missing"))
    _wealth_columns(df, indicators)
    z = zeros(nrow(df), sum(length, categories))
    valid = trues(nrow(df))
    offset = 0
    for (col, cats) in zip(indicators, categories)
        lookup = Dict(v => i for (i, v) in enumerate(cats))
        for (i, value) in enumerate(df[!, col])
            if ismissing(value) && missing_policy == :error
                throw(ArgumentError("Missing value in $col at row $i; use missing_policy=:category explicitly"))
            end
            j = get(lookup, value, 0)
            if j == 0
                unknown == :error && throw(ArgumentError("Unseen category $(repr(value)) in $col at row $i"))
                valid[i] = false
            else
                z[i, offset + j] = 1
            end
        end
        offset += length(cats)
    end
    return z, valid
end

"""
    fit_wealth(df; indicators, anchor, ndims=2, missing_policy=:error)

Fit unweighted indicator MCA using only the explicitly named categorical
`indicators`. Numeric values are treated as category labels, not continuous data.
`anchor=(column=:tv, low=false, high=true)` fixes dimension one's sign so replacing
the low category with the high category increases the score, all else equal.
Both categories must occur and have a nonzero contrast on dimension one. This
orientation does not establish that the dimension measures wealth: inspect asset
patterns and external diagnostics. Remaining dimensions use a deterministic sign.

Missing data error by default; `missing_policy=:category` explicitly treats missing
as a category. Constant columns are retained (and contribute no variation).
An error is raised if fewer than `ndims` nonzero dimensions exist. No imputation,
quintiling, household-size weighting, or supplementary-variable fitting is done.
"""
function fit_wealth(df::AbstractDataFrame; indicators, anchor, ndims::Integer=2,
                    missing_policy::Symbol=:error)
    cols = Symbol.(collect(indicators))
    _wealth_columns(df, cols)
    nrow(df) >= 2 || throw(ArgumentError("MCA requires at least two rows"))
    ndims >= 1 || throw(ArgumentError("ndims must be positive"))
    missing_policy in (:error, :category) || throw(ArgumentError("missing_policy must be :error or :category"))
    all(k -> hasproperty(anchor, k), (:column, :low, :high)) ||
        throw(ArgumentError("anchor must provide column, low, and high"))
    a = (column=Symbol(anchor.column), low=anchor.low, high=anchor.high)
    ai = findfirst(==(a.column), cols)
    isnothing(ai) && throw(ArgumentError("Anchor column must be an active indicator"))
    isequal(a.low, a.high) && throw(ArgumentError("Anchor categories must differ"))
    # Stable ordering independent of row order; preserve values (including missing).
    # Sort the generic category container: CSV's InlineString arrays otherwise
    # select a specialized sorter that cannot handle this tuple-valued key.
    cats = [sort!(Any[unique(df[!, c])...]; by=x -> (string(typeof(x)), repr(x))) for c in cols]
    z, _ = _wealth_indicator(df, cols, cats, missing_policy)
    p = vec(mean(z; dims=1))
    q = length(cols)
    # Standardized residuals of the complete disjunctive table. The SVD has
    # eigenvalues of CA; row principal coordinates are sqrt(n) * U * D.
    b = (z .- p') ./ sqrt.(q .* p')
    decomposition = svd(b / sqrt(nrow(df)); full=false)
    tol = maximum(size(b)) * eps(Float64) * first(decomposition.S)
    count(>(tol), decomposition.S) >= ndims ||
        throw(ArgumentError("Fewer than $ndims nonzero MCA dimensions; reduce ndims or review indicators"))
    coefficients = decomposition.V[:, 1:ndims] ./ sqrt.(q .* p)
    for d in 1:ndims
        magnitudes = abs.(coefficients[:, d])
        # Break nearly tied maxima by category order, not rounding noise.
        j = findfirst(x -> x >= maximum(magnitudes) * (1 - sqrt(eps(Float64))), magnitudes)
        coefficients[:, d] .*= sign(coefficients[j, d])
    end
    lo = findfirst(isequal(a.low), cats[ai])
    hi = findfirst(isequal(a.high), cats[ai])
    (isnothing(lo) || isnothing(hi)) && throw(ArgumentError("Both anchor categories must occur in the fitting data"))
    offset = sum(length, cats[1:ai-1]; init=0)
    contrast = coefficients[offset + hi, 1] - coefficients[offset + lo, 1]
    abs(contrast) > sqrt(eps(Float64)) * maximum(abs, coefficients[:, 1]) ||
        throw(ArgumentError("Anchor does not distinguish dimension one; choose another contrast"))
    coefficients[:, 1] .*= sign(contrast)
    return WealthMCA(cols, cats, p, coefficients, decomposition.S[1:ndims].^2,
                     sum(abs2, decomposition.S), missing_policy, a)
end

"""
    score_wealth(model::WealthMCA, df; unknown=:error)

Project rows onto a fitted MCA model without refitting or rescaling. Returns a
matrix (rows by retained dimensions), preserving input order. New categories
error by default. `unknown=:missing` returns missing for every dimension of an
affected row. Missing values follow the model's policy; a missing category absent
from the fitting data is an unseen category. Extra columns are ignored.
"""
function score_wealth(model::WealthMCA, df::AbstractDataFrame; unknown::Symbol=:error)
    z, valid = _wealth_indicator(df, model.indicators, model.categories,
                                model.missing_policy; unknown)
    coordinates = (z .- model.proportions') * model.coefficients
    result = Matrix{Union{Missing, Float64}}(coordinates)
    result[.!valid, :] .= missing
    return result
end

"""
    wealth_indices(df; indicators, anchor, reference_wave=1,
                   id=:building_id, wave=:wave, ndims=2,
                   missing_policy=:error, unknown=:error)

Fit each wave independently and also fit one shared model on `reference_wave`.
Returns `(scores, wave_models, reference_model, reference_wave)`. `scores` retains
input row order and ID/wave columns, with `wealth_within_d1`, `wealth_common_d1`,
etc. Only common scores can be differenced across waves. Dimension one is
oriented by `anchor` in every model; other dimensions have no wealth direction.

Requires nonmissing, unique `(id, wave)` keys. Each row has equal fitting weight.
No data are mutated. For future waves, reuse the returned reference model with
[`score_wealth`](@ref); do not refit or standardize separately by wave.
"""
function wealth_indices(df::AbstractDataFrame; indicators, anchor, reference_wave=1,
                        id::Symbol=:building_id, wave::Symbol=:wave, ndims::Integer=2,
                        missing_policy::Symbol=:error, unknown::Symbol=:error)
    ndims >= 1 || throw(ArgumentError("ndims must be positive"))
    id != wave || throw(ArgumentError("id and wave columns must differ"))
    _wealth_columns(df, [id, wave])
    any(ismissing, df[!, id]) && throw(ArgumentError("Missing household IDs"))
    any(ismissing, df[!, wave]) && throw(ArgumentError("Missing waves"))
    allunique(zip(df[!, id], df[!, wave])) || throw(ArgumentError("Duplicate household/wave keys"))
    reference_wave in df[!, wave] || throw(ArgumentError("Reference wave is absent"))
    cols = Symbol.(collect(indicators))
    isempty(intersect(cols, [id, wave])) || throw(ArgumentError("IDs and waves cannot be indicators"))
    models = Dict{Any, WealthMCA}()
    within = Matrix{Union{Missing, Float64}}(missing, nrow(df), ndims)
    for w in unique(df[!, wave])
        rows = findall(isequal(w), df[!, wave])
        subset = view(df, rows, :)
        model = fit_wealth(subset; indicators=cols, anchor, ndims, missing_policy)
        models[w] = model
        within[rows, :] = score_wealth(model, subset)
    end
    reference = models[reference_wave]
    common = score_wealth(reference, df; unknown)
    out = select(df, id, wave)
    for d in 1:ndims
        out[!, Symbol("wealth_within_d", d)] = within[:, d]
        out[!, Symbol("wealth_common_d", d)] = common[:, d]
    end
    return (scores=out, wave_models=models, reference_model=reference, reference_wave=reference_wave)
end

"""
    write_wealth_indices(input_path; indicators, anchor,
        imputed_path=nothing, output_dir=dirname(input_path), reference_wave=1,
        missing_policy=:category, unknown=:error)

Replace the legacy R CSV workflow with Julia. Read prepared household indicators
from `input_path` (and optionally `imputed_path`), calculate two MCA dimensions,
and write `wealth_index.csv` (within-wave scores), `wealth_index_reference.csv`
(common scores), and `wealth_indices.csv` (both, with explicit column names).
The first two preserve the legacy columns `building_id`, `wave`, `wealth_d1`,
`wealth_d2`, `imputed`. IDs are read as strings; `NA` and empty fields are missing.
All fits complete before any outputs are written. Output files are overwritten.

Regular and imputed inputs are fitted separately, matching the old R workflow;
their common scores are comparable across waves within each input version, not
across the two versions. Returns the fitted `regular` and optional `imputed`
results for reuse. Does not perform raw-survey cleaning or imputation.
"""
function write_wealth_indices(input_path::AbstractString; indicators, anchor,
                             imputed_path=nothing, output_dir=dirname(input_path),
                             reference_wave=1, missing_policy::Symbol=:category,
                             unknown::Symbol=:error)
    function calculate(path)
        df = CSV.read(path, DataFrame; missingstring=["", "NA"],
                      types=Dict(:building_id => String))
        return wealth_indices(df; indicators, anchor, reference_wave,
                              missing_policy, unknown, ndims=2)
    end
    regular = calculate(input_path)
    imputed = isnothing(imputed_path) ? nothing : calculate(imputed_path)
    combined = copy(regular.scores)
    combined.imputed = falses(nrow(combined))
    if !isnothing(imputed)
        other = copy(imputed.scores)
        other.imputed = trues(nrow(other))
        append!(combined, other)
    end
    within = select(combined, :building_id, :wave,
                    :wealth_within_d1 => :wealth_d1, :wealth_within_d2 => :wealth_d2, :imputed)
    common = select(combined, :building_id, :wave,
                    :wealth_common_d1 => :wealth_d1, :wealth_common_d2 => :wealth_d2, :imputed)
    mkpath(output_dir)
    CSV.write(joinpath(output_dir, "wealth_index.csv"), within)
    CSV.write(joinpath(output_dir, "wealth_index_reference.csv"), common)
    CSV.write(joinpath(output_dir, "wealth_indices.csv"), combined)
    return (; regular, imputed)
end
