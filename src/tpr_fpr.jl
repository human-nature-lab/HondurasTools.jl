# tpr_fpr.jl
# code for two stage appraoach to TPR vs. FPR

function newstrap2!(τ, rgx, ŷst, mt, ysim, K, L, fitfunc, rte, fx_k, fx_l, ybootvar)
    # for k in eachindex(1:K)
    Threads.@threads :static for k in eachindex(1:K)
        tid = Threads.threadid()
        # stage 1 uncertainty (over K)
        rgx[!, Symbol(string(rte) * "_k")] .= ŷst[rte][k]
        mt[tid] = fitfunc(fx_k, rgx)
        ysim[k] .= predict(mt[tid])

        for l in eachindex(1:L)
            # stage 2 uncertainty (over L for a k)
            # simulate (bootstrap) the k model
            # with the simulated response
            rgx[!, ybootvar] .= rand.(Bernoulli.(ysim[k]))
            
            mt[tid] = mx2 = fitfunc(fx_l, rgx)
            τ[l, k] .= coef(mx2)
        end
    end
end

export newstrap2!

function newstrap2_lm!(
    τ, rgx, ŷst, mt, ysim, K, L, fitfunc, rte, fx_k, fx_l, ybootvar
)
    for k in eachindex(1:K)
    # Threads.@threads :static for k in eachindex(1:K)
        tid = Threads.threadid()
        # stage 1 uncertainty (over K)
        rgx[!, Symbol(string(rte) * "_k")] .= ŷst[rte][k]
        mt[tid] = fitfunc(fx_k, rgx)
        ysim[k] .= predict(mt[tid])

        _newstrap2_inner_lm!(τ[:, k], rgx[!, ybootvar], ysim[k], rgx, mt, fx_l, L, tid, fitfunc)
    end
end

function _newstrap2_inner_lm!(τ_k, ŷ, ysim_k, rgx, mt, fx_l, L, tid, fitfunc)
    for l in eachindex(1:L)
        # stage 2 uncertainty (over L for a k)
        # simulate (bootstrap) the k model
        # with the simulated response
        ŷ .= rand.(Normal.(ysim_k, sqrt(deviance(mt[tid])/dof_residual(mt[tid]))))
        
        mt[tid] = mx2 = fitfunc(fx_l, rgx)
        τ_k[l] .= coef(mx2)
    end
end

export newstrap2_lm!

function pbs_process(pbs)
    A = @chain pbs.tpr.β begin
        DataFrame()
        groupby(:iter)
        combine([x => Ref => x for x in [:coefname, :β]]...)
    end

    A.θ = pbs.tpr.θ

    B = @chain pbs.fpr.β begin
        DataFrame()
        groupby(:iter)
        combine([x => Ref => x for x in [:coefname, :β]]...)
    end

    B.θ = pbs.fpr.θ

    return (tpr = A, fpr = B)
end

export pbs_process

function newstrap!(ŷs, rx, bm2, βset, K, invlink)
    for k in eachindex(1:K)
        for r in rates
            MixedModels.setβ!(bm2[r], βset[r][k, :β])
            MixedModels.setθ!(bm2[r], βset[r][k, :θ])

            # we don't care about the standard errors from effects
            effects!(ŷs[r][k], rx, bm2[r]; invlink)
        end
    end
end

export newstrap!

#=
K = 1_000
L = 10_000
βout = [fill(NaN, 13) for i in eachindex(1:(K*L))];
βout = reshape(βout, L, K)
rgxb[!, :tpr_k] .= NaN
simulation!(βout, ms, rgxb, fx, K,L)
βreorg = [vec([βout[j][i] for j in 1:length(βout)]) for i in eachindex(1:13)]
vc = varcov(βreorg)
=#
function simulation!(βout, ms, rgxb, fx, K,L)
    for k in eachindex(1:K)
        # simulate to get first-stage uncertainty (via err in what is stage 2 data)
        rgxb[!, :tpr_k] .= rand.(Normal.(rgxb.tpr, rgxb.err_tpr))
        ms[1] = fit(GeneralizedLinearModel, fx, rgxb, Binomial(), LogitLink())
        for l in eachindex(1:L)
            # simulate using stage 2 std error to get uncertainty at second stage
            βout[l, k] .= rand.(Normal.(coef(ms[1]), stderror(ms[1])))
        end
    end
