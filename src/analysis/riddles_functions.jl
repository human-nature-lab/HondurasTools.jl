# riddles_functions.jl

"""
        stagetwo(outcome, ef_t, ef_f; x = :response)

## Description

Calculate the second-stage regression estimates, of the riddle on the accuracy score.
"""
function stagetwo(outcome, bef; x = :response, terms = nothing)

    fm = if isnothing(terms)
        Term(outcome) ~ Term(x)
    else
        Term(outcome) ~ Term(x) + terms
    end

    return emodel(
        fit(GeneralizedLinearModel, fm, bef.tpr, Binomial(), LogitLink()),
        fit(GeneralizedLinearModel, fm, bef.fpr, Binomial(), LogitLink())
    );
end

export stagetwo

function stagetwo(outcome, ef::DataFrame; terms = nothing)

    fm, fm2 = if isnothing(terms)
        a = Term(outcome) ~ Term(:tpr)
        b = Term(outcome) ~ Term(:fpr)
        a, b
    else
        a = Term(outcome) ~ Term(:tpr) + terms
        b = Term(outcome) ~ Term(:fpr) + terms
        a, b
    end
    
    return emodel(
        fit(GeneralizedLinearModel, fm, ef, Binomial(), LogitLink()),
        fit(GeneralizedLinearModel, fm2, ef, Binomial(), LogitLink())
    );
end

"""
        stagetwo_peirce(outcome, ef; x = :youden, terms = nothing)

## Description

Simple logistic regression on Youden/Peirce statistic for overall accuracy.
"""
function stagetwo_peirce(outcome, ef; x = :youden, terms = nothing)
    fm = if isnothing(terms)
        Term(outcome) ~ Term(x)
    else
        Term(outcome) ~ Term(x) + terms
    end
    
    return fit(GeneralizedLinearModel, fm, ef, Binomial(), LogitLink())
end

export stagetwo_peirce

"""
        riddle2stage(z, mz, mzj)

## Description

Generate regression tables for the second stage models.
"""
function riddle2stage(z, mz, mzj)
    zname = split(string(z), "_")[1]

    tbs = vec.([mz]);
    tbs = reduce(vcat, tbs);
    tbs = vcat(tbs..., mzj)
    cnames = ["(1)", "(2)", "(3)"]
    rp = processregs(tbs; cnames) 
    cap = "Second-stage estimates of " * zname * " riddle knowledge on accuracy, as represented by, (1) true positive rate, (2) false positive rate, and (3) Youden's J statistic, a summary measure of accuracy calculated as the first-stage estimated true positive rate minus the estimated false positive rate."
    exportregtable(prj.pp, prj.css, zname * "-riddle-models", rp, cap)
    rp
end

export riddle2stage

"""
        eff_stage2(
            ms, msj, ef;
            otc = [:zinc_rid, :cord_rid, :prenatal_rid],
            tnr = true,
            invlink = logistic, level = 0.95
        )

## Description

Fill out stage 2 marginal effects.
"""
function eff_stage2(
    ms, msj, ef;
    otc = [:zinc_rid, :cord_rid, :prenatal_rid],
    tnr = true,
    invlink = logistic, level = 0.95
)

    e_tpr = DataFrame();
    e_fpr = DataFrame();
    e_j = DataFrame();

    # check that model lengths are the same
    @assert length(ms) == length(msj)

    for (m, mj, o) in zip(ms, msj, otc)
        
        # intersection better?
        # how similar are they?
        vls = union(
            ef[.!ismissing.(ef[!, o]), :tpr],
            ef[.!ismissing.(ef[!, o]), :fpr]
        )

        vls_j = ef[.!ismissing.(ef[!, o]), :youden]

        dsn = Dict(:response => sunique(vls));
        dsnj = Dict(:youden => sunique(vls_j));

        for (m_, df, type) in zip(
            [m.tpr, m.fpr, mj], [e_tpr, e_fpr, e_j], ["tpr", "fpr", "j"]
        )

            dsn_ = if type == "j"
                dsnj
            else
                dsn
            end

            e = effects(dsn_, m_; invlink, level);
            rename!(e, o => :riddle)
            e[!, :outcome] = fill(string(o), nrow(e))
            append!(df, e)
        end
    end

    if tnr
        e_fpr[!, :response]  = 1 .- e_fpr[!, :response];
    end

    rename!(e_j, :youden => :response)

    return e_tpr, e_fpr, e_j
end

export eff_stage2

