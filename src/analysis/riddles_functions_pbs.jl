# riddles_functions_pbs.jl
# parametric bootstrap functions

function riddle_forms(z, x)
    return [(@eval @formula($z ~ 1 + $x)),
    (@eval @formula($z ~ 1 + $x + age + man)),
    (@eval @formula($z ~ 1 + $x + age + man + degree))] 
end

export riddle_forms

trial(p) = rand(Bernoulli(p))

"""
		bieffects!(bf, bimodel, invlink; rates)

## Description

"""
function bieffects!(bf, bimodel, invlink; rates)
	for r in rates
		effects!(
			bf, bimodel[r];
			invlink,
			eff_col = r,
			err_col = Symbol(string(r) * "_err")
		);
	end
	bf[!, :j] .= bf[!, :tpr] - bf[!, :fpr];
	bf
end

export bieffects!

# helper functions to store simulated outcomes
@inline _inner1(l, K) = [Vector{Float64}(undef, l) for _ in 1:K]
@inline _inner2(l, K) = (; [r => _inner1(l, K) for r in [:tpr, :fpr, :j]]...)
@inline _inner3(outcomes, l, K) = (; [z => _inner2(l, K) for z in outcomes]...)

@inline yballocate(k, l) = [(
	tpr = Vector{Float64}(undef, l),
	fpr = Vector{Float64}(undef, l),
	j = Vector{Float64}(undef, l)
) for _ in 1:k
]

# @inline _minner1(K, mt) = Vector{mt}(undef, K) for _ in 1:K]
# @inline _minner2(l, K, mt) = (; [r => _minner1(l, K, mt) for r in [:tpr, :fpr, :j]]...)
# @inline _minner3(outcomes, l, K, mt) = (; [z => _minner2(l, K, mt) for z in outcomes]...)

"""
		parametricboot2stage(
            bimodel, pb, bef_,
            fitmodel, modelformulas, mls,
            ;
            iters = (L = 1, K = 1),
            rates = rates, riddles = riddles,
        )

## Description

parametric bootstrap for 2-stage model.

As written, this only works for binary outcomes models at the second stage.

"""
function parametricboot2stage(
	bimodel, pb, bf,
    fitmodel, modelformulas, nparam,
    ;
	iters = (L = 1, K = 1),
	rates = rates,
	invlink = logistic
)

	mt = StatsModels.TableRegressionModel;

	bf = deepcopy(bf) # this will have all the needed variables
    # copies of data for stage 2
	
	bfs = Vector{DataFrame}(undef, iters.K)
    for i in eachindex(bfs)
        bfs[i] = deepcopy(bf)
    end

    # We don't need K copies -> just overwrite the single copy
	# K copies of the bimodel
	# stage1_models = preallocate_bs_models(bimodel, iters.K)
    # stage1_model = deepcopy(bimodel)
	stage1_model = [deepcopy(bimodel) for _ in 1:iters.K];

	bootparams = _bootstore2(nparam, L, K)

	ems = Vector{ModelSet}(undef, iters.K)
	ybs = yballocate(iters.K, nrow(bf))

	# stage 1 link

	bieffects!(bf, bimodel, invlink; rates)

	m2_s = Vector{Vector{mt}}(undef, iters.K)
	for i in eachindex(m2_s)
		m2_s[i] = Vector{mt}(undef, 3)
	end

	@time @show "setup complete"

	_pb2stage_K!(
		bootparams,
		pb,
		m2_s, ybs, befs, ems, stage1_model,
		fitmodel, fxs,
		rates, iters,
		invlink,
	)

	return bootparams
end

export parametricboot2stage

function _pb2stage_K!(
	bootparams,
	pb,
	m2_s, ybs, befs, ems, stage1_model,
	fitmodel, fxs,
	rates, iters,
	invlink,
)
    
    # threads would be an issue here due to overwriting
    # this repeatedly overwrites bm with new param values
	Threads.@threads for k in 1:(iters.K)

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

		# end of first stage only material

		# this is also bootstrapping for J similar to aims 1 and 2

		# second stage model
        # (that forms the basis for the second stage bootstrap)
        # here, fit with with data from model 1 bootstrap iter k
		ems[k] = modelset(
			fitmodel(fxs[:tpr], bfs[k]),
			fitmodel(fxs[:fpr], bfs[k]),
			fitmodel(fxs[:j], bfs[k])
		)

		for r in [:tpr, :fpr, :j]
			# there are K prediction vectors, riddle_hat_{z,k}
			ybs[k][r] .= predict(ems[k][r])
		end

		_pb2stage_L!(
			bootparams, m2_s, bfs, ybs, fitmodel, fxs, k, iters.L
		)
	end
