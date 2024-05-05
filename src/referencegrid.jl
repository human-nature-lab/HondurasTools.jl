# referencegrid.jl

"""
        combinerefgrid(rg; rates = rates, kin = kin)

## Description

Combine separate rate reference grids.
"""
function combinerefgrid(rg, vbl; rates = rates, kin = kin)

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
    confrange = [0.025, 0.975],
    type = :normal
)
    rg = if !isnothing(pbs)
        jboot(
            vbl, bimodel, rg, pbs, iters; invlink, type,
            confrange, respvar = :response,
        )
    else
        combinerefgrid(rg, vbl)
    end

    return disallowmissing!(rg)
end

export processrefgrid
