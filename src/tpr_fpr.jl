# tpr_fpr.jl
# code for two stage appraoach to TPR vs. FPR

function fill_mthreads!(mthreads, bimodel)
    for i in eachindex(mthreads)
        mthreads[i] = deepcopy(bimodel)
    end
end

export fill_mthreads!

# fill rgb
function fill_rgb!(rgb, K, rates)
    for k in 1:K
        for r in rates
            rgb[!, string(r) * "_" * string(k)] = fill(NaN, nrow(rgb))
        end
    end
end

export fill_rgb!

function stage1_bs!(rgb, mthreads, βset, θset, rates, iters, invlink)
    Threads.@threads :static for k in eachindex(1:iters)
    # for k in eachindex(1:iters)
        for r in rates
            tid = Threads.threadid()
            MixedModels.setβ!(mthreads[tid][r], βset[k][r])
            MixedModels.setθ!(mthreads[tid][r], θset[k][r])

            effects!(
                rgb, mthreads[tid][r];
                eff_col = string(r) * "_" * string(k),
                err_col = Symbol("err_" * string(r)),
                invlink
            )
        end
    end
end

export stage1_bs!
