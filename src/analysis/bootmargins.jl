# bootmargins.jl
# bootstrapping the aim 1, 2 models for Youden's J

using GeometryBasics:Point

"""
        bootstrapdata(pbs, iters)

## Description

Create a structure to easily access bootstrap coefficients.
"""
function bootstrapdata(pbs, iters)
    Θ = (
        tpr = (
            β = Vector{Vector{Float64}}(undef, iters),
            θ = Vector{Vector{Float64}}(undef, iters)
        ),
        fpr = (
            β = Vector{Vector{Float64}}(undef, iters),
            θ = Vector{Vector{Float64}}(undef, iters)
        ),
    );

    gβ = (
        tpr = groupby(DataFrame(pbs[:tpr].β), :iter),
        fpr = groupby(DataFrame(pbs[:fpr].β), :iter)
    );

    for r in rates
        for i in eachindex(1:iters)
            # check name order
            # @assert gβ[r][i][!, :coefname] ...
            Θ[r][:β][i] = gβ[r][i].β
            Θ[r][:θ][i] = pbs[r].θ[i]
        end
    end
    return Θ
end

function _bootstrap_allocate(refgrids, iters, respvar)

    bstimates = (
        tpr = Vector{Vector{Float64}}(undef, iters),
        fpr = Vector{Vector{Float64}}(undef, iters),
    );

    for r in rates
        for i in eachindex(bstimates[:tpr])
            bstimates[r][i] = similar(refgrids[:tpr][!, respvar])
        end
    end
    return bstimates
end

function _installparams!(bm, Θ, i, rates)
    for r in rates
        e = @views bm[r]
        b, u = Θ[r]
        
        # install new parameters to bimodel
        e.β = b[i]
        e.θ = u[i];
    end
end


"""
        _assignmargins!(bstimates, refgrids, bm, Θ, iters, invlink, rates)

## Description

Calculated bootstrapped marginal effects from the bootstrap parameter distributions from the model bootstrap. (no additional randomness here.)

`iters` should be the number of iterations in the parametric bootstrap for the linear model.
"""
function _assignmargins!(bstimates, refgrids, bm, Θ, iters, invlink, rates)
    for i in 1:iters
        _installparams!(bm, Θ, i, rates)

        # marginal effect calculation
        # overwrite -> this would have to be adjusted for Threads
        apply_referencegrids!(
            bm, refgrids;
            invlink, multithreaded = false
        )

        # copy to the storage location
        # no easy way to avoid effects! dump into a the refgrid dataframe
        for r in rates
            bstimates[r][i] .= refgrids[r][!, :response]
        end
    end
end

"""
        postprocess_bootstrap!(refgrids, bstimates, iters)

## Description

Rearrange and store bootstrap predictions in the refgrids.
"""
function postprocess_bootstrap!(refgrids, bstimates, iters)
    for r in rates
        refgrids[r].response_bs = Vector{Vector{Float64}}(
            undef, nrow(refgrids[r])
        );
        for i in 1:nrow(refgrids[r])
            refgrids[r].response_bs[i] = Vector{Float64}(undef, iters) 
        end
    end
    for r in rates
        for i in 1:nrow(refgrids[r])
            refgrids[r][i, :response_bs] = [e[i] for e in bstimates[r]]
        end
    end
end

