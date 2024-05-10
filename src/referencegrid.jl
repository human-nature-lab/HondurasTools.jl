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

    vs = if typeof(vbl) <: Symbol
        [string(vbl), string(kin)]
    else
        [string.(vbl)..., string(kin)]
    end
    vx = intersect(names(rg.tpr), names(rg.fpr), vs)
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

"""
        j_calculations!(xc, iters)

Calculate the j statistic for the marginal effects of the TPR and FPR models, and bootstrap the standard errors / CIs for J.

`xc`: Combined reference grid, with `tpr`, `fpr` response columns and `err_tpr`, `err_fpr` standard errors.

Multithreaded over rows of `xc`
"""
function j_calculations!(xc, iters)
    xc.err_j .= NaN
    xc.j .= NaN
    xc.ci_j = fill((NaN, NaN), nrow(xc));

    dtpr = Distributions.Normal.(xc.tpr, xc.err_tpr);
    dfpr = Distributions.Normal.(xc.tpr, xc.err_tpr);

    dj = [Vector{Float64}(undef, iters) for _ in 1:nrow(xc)];
    _j_calculations!(dj, xc.tpr, xc.fpr, xc.j, xc.err_j, xc.ci_j, dtpr, dfpr)

end

function _j_calculations!(dj, tprv, fprv, j, err_j, ci_j, dtpr, dfpr)
    Threads.@threads for i in eachindex(tprv)
        dj[i] .= NaN
        for j in eachindex(dj[i])
            dj[i][j] = rand(dtpr[i]) - rand(dfpr[i])
        end
        j[i] = x = tprv[i] - fprv[i]
        err_j[i] = s = std(dj[i])
        ci_j[i] = ci(x, s)
    end
end

export j_calculations!
