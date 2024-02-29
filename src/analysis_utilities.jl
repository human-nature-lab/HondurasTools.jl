# analysis_utilities.jl
# functions to assist with generating model formulas

import Base.vec

function vec(em::EModel)
    return [em.tpr, em.fpr]
end

export vec

ncdf(x; μ = 0, σ2 = 1) = cdf(Normal(μ, σ2), x)

export ncdf

##

descstats = [:mean, :median, :std, :min, :max, :eltype, :nunique, :nmissing]
export descstats

function symb(rhe::Term)
    return rhe.sym
end

function symb(rhe::InteractionTerm)
    return [e.sym for e in rhe.terms]
end

function symb(rhe::FunctionTerm)
    # only works for simple random intercept
    return rhe.args_parsed[2].sym
end

export symb

"""
        extractvars(fx::T) where T <: FormulaTerm

Extract symbol-typed variables from a formula.
"""
function extractvars(fx::T; lhs = true) where T <: FormulaTerm
    rhs = fx.rhs
    return if lhs
        vcat(fx.lhs.sym, reduce(vcat, symb.(rhs)) |> unique)
    else
        reduce(vcat, symb.(rhs)) |> unique
    end
end

export extractvars

modeldf(df, fx; lhs = true) = select(df, extractvars(fx, lhs = lhs))

export modeldf

@inline interaction_equality(i1, i2) = Set(i1.terms) == Set(i2.terms)

"""
        interactpairwise(trms)

## Description

Generate pairwise interactions for all combinations of input term set.
    
- Works for terms that are themselves interactions, e.g., the `a & b` is interacted with each `c` in the list (*as* `a & b & c`).
- Does not add main effects
"""
function interactpairwise(trms)
    int_set = [];
    for x in trms, y in trms
        if x != y
            candidate = x & y
            if !any([interaction_equality(candidate, t) for t in int_set])
                push!(int_set, candidate)
            end
        end
    end
    return int_set
end

export interactpairwise

"""
OLD: cf. interactpairwise

        pairwise_formula(y, preds)

Construct a formula that contains effects for each variable in `pred` with all pairwise interactions.
"""
function pairwise_formula(y, preds)
    allpreds = reduce(+, Term.(preds)) + pairwiseinteractions(preds)
    return Term(y) ~ allpreds
end

export pairwise_formula

"""
OLD: cf. interactpairwise

        pairwiseinteractions(vb)

Generate all pairwise interactions from a set of variables.
"""
function pairwiseinteractions(vb::Vector{Symbol})
    rhs = []
    for a in vb, b in vb
        if a != b
            x = Term(a) & Term(b)
            x2 = Term(b) & Term(a)
            if (x ∉ rhs) & (x2 ∉ rhs)
                push!(rhs, x)
            end
        end
    end
    return reduce(+, rhs)
end

export pairwiseinteractions

grpidx(grp_idx) = [findfirst(grp_idx .== u):findlast(grp_idx .== u) for u in unique(grp_idx)];

export grpidx

"""
        bifit(
            model, fx, dft, dff;
            fx2 = nothing, dstr = Binomial(), lnk = LogitLink()
        )

Fit two models: TPR and FPR.
`model` one of GeneralizedLinearModel, MixedModel

"""
function bifit(
    model, fx, dft, dff;
    fx2 = nothing, dstr = Binomial(), lnk = LogitLink(), kwargs...
)

    fx2 = if !isnothing(fx2)
        fx2
    else
        fx
    end

    return emodel(
        fit(model, fx, dft, dstr, lnk; kwargs...),
        fit(model, fx2, dff, dstr, lnk; kwargs...)
    )
end

export bifit

function distance_interaction!(col, v)
    v2 = string(v) * "_notinf" |> Symbol
    fnte = .!(isinf.(col[!, v]) .| isnan.(col[!, v])); # finite
    col[!, v2] = fnte
    col[.!fnte, v] .= 0 # revalue dist as zero when infinite
    vi = string(v) * "_i" |> Symbol
    col[!, vi] = col[!, v2] .* col[!, v] # create interaction
end

export distance_interaction!

##

function interm(x, term::Term)
    return x == term
end

function interm(x, term::InteractionTerm)
    return x ∈ term.terms
end

"""
        inform(x, fm::Vector{AbstractTerm})

## Description

Check whether `x` is in the formula (a vector that contains `Term` and/or `InteractionTerm` elements).

(Mainly, this is used to ascertain whether a covariate dropped by the Lasso is still retained in the selected set of interactions.)
"""
function inform(x, fm::Vector{T}) where T <: AbstractTerm
    for y in fm
        if interm(x, y)
            return true
        end
    end
    return false
end

"""
checkmains(mains, fm::Vector{AbstractTerm})

## Description

Check which main effects are dropped, and whether they are contained in any of
the selected interactions.
"""
function checkmains(mains, fm::Vector{T}) where T <: AbstractTerm
    m = setdiff(mains, fm)
    xo = Bool[]
    for x in m
        push!(xo, inform(x, fm))
    end
    return Dict(m .=> xo)
end

export checkmains
