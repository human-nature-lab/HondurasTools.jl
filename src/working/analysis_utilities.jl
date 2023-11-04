# analysis_utilities.jl
# functions to assist with generating model formulas

##

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

"""
        pairwise_formula(y, preds)

Construct a formula that contains effects for each variable in `pred` with all pairwise interactions.
"""
function pairwise_formula(y, preds)
    allpreds = reduce(+, Term.(preds)) + pairwiseinteractions(preds)
    return Term(y) ~ allpreds
end

export pairwise_formula

"""
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
function bifit(fx, dft, dff; fx2 = nothing, dstr = Binomial(), lnk = LogitLink())

    fx2 = if !isnothing(fx2)
        fx2
    else
        fx
    end

    return emodel(
        fit(model, fx, dft, dstr, lnk),
        fit(model, fx2, dff, dstr, lnk),
    )
end

export bifit