"""

## Description

add marginal effects, predict for each unique covariate combination that
represents a perceiver
take typical value for any measure repeated within a perceiver:
  - distance variables
  - relation
except kin, which is set to false
"""
function refgrid_stage1(dats, regvars, efdicts; rates = rates)

    # data sufficient to define unique perceivers (fixed effects)
    bef = bidata([unique(dats[r][!, regvars]) for r in rates]...)

    # check that rows in effects DataFrame equals number of perceivers
    for r in rates
        df = bef[r]
        @assert length(unique(df.perceiver)) == nrow(df)
    end

    # set the design for the marginal means
    for r in rates
        df = bef[r];

        for (k, v) in efdicts[r]
            df[!, k] = ifelse(length(v) == 1, fill(v, nrow(df)), v)
        end
    end

    for r in rates
        sort!(bef[r], [:village_code, :perceiver])
    end

    return bef
end

export refgrid_stage1

"""

## Description

stage 1 marginal effects, including whole set of individuals
"""
function addeffects!(bef, bm; otc = nothing, rates = rates, invlink = logistic)

    Threads.@threads for i in 1:2
        r = rates[i];
        df = bef[r];
        m_ = bm[r];

        effects!(df, m_);
        df.response = invlink.(df.response);

        if !isnothing(otc)
            # bring in the outcome variables, matched to the perceivers
            leftjoin!(df, otc, on = [:village_code, :perceiver => :name]);
        end
    end
end

export addeffects!

##

"""

## Description

Create object to store the bootstrapped coefficients for the stage 2 models,
for each of the outcomes.
"""
function bootstore(p, riddles, L, K)
    k = 1 # pick arbitrary index, all models are the same
    return Dict(
        reduce(
            vcat,
            [
                rid => Dict(
                    [r => [
                            Vector{Float64}(undef, p) for _ in 1:L, _ in 1:K
                                # N.B., we have 1_000 by 1_000 matrix of
                                # coef vectors
                        ] for r in rates
                    ]) for rid in riddles
            ]
        )
    )
end

export bootstore

function boot2stage!(
    bs_stage2mods, bs_stage2mods_dosage, bs_stage2mods_controls,
    stage2mods_bs, stage2mods_dosage_bs, stage2mods_controls_bs,
    m1, pb, regvars, efdicts, controls, dats_;
    ι = (L = 1_000, K = 1_000, rates = rates, riddles = riddles)
)

    Threads.@threads for k in 1:ι.K
    
        # install bootstrap values for prediction
        # (comprehension to unpack to vector)

        m1_ = deepcopy(m1)

        for r in ι.rates
            βsi = pb[r].fits[k].β;
            θsi = pb[r].fits[k].θ;

            MixedModels.setβ!(m1_[r], [x for x in βsi]);
            MixedModels.setθ!(m1_[r], [x for x in θsi]);
        end

        # marginal effects for stage 2
        # `efdicts` is constant over loop
        bef = refgrid_stage1(dats_, regvars, efdicts);
        addeffects!(bef, m1_, otc; rates = ι.rates);

        # second-stage estimates
        # N.B., kwarg x = :response
        # for z in riddles
        #     stage2mods[z][k] = stagetwo(z, bef);
        #     stage2mods_dosage[z][k] = stagetwo(z, bef; terms = Term(:dosage));
        #     stage2mods_controls[z][k] = stagetwo(z, bef; terms = controls);
        # end

        for l in 1:ι.L
            # resample 'data' for stage 2
            tn = rand(1:nrow(bef.tpr), nrow(bef.tpr));
            fn = rand(1:nrow(bef.fpr), nrow(bef.fpr));

            nt = @views(bef.tpr[tn, :]);
            nf = @views(bef.fpr[fn, :]);

            bd = bidata(nt, nf); # repackage SubDataFrames

            for z in ι.riddles
                # 1 is only index, rewrite at each l in L
                a = stage2mods_bs[z][1] = stagetwo(z, bd);
                b = stage2mods_dosage_bs[z][1] = stagetwo(
                    z, bd; terms = Term(:dosage)
                );
                c = stage2mods_controls_bs[z][1] = stagetwo(
                    z, bd; terms = controls
                );

                # store parameters
                # for a riddle, for a rate
                # the vector of parameters is stored in position [l, k] of a matrix
                # 
                for r in ι.rates
                    bs_stage2mods[z][r][l, k] .= coef(a[r])
                    bs_stage2mods_dosage[z][r][l, k] .= coef(b[r])
                    bs_stage2mods_controls[z][r][l, k] .= coef(c[r])
                end
            end
        end
    end
end

export boot2stage!

