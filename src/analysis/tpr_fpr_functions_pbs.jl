# riddles_functions_pbs.jl
# parametric bootstrap functions

# pbs for glm

"""
		simulation(m)

## Description

Simulate from a model.
"""
function simulation(m)
	return Distributions.Normal.(predict(m), sqrt(deviance(m)/dof_residual(m)))
end

function simulation(x, m)
	return Distributions.Normal(x, sqrt(deviance(m)/dof_residual(m)))
end

"""
		simulations!(b, x, m)

## Description

Simulate from a model.
"""
function simulations!(b, x, m)
	@assert length(b) == length(x)
	for (i, v) in enumerate(x)
		b[i] = passmissing(rand∘simulation)(v, m)
	end
end

"""
		t_parametricboot2stage(
            bimodel, pb, bef_,
            fitmodel, modelformulas, mls,
			outcomes
            ;
            iters = (L = 1, K = 1),
            rates = rates,
        )

## Description

Parametric bootstrap for 2-stage model.

As written, this only works for binary outcomes models at the second stage.

"""
function t_parametricboot2stage(
	bimodel, pb, bef, bf,
    fitmodel, modelformulas, mls,
	outcomes
    ;
	iters = (L = 1, K = 1),
	rates = rates,
)

    # copies of data for stage 2
	befs = Vector{BiData}(undef, iters.K)
    for i in eachindex(befs)
        befs[i] = deepcopy(bef)
    end

    # stage1_model = deepcopy(bimodel)
	stage1_model = [deepcopy(bimodel) for _ in 1:iters.K];

	bootparams = Dict(
		i => bootstore(e, iters.L, iters.K, outcomes) for (i, e) in enumerate(mls)
	)

	mt2 = StatsModels.TableRegressionModel;
	ems = (; [z => Dict{Int, Vector{mt2}}() for z in outcomes]...)

	# model versions in the order given in modelformulas
	for z in outcomes
		for e in 1:length(modelformulas[z])
			ems[z][e] = Vector{mt2}(undef, iters.K)
		end
	end

	# addeffects!(bef_, bimodel; rates = rates)

	ybs = (; [z => make_yb(bf, iters.K) for z in outcomes]...)

	m2_s = Vector{mt2}(undef, iters.K)

    # stage 1 link
    invlink = logistic;

	@time @show "setup complete"

	t_pb2stage_K!(
		bootparams,
		pb,
		m2_s, ybs, befs,
		ems, stage1_model,
		fitmodel, modelformulas,
		outcomes, rates, iters,
		invlink,
	)

	return bootparams
end

export t_parametricboot2stage

function t_pb2stage_K!(
	bootparams,
	pb,
	m2_s, ybs, befs, ems, stage1_model,
	fitmodel, modelformulas,
	outcomes, rates, iters,
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
		apply_referencegrids!(stage1_model[k], befs[k]; invlink)

		rename!(befs[k][:tpr], :response => :tpr)
		rename!(befs[k][:fpr], :response => :fpr)
		
		# use tpr DataFrame as the second stage DataFrame
		leftjoin!(
			befs[k][:tpr], befs[k][:fpr][!, [:perceiver, :fpr]],
			on = :perceiver
		)

		# second stage model
        # (that forms the basis for the second stage bootstrap)
        # here, fit with with data from model 1 bootstrap iter k
		for z in outcomes
			for (e, fx) in enumerate(modelformulas[z])
				ems[z][e][k] = fitmodel(fx, befs[k][:tpr])
			
				# there are K prediction vectors, riddle_hat_{z,k}
				ybs[z][k] = predict(ems[z][e][k])
			end
		end

		t_pb2stage_L!(
			bootparams, m2_s, befs, ybs, fitmodel, modelformulas, k, iters.L,
			outcomes, ems
		)
	end
end

function t_pb2stage_L!(
	bootparams, m2_s, befs, ybs,
	fitmodel, modelformulas,
	k, L,
	outcomes, ems
)

	for l in 1:L
		# parametric bootstrap at second stage
		# overwrites bef[r][!, z]

		# no case resampling
		# instead, sample new outcomes using model parameters
		for z in outcomes
			for (e, fx) in enumerate(modelformulas[z])
				#=
				replace DataFrame col with simulated response vector
				lazily deal with missingness
				(difficult in the presence of 3
				response variables in the same DataFrame)

                N.B., since our second stage is binary, we simulate a response
                vector from the predicted probabilities
				=#
				simulations!(
					@views(befs[k][:tpr][.!ismissing.(befs[k][:tpr][!, :fpr]), z]), # simulated outcome values
					ybs[z][k], # predicted outcome values
					ems[z][e][k] # model
				);

				# overwrite within an l
				# within a z
				m2_s[k] = fitmodel(fx, befs[k][:tpr])

				# store parameters
				# for a riddle, for a rate
				# the vector of parameters is stored in position [l, k] of a matrix
				bootparams[e][z][l, k] .= coef(m2_s[k])
			end
		end
	end
end

"""
		make_yb(df, K)

## Description

- Preallocate for second-stage model predictions. K prediction vectors.

"""
function make_yb(df, K)
	return [Vector{Float64}(undef, nrow(df)) for _ in 1:K]
end

export make_yb

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

# post bootstrap

function extractbootparams_one(
	bootparams, mls; riddles = riddles, rates = rates, func = std
)

    stds = Dict(
        z => Dict(e => Vector{Float64}(undef, np) for (e, np) in zip(keys(bootparams), mls)) for z in riddles
    )

    for z in riddles
        for e in eachindex(mls)
			mt = bootparams[e][z];
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

			stds[z][e] = [func(x) for x in mtv]
        end
    end
    return stds
end

export extractbootparams
