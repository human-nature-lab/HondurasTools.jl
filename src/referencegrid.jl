# referencegrid.jl

"""
        referencegrid(df::BiData, effectsdicts; rates = rates)

## Description

Apply `referencegrid` to a BiData object.
"""
function referencegrid(df::BiData, effectsdicts; rates = rates)
    return (; [r => referencegrid(df[r], effectsdicts[r]) for r in rates]...)
end

export referencegrid

"""
        referencegrid(df::AbstractDataFrame, effectsdict)

## Description

Construct a reference grid DataFrame from all possible combinations of the
input effects dictionary `effectsdict` values.
"""
function referencegrid(df::AbstractDataFrame, effectsdict)
    
    kys = collect(keys(effectsdict));
    cp = vec(collect(Iterators.product(values(effectsdict)...)));
    df = similar(df, length(cp));
    df = select(df, kys)

    for (i, c) in (enumerate∘eachcol)(df)
        c .= [e[i] for e in cp]
    end

    return df
end

export referencegrid

function apply_referencegrids!(
    m::EModel, referencegrids;
    invlink = identity, multithreaded = true
)
    if multithreaded
        #Threads.@threads for r in rates
        for r in rates
            effects!(referencegrids[r], m[r]; invlink)
        end
    else
        for r in rates
            effects!(referencegrids[r], m[r]; invlink)
        end
    end
end

export apply_referencegrids!

"""
        combinerefgrid(rg; rates = rates, kin = kin)

## Description

Combine separate rate reference grids.
"""
function combinerefgrid(rg, vbl, respvar; rates = rates, kin = kin)

    vx = intersect(names(rg.tpr), names(rg.fpr), [string(vbl), string(kin)])
    rgc = select(rg[:fpr], Not([:response, :err, :ci]))
    
    @assert rg[:tpr][!, vx] == rg[:fpr][!, vx]
    
    for r in rates rgc[!, r] = rg[r][!, respvar] end
    for r in rates rgc[!, "err_" * string(r)] = rg[r][!, :err] end
    for r in rates rgc[!, "ci_" * string(r)] = rg[r][!, :ci] end
    return rgc
end

export combinerefgrid

function processrefgrid(
    rg, bimodel, vbl, iters, invlink;
    pbs = nothing,
    respvar = :response,
    confrange = [0.025, 0.975],
    type = :normal
)
    rg = if !isnothing(pbs)
        jboot(
            vbl, bimodel, rg, pbs, iters; invlink, type,
            confrange, respvar = :response,
        )
    else
        combinerefgrid(rg, vbl, respvar)
    end

    return disallowmissing!(rg)
end

export processrefgrid