"""
        bootmargins(
            vbl, mm, pbt, pbf;
            resp_var = :response, iters = 1000, minimal = true
        )

## Description

        jboot(
            vbl, bimodel, pbs, dats;
            iters = 1000,
            invlink = identity,
            respvar = :response
        )

## Description

Input `bimodel` and `parametricbootstrap()` results for each to generate bootstrapped confidence intervals for Youden's J statistic over the margins of a variable of interest `vbl`. `iteration` specifies the number of replications for generating TPR 

- `iters`: number of iterations for j calculation (separate from number iters in the model bootstrap)

"""
function jboot(
    vbl, bimodel, refgrids, pbs, iters;
    invlink = identity,
    confrange = [0.025, 0.975],
    respvar = :response,
    type = :percentile
)

    if typeof(vbl) == Symbol
        vbl = [vbl]
    end

    # we will overwrite these columns repeatedly during the bootstrap
    refgrids = deepcopy(refgrids)

    for r in rates
        dropmissing!(refgrids[r], [vbl..., kin])
    end

    inc_names = (
        tpr = setdiff(names(refgrids.tpr), ["err", "ci"]),
        fpr = setdiff(names(refgrids.fpr), ["err", "ci"])
    )
    for r in rates; select!(refgrids[r], inc_names[r]) end

    # we will overwrite the model parameters during the bootstrap
    # (this strategy simplifies prediction and marginal effects calculation)
    bm = deepcopy(bimodel);

    @assert nrow(refgrids[:tpr]) .== nrow(refgrids[:fpr])
    
    bslen = length(pbs.tpr.σ) # number of iterations in `pbs`

    # bstimates corresponds to the response column in each refgrid in refgrids
    bstimates = _bootstrap_allocate(refgrids, bslen, respvar)
    Θ = bootstrapdata(pbs, bslen);

    # calculate distribution of marginal effect predictions based on
    # resampled values from the model bootstrap
    _assignmargins!(bstimates, refgrids, bm, Θ, bslen, invlink, rates);

    rg = deepcopy(refgrids);

    postprocess_bootstrap!(rg, bstimates, bslen);

    # use original model
    apply_referencegrids!(bimodel, rg; invlink)
    ci!(rg)

    # combine rate rg data -> rgc
    for r in rates; sort!(rg[r], [kin, vbl...]) end

    # if these are not the same, we cannot lazily combine:
    @assert(rg[:tpr][!, [kin, vbl...]] == rg[:fpr][!, [kin, vbl...]])

    # lazily add columns, renaming as appropriate
    rgc = select(rg[:fpr], Not([:response, :err, :ci, :response_bs]))
    for r in rates rgc[!, r] = rg[r][!, respvar] end
    for r in rates rgc[!, "err_" * string(r)] = rg[r][!, :err] end
    for r in rates rgc[!, "ci_" * string(r)] = rg[r][!, :ci] end
    for r in rates rgc[!, "bs_" * string(r)] = rg[r][!, :response_bs] end

    #=
    resample to calculate
       - two-dimensional accuracy scores
       - j statistic
    iters times (same as initial bootstrap, for simplicity)
    =#

    # data structures
    rgc.bs_accuracy = Vector{Vector{Point2{Float64}}}(undef, nrow(rgc))

    # calculate j statistic
    rgc[!, :peirce] = rgc[!, :tpr] - rgc[!, :fpr];

    rgc.bs_j = Vector{Vector{Float64}}(undef, nrow(rgc))
    
    for i in eachindex(rgc.bs_accuracy)
        rgc.bs_accuracy[i] = Vector{Point2}(undef, iters)
        rgc.bs_j[i] = Vector{Float64}(undef, iters)
    end

    _jboot!(rgc, iters)
    
    # basic bootstrap CI
    # https://www.stat.cmu.edu/~ryantibs/advmethods/notes/bootstrap.pdf
    rgc.ci_j = fill((NaN, NaN), nrow(rgc));
    rgc.bsinfo_j = Vector{NamedTuple}(undef, nrow(rgc));
    for (i, (x, θ)) in (enumerate∘zip)(rgc.bs_j, rgc.peirce)
        xbar = mean(x)
        se = std(x)
        qte = quantile(x, confrange)
        rgc.bsinfo_j[i] = (
            mean = xbar, std = se, ptiles = qte
        )
        rgc.ci_j[i] = bootinterval(θ, qte, se; type)
    end

    # for confidence ellipse calculation
    # https://www.stat.cmu.edu/~larry/=stat401/lecture-18.pdf
    rgc.Σ = [cov(x) for x in rgc.bs_accuracy]

    return rgc
end

export jboot

function bootinterval(θ, qte, se; type = :percentile)
    return if type == :basic
        2θ - qte[2], 2θ - qte[1]
    elseif type == :percentile
        qte[1], qte[2]
    elseif type == :normal
        θ ± se*1.96
    else
        error("type not improperly specified")
    end
end

"""
resample for j
"""
function _jboot!(rgc, iters)
    for (i, (s, v)) in (enumerate∘zip)(rgc.bs_tpr, rgc.bs_fpr)
        for j in 1:iters
            vr, sr = rand(v), rand(s)
            rgc.bs_accuracy[i][j] = Point(vr, sr) # (fpr, tpr)
            rgc.bs_j[i][j] = sr - vr # tpr - fpr
        end
    end
end
