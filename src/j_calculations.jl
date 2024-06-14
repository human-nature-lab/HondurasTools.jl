# j_calculations!.jl

"""
        j_calculations!(xc, iters)

Calculate the j statistic for the marginal effects of the TPR and FPR models, and bootstrap the standard errors / CIs for J.

`xc`: Combined reference grid, with `tpr`, `fpr` response columns and `err_tpr`, `err_fpr` standard errors.

Multithreaded over rows of `xc`
"""
function j_calculations!(xc, iters)
    xc.j .= NaN
    xc.err_j .= NaN

    dtpr = Distributions.Normal.(xc.tpr, xc.err_tpr);
    dfpr = Distributions.Normal.(xc.tpr, xc.err_tpr);

    dj = [Vector{Float64}(undef, iters) for _ in 1:nrow(xc)];
    _j_calculations!(dj, xc.tpr, xc.fpr, xc.j, xc.err_j, dtpr, dfpr)
end

function _j_calculations!(dj, tprv, fprv, j, err_j, dtpr, dfpr)
    Threads.@threads for i in eachindex(tprv)
        dj[i] .= NaN
        for j in eachindex(dj[i])
            dj[i][j] = rand(dtpr[i]) - rand(dfpr[i])
        end
        j[i] = tprv[i] - fprv[i]
        err_j[i] = std(dj[i])
    end
end

export j_calculations!

function j_calculations_pb!(rx, bm, βset, invlink, K; bivar = true)

    # store estimates at each bootstrap iteration
    ŷs = (
        tpr = [fill(NaN, size(rx, 1)) for _ in eachindex(1:K)],
        fpr = [fill(NaN, size(rx, 1)) for _ in eachindex(1:K)]
    )
    js = [fill(NaN, size(rx, 1)) for _ in eachindex(1:K)]
    
    _j_calculations_pb!(ŷs, rx, bm, βset, invlink, K)

    for (k, (a, b)) in (enumerate∘zip)(ŷs.tpr, ŷs.fpr)
        js[k] .= a + b
    end
    jst = (reduce)(hcat, js)

    return if !bivar
        std(eachcol(jst))
    else
        std(eachcol(jst)), _post_j_caluclations_pb(ŷs)
    end
end

export j_calculations_pb!

function _j_calculations_pb!(ŷs, rx, bm, βset, invlink, K; rates = rates)
    for k in eachindex(1:K)
        for r in rates
            MixedModels.setβ!(bm[r], βset[r][k, :β])
            MixedModels.setθ!(bm[r], βset[r][k, :θ])

            # we don't care about the standard errors from effects
            effects!(ŷs[r][k], rx, bm[r]; invlink)
        end
    end
end

# tpr, fpr
function _post_j_caluclations_pb(ŷs)
    ax = reduce(hcat, ŷs.tpr)
    bx = reduce(hcat, ŷs.fpr)
    tpl = Matrix{Point2f}(undef, size(ax))

    # (fpr, tpr)
    for (i, (c1, c2)) in (enumerate∘zip)(eachcol(bx), eachcol(ax))
        for (j, (x, y)) in (enumerate∘zip)(c1, c2)
            tpl[j, i] = Point2f(x, y)
        end
    end
    return tpl
end
