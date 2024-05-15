# ratetradeoff.jl

"""
        ratetradeoff(jvals, fprvals)

## Description

Calculate the tradeoff (x) vs. strictchange (y) measure for a variable. Where x is the transformed (by 45 degrees, to a basis formed by y=x, and y=1-x) maximum fpr difference, and y is the transformed (by 45 degrees, to a basis formed by y=x, and y=1-x) maximum J.

"""
function ratetradeoff(jvals, fprvals)
    jmx = maximum(jvals)
    strict = jmx * (inv∘sqrt)(2)

    fmn, fmx = extrema(fprvals)
    tradeoff = (fmx - fmn) * sqrt(2)

    return (tradeoff, strict)
end

export ratetradeoff

"""
        ratetradeoffs(rdf, variables)

## Description

Calculate the tradeoff (x) vs. strictchange (y) measures for each. Where x is the transformed (by 45 degrees, to a basis formed by y=x, and y=1-x) maximum fpr difference, and y is the transformed (by 45 degrees, to a basis formed by y=x, and y=1-x) maximum J.

`rdf`: The marginal effects DataFrame, including each variable with column `variable`.

"""
function ratetradeoffs(rdf, variables)
    tradeoffs = Dict{Symbol, Tuple{AbstractFloat, AbstractFloat}}();
    for e in variables
        if Symbol(e) ∈ rdf.variable
            idx = rdf[!, :variable] .== e
            
            jvals = rdf[idx, :j]
            fprvals = rdf[idx, :fpr]
            
            tradeoffs[e] = ratetradeoff(jvals, fprvals)
        else @warn string(e) * " not in rdf"
        end
    end
    return tradeoffs
end

export ratetradeoffs
