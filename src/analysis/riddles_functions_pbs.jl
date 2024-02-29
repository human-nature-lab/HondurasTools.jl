# riddles_functions_pbs.jl
# parametric bootstrap functions

trial(p) = rand(Bernoulli(p))

"""
        parametricboot2stage

## Description

parametric bootstrap for 2-stage model.

"""
function parametricboot2stage(
    m1_s, pb, regvars, efdicts, dats, dats_, otc;
    L = 1, K = 1,
    ι = (
        rates = rates,
        riddles = riddles, variants = [nothing, Term(:dosage), controls]
    )
)

    bootparams = Dict(e => bootstore(c, riddles, L, K) for (e, c) in zip(ι.variants, [2,3,7])) # hard code number of parameters in the three variants

    ems = Dict(z => Dict{Any, Vector{EModel}}() for z in riddles);

    for z in riddles
        for e in ι.variants
            for r in rates
                ems[z][e] = Vector{EModel}(undef, K);
            end
        end
    end

    bef_ = refgrid_stage1(dats, regvars, efdicts; rates = rates);
    addeffects!(bef_, m1, otc; rates = rates);

    ybs = Dict(z => make_yb(rates, bef_, K) for z in riddles);
    befs = Vector{BiData}(undef, K);
    m2_s = Vector{EModel}(undef, K);

    @show "setup complete"

    _pb2stage!(
        bootparams,
        pb,
        m2_s, ybs, befs, ems, m1_s,
        efdicts, dats_, regvars, otc, ι, K, L
    )

    return bootparams
end

export parametricboot2stage

function make_yb(rates, bef, K)
    return Dict(
        [r => [Vector{Float64}(undef, nrow(bef[r])) for _ in 1:K] for r in rates]
    );
end

function _pb2stage!(
    bootparams,
    pb,
    m2_s, ybs, befs, ems, m1_s,
    efdicts, dats_, regvars, otc, ι, K, L
)
    
    Threads.@threads for k in 1:K
        m1_ = m1_s[k]
        
        # install bootstrap values for prediction from stage 1 model
        # (comprehension to unpack to vector)
        for r in ι.rates
            βsi = pb[r].fits[k].β;
            θsi = pb[r].fits[k].θ;

            MixedModels.setβ!(m1_[r], [x for x in βsi]);
            MixedModels.setθ!(m1_[r], [x for x in θsi]);
        end

        # marginal effects for stage 2
        # `efdicts` is constant over loop
        befs[k] = refgrid_stage1(dats_, regvars, efdicts);
        addeffects!(befs[k], m1_, otc; rates = ι.rates);
        # bef_resp = copy(bef[!, :response])
        
        # second stage model that forms the basis for the second stage bootstrap
        for z in ι.riddles
            for e in ι.variants
                ems[z][e][k] = stagetwo(z, befs[k]; terms = e)
                for r in rates
                    # there are K prediction vectors, riddle_hat_{z,k}
                    ybs[z][r][k] = predict(ems[z][e][k][r])
                end
            end
        end

        for l in 1:L
            # parametric bootstrap at second stage
            # overwrites bef[r][!, z]

            # no case resampling
            # instead, sample new outcomes using model parameters
            for z in ι.riddles
                for r in ι.rates
                    #=
                    replace DataFrame col with simulated response vector
                    lazily deal with missingness
                    (difficult in the presence of 3
                    response variables in the same DataFrame)
                    =#
                    befs[k][r][.!ismissing.(befs[k][r][!, z]), z] .= trial.(ybs[z][r][k])
                end
                
                for e in ι.variants
                    # overwrite within an l
                    # within a z
                    m2_s[k] = stagetwo(z, befs[k]; terms = e)
                    for r in ι.rates
                        # store parameters
                        # for a riddle, for a rate
                        # the vector of parameters is stored in position [l, k] of a matrix
                        bootparams[e][z][r][l, k] .= coef(m2_s[k][r])
                    end
                end
            end
        end
    end
end
