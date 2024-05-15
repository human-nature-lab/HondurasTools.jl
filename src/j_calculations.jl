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
