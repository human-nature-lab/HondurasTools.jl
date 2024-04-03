# riddles_functions_pbs.jl
# parametric bootstrap functions

trial(p) = rand(Bernoulli(p))

"""
		parametricboot2stage(
            bimodel, pb, regvars, dats_, otc;
            iters = (L = 1, K = 1),
            rates = rates, riddles = riddles,
        )

## Description

parametric bootstrap for 2-stage model.

"""
function parametricboot2stage(
	bimodel, pb, bef_,
    fitmodel, modelformulas, mls,
    ;
	iters = (L = 1, K = 1),
	rates = rates, riddles = riddles,
)

    # copies of data for stage 2
	befs = Vector{BiData}(undef, iters.K)
    for i in eachindex(befs)
        befs[i] = deepcopy(bef_)
    end

    # We don't need K copies -> just overwrite the single copy
	# K copies of the bimodel
	# stage1_models = preallocate_bs_models(bimodel, iters.K)
    stage1_model = deepcopy(bimodel)

	bootparams = Dict(
		i => bootstore(e, riddles, iters.L, iters.K) for (i, e) in enumerate(mls)
	)

	ems = Dict(z => Dict{Int, Vector{EModel}}() for z in riddles)

	# model versions in the order given in modelformulas
	for z in riddles
		for e in 1:length(modelformulas[z])
			ems[z][e] = Vector{EModel}(undef, iters.K)
		end
	end

	addeffects!(bef_, bimodel; rates = rates)

	ybs = Dict(z => make_yb(rates, bef_, iters.K) for z in riddles)

	m2_s = Vector{EModel}(undef, iters.K)

    # stage 1 link
    invlink = logistic;

	@time @show "setup complete"

	_pb2stage_K!(
		bootparams,
		pb,
		m2_s, ybs, befs, ems, stage1_model,
		fitmodel, modelformulas,
		riddles, rates, iters,
		invlink,
	)

	return bootparams
end

export parametricboot2stage

function _pb2stage_K!(
	bootparams,
	pb,
	m2_s, ybs, befs, ems, stage1_model,
	fitmodel, modelformulas,
	riddles, rates, iters,
	invlink,
)

    # Threads.@threads 
    # this repeatedly overwrites bm with new param values
	for k in 1:(iters.K)
		bm = stage1_model

		# install bootstrap values for prediction from stage 1 model
		# (comprehension to unpack to vector)
		for r in rates
			βsi = pb[r].fits[k].β
			θsi = pb[r].fits[k].θ

			MixedModels.setβ!(bm[r], [x for x in βsi])
			MixedModels.setθ!(bm[r], [x for x in θsi])
		end

		# marginal effects from stage 1 (as data for stage 2)
		apply_referencegrids!(bm, befs[k]; invlink)

		# second stage model
        # (that forms the basis for the second stage bootstrap)
        # here, fit with with data from model 1 bootstrap iter k
		for z in riddles
			for (e, fx) in enumerate(modelformulas[z])
				ems[z][e][k] = bifit(fitmodel, fx, befs[k])
				for r in rates
					# there are K prediction vectors, riddle_hat_{z,k}
					ybs[z][r][k] = predict(ems[z][e][k][r])
				end
			end
		end

		_pb2stage_L!(
			bootparams, m2_s, befs, ybs, fitmodel, modelformulas, k, iters.L,
			riddles, rates,
		)
	end
end

function _pb2stage_L!(
	bootparams, m2_s, befs, ybs,
	fitmodel, modelformulas,
	k, L,
	riddles, rates,
)
	for l in 1:L
		# parametric bootstrap at second stage
		# overwrites bef[r][!, z]

		# no case resampling
		# instead, sample new outcomes using model parameters
		for z in riddles
			for r in rates
				#=
				replace DataFrame col with simulated response vector
				lazily deal with missingness
				(difficult in the presence of 3
				response variables in the same DataFrame)

                N.B., since our second stage is binary, we simulate a response
                vector from the predicted probabilities
				=#
				befs[k][r][.!ismissing.(befs[k][r][!, z]), z] .= trial.(ybs[z][r][k])
			end
            
			for (e, fx) in enumerate(modelformulas[z])
				# overwrite within an l
				# within a z
				m2_s[k] = bifit(fitmodel, fx, befs[k])

				for r in rates
					# store parameters
					# for a riddle, for a rate
					# the vector of parameters is stored in position [l, k] of a matrix
					bootparams[e][z][r][l, k] .= coef(m2_s[k][r])
				end
			end
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

function make_yb(rates, bef, K)
	return Dict(
		[r => [Vector{Float64}(undef, nrow(bef[r])) for _ in 1:K] for r in rates]
	)
end

# """
# Reference grids from stage 1 model, with estimates for each individual. Then, join the outcomes data.

# - Model estiamtes are calculated from this template during the K-L loop.
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

function stage2data(dats, otc, addvars, regvars; rates = rates)
    efdicts = perceiver_efdicts(dats; kinvals = false)
    bef_ = refgrid_stage1(dats, regvars, efdicts; rates = rates)
    for r in rates
        leftjoin!(bef_[r], otc, on = [:perceiver => :name])
        if !isnothing(addvars)
            leftjoin!(bef_[r], addvars, on = [:perceiver => :name])
        end
    end
    return bef_
end

export stage2data
