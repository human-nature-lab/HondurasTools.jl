# newstrap.jl

"""
Repeated marginal effects from stage 1 model
"""
function stage2_bootdata(
	bimodel, pb, bf;
	K = 1,
	rates = rates,
	invlink = logistic # stage 1 link
)

	bf = deepcopy(bf) # this will have all the needed variables
    # copies of data for stage 2
	
	bfs = Vector{DataFrame}(undef, K)
    for i in eachindex(bfs)
        bfs[i] = deepcopy(bf)
    end

    # We don't need K copies -> just overwrite the single copy
	# K copies of the bimodel
	# stage1_models = preallocate_bs_models(bimodel, iters.K)
    # stage1_model = deepcopy(bimodel)
    stage1_model = Vector{EModel}(undef, K)
    
    for k in 1:K
	    stage1_model[k] = deepcopy(bimodel)
    end

	# bieffects!(bf, bimodel, invlink; rates)

	_stage2_bootdata!(
        bfs, pb,
        stage1_model,
        rates, K,
        invlink,
    )

	return bfs
end

export stage2_bootdata

function _stage2_bootdata!(
	bfs, pb,
	stage1_model,
	rates, K,
	invlink,
)
    
    # threads would be an issue here due to overwriting
    # this repeatedly overwrites bm with new param values
	Threads.@threads for k in 1:K

		# install bootstrap values for prediction from stage 1 model
		# (comprehension to unpack to vector)
		for r in rates
			βsi = pb[r].fits[k].β
			θsi = pb[r].fits[k].θ

			MixedModels.setβ!(stage1_model[k][r], [x for x in βsi])
			MixedModels.setθ!(stage1_model[k][r], [x for x in θsi])
		end

		# marginal effects from stage 1 (as data for stage 2)
		# apply_referencegrids!(stage1_model[k], befs[k]; invlink)
		bieffects!(bfs[k], stage1_model[k], invlink; rates);
    end
end

# stage 2

function ksetup(K, ln)
    ems = Vector{Vector{RegressionModel}}(undef, K);
    for i in eachindex(ems)
        ems[i] = Vector{RegressionModel}(undef, 3)
    end
    ysims = yballocate(K, ln);
    return ems, ysims
end

function kfill!(bfsk, emsk, ysimsk, fxs, fitmodel)
    for (i, q) in enumerate([:tpr, :fpr, :j])
        emsk[i] = fitmodel(fxs[q], bfsk)
        ysimsk[q] .= predict(emsk[i])
    end
end

# need a three place vector of models, m2_s

function innerboot(bp, ysim, bf, pbsmodel, outcome, fxs, fitmodel)
    for (i, q) in enumerate([:tpr, :fpr, :j])
        # there are K prediction vectors, riddle_hat_{z,k}
        bf[!, outcome] .= trial.(ysim[q]) # simulate outcomes (binary model)
        pbsmodel[i] = fitmodel(fxs[q], bf)

        bp[q] .= coef(pbsmodel[i])
    end
end

function twoboot(bfs, numparams, iters, fxs, outcome, fitmodel)
    bootparams = _bootstore3(numparams, iters.L, iters.K)
    ems, ysims = ksetup(iters.K, nrow(bfs[1]))
    twoboot!(bootparams, bfs, ems, ysims, fxs, outcome, iters, fitmodel)
    return bootparams
end

function twoboot!(bootparams, bfs, ems, ysims, fxs, outcome, iters, fitmodel)
    Threads.@threads for k in 1:(iters.K)
        kfill!(@views(bfs[k]), @views(ems[k]), @views(ysims[k]), fxs, fitmodel)
        
        for l in 1:(iters.L)
            innerboot(
                @views(bootparams[k, l]), @views(ysims[k]), @views(bfs[k]),
                @views(ems[k]), # can do this since we copied predicted to ysims
                outcome, fxs, fitmodel
            )
        end
    end
end

export twoboot

function _update_bf!(Q, dsq, A1, A2, j)
    for (i, (a1, a2)) in (enumerate∘zip)(A1, A2)
        Q[i] = abs(dsq[a1][j] - dsq[a2][j])
    end
end

function _update_bf!(Q, dsq, A1, A2)
    for (i, (a1, a2)) in (enumerate∘zip)(A1, A2)
        Q[i] = abs(dsq[a1] - dsq[a2])
    end
end

function update_edf!(edf_, ds, j)
    for (q, qr_) in zip([:tpr, :fpr, :j], [:tpr_ad, :fpr_ad, :j_ad])
         _update_bf!(edf_[!, qr_], ds[q], edf_.alter1, edf_.alter2, j)
    end
end

function update_edf!(edf_, ds)
    for (q, qr_) in zip([:tpr, :fpr, :j], [:tpr_ad, :fpr_ad, :j_ad])
         _update_bf!(edf_[!, qr_], ds[q], edf_.alter1, edf_.alter2)
    end
end

export update_edf!

function twoboot_s(edf, ds, numparams, iters, fxs, outcome, fitmodel)
    bootparams = _bootstore3(numparams, iters.L, iters.K)
    ems, ysims = ksetup(iters.K, nrow(edf))
    twoboot_s!(bootparams, edf, ems, ds, ysims, fxs, outcome, iters, fitmodel)
    return bootparams
end

function twoboot_s!(
	bootparams, edf, ems, ds, ysims, fxs, outcome, iters, fitmodel
)
    for k in 1:(iters.K) # cannot multithread here
		update_edf!(edf, ds, k) # replace with bootstrap stage1 bs values at k
        kfill!(@views(edf), @views(ems[k]), @views(ysims[k]), fxs, fitmodel)
        
        Threads.@threads for l in 1:(iters.L)
            innerboot(
                @views(bootparams[k, l]), @views(ysims[k]), @views(edf),
                @views(ems[k]), # can do this since we copied predicted to ysims
                outcome, fxs, fitmodel
            )
        end
    end
end

export twoboot_s

function bootinfo(eb)
    return (; [q => tuple.(mean.(eb[q]), std.(eb[q])) for q in [:tpr, :fpr, :j]]...)
end

function extract_bootparams(bootparams)
    return (; [q => _extract_bootparams(bootparams, q) for q in [:tpr, :fpr, :j]]...)
end

function _extract_bootparams(bootparams, q)
    qset = [e[q] for e in bootparams]
    pqset = reshape(qset, length(qset))
    return [[x[i] for x in pqset] for i in eachindex(pqset[1])]
end

export extract_bootparams, bootinfo

function zqeffects(z, q, bf, mout, vcdict, invlink)
    mx = mout[z][q]
    rx = DataFrame(q => sunique(bf[!, q]))
    boot_effects!(rx, mx, z, vcdict[z,q], invlink)
    return rx
end

export zqeffects