end

function _pb2stage_L!(bootparams, m2_s, bfs, ybs, fitmodel, fxs, k, L)

	for l in 1:L
		# parametric bootstrap at second stage
		# overwrites bf[k][!, z] at each rate

		# no case resampling
		# instead, sample new outcomes using model parameters

		for q in [:tpr, :fpr, :j]
			bfs[k][!, z] .= trial.(ybs[k][q]) # simulated outcomes
			m2_s[q][k] = fitmodel(fxs[q], bf)

			bootparams[q][l, k] .= coef(m2_s[k][q])
		end
	end
end

function preallocate_bs_models(bm, K)
	# this is slow and resource intensive
	bms = Vector{EModel}(undef, K)
	_preallocate_bs_models!(bms, bm)
    return bm
end

function _preallocate_bs_models!(bms, bm)
	Threads.@threads for k in eachindex(bms)
		bms[k] = deepcopy(bm)
	end
end

"""
		make_yb(rates, df, K)

## Description

- Preallocate for second-stage model predictions. K prediction vectors. For `BiModel` objects.

"""
function make_yb(rates, bef, K)
	return Dict(
		[r => [Vector{Float64}(undef, nrow(bef[r])) for _ in 1:K] for r in rates]
	)
end

# """
# Reference grids from stage 1 model, with estimates for each individual. Then, join the outcomes data.

# - Model estimates are calculated from this template during the K-L loop.
# """
# function dataforstage2!(befs, dats_, otc, regvars, efdicts, K, rates, addvars)
#     # Threads.@threads
# 	# for k in 1:K
# 	# 	befs[k] = refgrid_stage1(dats_, regvars, efdicts; rates)
# 	# 	# add outcomes
# 	# 	for r in rates
# 	# 		leftjoin!(
# 	# 			befs[k][r], otc; on = [:perceiver => :name],
# 	# 		)
#     #         if !isnothing(addvars)
#     #             leftjoin!(befs[k][r], addvars, on = [:perceiver => :name])
#     #         end
# 	# 	end
# 	# end

# end

"""


## Description

Make stage 2 data. See function for details on variables included.
"""
function stage2data(dats, otc, addvars, regvars; rates = rates, kinvals = false)
    efdicts = perceiver_efdicts(dats; kinvals)
    bef_ = refgrid_stage1(dats, regvars, efdicts; rates = rates)

	rvg1 = [setdiff([regvars..., :kin431], [:degree])..., [:dists_p]...]
	rvg2 = [setdiff([regvars..., :kin431], [:degree])..., [:dists_p, :dists_a]...]
	# include average degree (of the two relationships)
	tpr = @chain bef_.tpr begin
		groupby(rvg1)
		combine(:degree => mean => :degree)
	end

	fpr = @chain bef_.fpr begin
		groupby(rvg2)
		combine(:degree => mean => :degree)
	end
	bef_ = bidata(tpr, fpr)
    
	for r in rates
        if !isnothing(otc)
            leftjoin!(bef_[r], otc, on = [:perceiver => :name])
        end
        if !isnothing(addvars)
            leftjoin!(bef_[r], addvars, on = [:perceiver => :name])
        end
    end
    return bef_
end

export stage2data

# post bootstrap

function extractbootparams(
    bootparams, mls; riddles = riddles, rates = rates, func = std
)

    stds = Dict(
        z => Dict(
            r => Dict(e => Vector{Float64}(undef, np) for (e, np) in zip(keys(bootparams), mls)) for r in rates
        ) for z in riddles
    )

    for z in riddles
        for e in eachindex(mls)
            for r in rates
                mt = bootparams[e][z][r];
                lc = length(mt[1, 1]);

                # move preallocation out?
                mtv = let mtv = [Vector{Float64}(undef, size(mt, 1) * size(mt, 2)) for _ in 1:lc];
                    for (j, e1) in enumerate(mt)
                        for (k, e2) in enumerate(e1)
                            mtv[k][j] = e2
                        end
                    end
                    mtv
                end

                stds[z][r][e] = [func(x) for x in mtv]
            end
        end
    end
    return stds
end

export extractbootparams
