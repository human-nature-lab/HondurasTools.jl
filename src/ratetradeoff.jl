# ratetradeoff.jl

@inline rotation(θ) =  [cos(θ) -sin(θ); sin(θ) cos(θ)]

"""
        ratetradeoff(jvals, fprvals)

## Description

Calculate the tradeoff (x) vs. strictchange (y) measure for a variable, using the maximum and minimum j points.

"""
function ratetradeoff(fprvals, tprvals; θ = -π/4)
    pts = Point2f.(fprvals, tprvals)
    ptst = [rotation(θ) * pt for pt in pts]
    xt = [pt[1] for pt in ptst]
    yt = [pt[2] for pt in ptst]

    xtmn, xtmx = extrema(xt)
    ytmn, ytmx = extrema(yt)

    return Point2f(xtmx - xtmn, ytmx - ytmn)
end

"""
        ratetradeoffs(rdf, variables)

## Description

Calculate the tradeoff (x) vs. strictchange (y) measures for each. Where x is the transformed (by 45 degrees, to a basis formed by y=x, and y=1-x) maximum fpr difference, and y is the transformed (by 45 degrees, to a basis formed by y=x, and y=1-x) maximum J.

`rdf`: The marginal effects DataFrame, including each variable with column `variable`.

"""
function ratetradeoffs(rdf::AbstractDataFrame, variables)
    tradeoffs = Dict{Symbol, Point2f}();
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

"""
        ratetradeoffs(md, variables)

## Description

Calculate the tradeoff (x) vs. strictchange (y) measures for each. Where x is the transformed (by 45 degrees, to a basis formed by y=x, and y=1-x) maximum fpr difference, and y is the transformed (by 45 degrees, to a basis formed by y=x, and y=1-x) maximum J.

`md`: Is a dictionary of marginal effects DataFrames, including each variable with column `variable`.

"""
function ratetradeoffs(md::T, variables) where T<:Dict
    tradeoffs = Dict{Symbol, Point2f}();
    for e in variables
        m = get(md, e, nothing)
        if !isnothing(md)
            rg = m.rg
            rg = @subset rg .!$kin

            # jvals = rg[!, :j]
            fprvals = rg[!, :fpr]
            tprvals = rg[!, :tpr]
            
            tradeoffs[e] = ratetradeoff(fprvals, tprvals; θ = -π/4)
        else @warn string(e) * " not in md"
        end
    end
    return tradeoffs
end

export ratetradeoff, ratetradeoffs