end

export simulation!

##

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

            # we don't care about the standard errors from effects
        end
    end
end

export stage1_bs!

"""
        stage2_bs!(efset, rgb, fx_bs, mthreads, K, L, invlink, fitfunc)

## Description

fitfunc: function to fit the model, basically `fit` with arguments entered; e.g.:

@inline fitfunc(fx, df) = fit(
    MixedModel, fx, df, Bernoulli(), LogitLink(); fast = true
)
"""
function stage2_bs!(
    efset, βs, ses, θs, rgb, rte, yvar, fx_bs, mthreads, K, L, invlink, fitfunc
)
    for l in eachindex(1:L)
        # Threads.@threads :static 
        for k in eachindex(1:K)
            tid = Threads.threadid()
            # mthreads[tid] = fit(modeltype, fx_bs[k], rgb)
            mthreads[tid] = fitfunc(fx_bs[k], rgb)

            # no σ since logistic
            βs[k] .= coef(mthreads[tid])
            ses[k] .= stderror(mthreads[tid])
            θs[k] .= ranef(mthreads[tid])

            if k > 1
                rename!(
                    efset[l],
                    string(rte) * "_" * string(k-1) =>
                    string(rte) * "_" * string(k)
                )
            elseif k == 1
                rename!(
                    efset[l],
                    string(rte) * "_i" =>
                    string(rte) * "_" * string(k)
                )
            end
            effects!(
                efset[l], mthreads[tid];
                eff_col = string(yvar) * "_" * string(k),
                err_col = Symbol("err_" * string(yvar)),
                invlink
            )
        end
    end
end

function stage2_bs_preallocate(m, K)
    βs = [fill(NaN, length(coef(m))) for _ in 1:K]
    vcovs = [vcov(m) for _ in 1:K]
    for e in vcovs
        e .= NaN
    end
    θs = [deepcopy(m.θ) for _ in 1:K]
    for e in θs
        e .= NaN
    end
    τ = (β = βs, vcov = vcovs, θ = θs, )
    return τ
end

export stage2_bs_preallocate

# Threads.@threads :static # don't bother since estimation is multithreaded
# tid = Threads.threadid()
function stage2_bs!(τ, rgb, fx_bs, mthreads, K, fitfunc)
    for k in eachindex(1:K)
        mthreads[1] = fitfunc(fx_bs[k], rgb)

        # no σ since logistic
        τ.β[k] .= coef(mthreads[1])
        τ.vcov[k] .= vcov(mthreads[1])
        τ.θ[k] .= mthreads[1].θ
        @show k
    end
end

export stage2_bs!

function stage2_bs_glm!(τ, rgb, fx_bs, mthreads, K, L, fitfunc)
    
    ysim = [fill(NaN, nrow(rgb)) for _ in eachindex(mthreads)]
    _stage2_bs_glm!(τ, ysim, mthreads, fx_bs, rgb, K, L, fitfunc)
end

export stage2_bs_glm!

function _stage2_bs_glm!(τ, ysim, mthreads, fx_bs, rgb, K, L, fitfunc)
    # for k in eachindex(1:K)
    Threads.@threads :static for k in eachindex(1:K)
        tid = Threads.threadid();
        # fit the k model
        try
            mthreads[tid] = mx = fitfunc(fx_bs[k], rgb)
            ysim[tid] .= predict(mx)

            # simulate (bootstrap) the k model
            # with the simulated response
            for l in eachindex(1:L)
                rgb.knows .= rand.(Bernoulli.(ysim[tid]))
                try
                    mthreads[tid] = mx2 = fitfunc(fx_bs[k], rgb)
                    τ[l, k] .= coef(mx2)
                catch
                    @show "issue " * string(k)
                    τ[l, k] .= NaN
                    continue
                end
            end
        catch
            continue
        end
    end
end
