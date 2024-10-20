# margincalculations.jl

"""
        addmargins!(margindict, vbldict, bimodel, dat)

## Description

`margindict::Dict{Symbol, @NamedTuple{rg::DataFrame, name::String}}`: Margin dictionary to store estimated referencegrids by variable.

Calculates for most variables, but will not work for distance.
"""
function addmargins!(
    margindict, vbldict, bimodel, dat;
    margresolution = 0.001, allvalues = false
)
    # for p in keys(vbldict)
    Threads.@threads for p in keys(vbldict)
        e, name = vbldict[p]
        ed = standarddict(dat; kinvals = [false, true])
        ed[e] = marginrange(dat, e; margresolution, allvalues)
        rg = referencegrid(dat, ed)
        estimaterates!(rg, bimodel; iters = 20_000)
        ci_rates!(rg)
        margindict[e] = (rg = rg, name = name,)
    end
end

function _innermargins!(
    margindict, vbldict, dat, kinvals, margresolution, allvalues,
    bms, bimodel, invlink, K, bivar, βset, L
)
    Threads.@threads for i in L
        e, name = vbldict[i]
        ed = standarddict(dat; kinvals)
        ed[e] = marginrange(dat, e; margresolution, allvalues)
        rg = referencegrid(dat, ed)
        
        # iters = nothing since j will be bootstrapped
        estimaterates!(rg, bimodel; iters = nothing)
        rg[!, :j] = rg[!, :tpr] - rg[!, :fpr]
        ses, bv = j_calculations_pb!(rg, bms[i], βset, invlink, K; bivar)
        rg[!, :err_j] = ses
        rg[!, :ci_j] = ci.(rg[!, :j], rg[!, :err_j])
        rg[!, :ci_tpr] = ci.(rg[!, :tpr], rg[!, :err_tpr])
        rg[!, :ci_fpr] = ci.(rg[!, :fpr], rg[!, :err_fpr])
        rg[!, :Σ] = cov.(eachrow(bv))

        margindict[e] = (rg = rg, name = name,)
    end
end

function addmargins!(
    margindict, vbldict, bimodel, pbs, dat, K, invlink;
    margresolution = 0.001, allvalues = false,
    kinvals = [false, true],
    bivar = true
)
    L = eachindex(vbldict)
    bms = [deepcopy(bimodel) for _ in L]
    βset = pbs_process(pbs)

    _innermargins!(
        margindict, vbldict, dat, kinvals, margresolution, allvalues,
        bms, bimodel, invlink, K, bivar, βset, L
    )
end

export addmargins!

function altermargins_bs!(
    margindict, bm, βset, invlink, K; bivar = true
)

    bms = [deepcopy(bm) for _ in eachindex(1:length(margindict))]
    kys = (collect∘keys)(margindict)

    # for (i, p) in (enumerate∘eachindex)(kys)
    Threads.@threads for i in eachindex(1:length(margindict))
        p = kys[i]
        e, _ = margindict[p]
        ses, bv = j_calculations_pb!(e, bms[i], βset, invlink, K; bivar)
        e[!, :err_j] = ses
        e[!, :ci_j] = ci.(e[!, :j], e[!, :err_j])
        e[!, :Σ] = eachrow(bv)
    end
end

export altermargins_bs!

"""
        margindistgrid(d_; margresolution = 0.01, allvalues = true)

## Description

Estimate margins for distance variables.

`d_::Tuple{Symbol, Symbol}` = (:dists_p, :dists_p_notinf)

"""
function margindistgrid(
    d_::Tuple{Symbol, Symbol}, dat; margresolution = 0.01, allvalues = true
)

    ed = standarddict(dat; kinvals = [false, true])
    ed[d_[1]] = marginrange(dat, d_[1]; margresolution, allvalues)
    ed[d_[1]] = ed[d_[1]][ed[d_[1]] .> 0]
    ed[d_[2]] = true
    rg1 = referencegrid(dat, ed)

    ed2 = standarddict(dat; kinvals = [false, true])
    ed2[d_[2]] = false
    ed2[d_[1]] = 0
    rg2 = referencegrid(dat, ed2)

    return vcat(rg1, rg2)    
end

export margindistgrid
