# bootmargins.jl
# bootstrapping the aim 1, 2 models for Youden's J

using GeometryBasics:Point

function _assign_margins!(
    mdf, mm, pbt, pbf, num_bs, blocks, vbl, kin, crt, crf, manual_typicals
)
    Threads.@threads for i in 1:num_bs
        block = blocks[i]
        # for a bimodel
        for (e, b) in zip([mm.tpr, mm.fpr], [pbt, pbf])

            # extract parameters
            gsβ = groupby(DataFrame(b.β), :iter);
            gsθ = b.θ;

            # install new parameters to mm
            e.β = gsβ[i].β
            e.θ = gsθ[i];
        end

        # calculate marginal effects (for both models)
        # we want tpr + fpr -> tnr = false
        mm_marg = bimargins(
            mm, [vbl, kin], crt, crf; tnr = false, manual_typicals
        );
        mm_marg.iter .= i;

        # could improve speed here
        # figure out: general case for rows and col num
        # append!(mdf, mm_marg)
        @assert nrow(mm_marg) == length(block)
        @assert sunique(names(mm_marg)) == sunique(names(mdf))
        mdf[block, :] = mm_marg[!, names(mdf)]
    end
end

"""
bootmargins(
    vbl, mm, pbt, pbf;
    resp_var = :response, iters = 1000, minimal = true
)

## Description

Input `bimodel` and `parametricbootstrap()` results for each to generate bootstrapped confidence intervals for Youden's J statistic over the margins of a variable of interest `vbl`. `iteration` specifies the number of replications for generating TPR 

"""
function bootmargins(
    vbl, mm, pbt, pbf, crt, crf;
    resp_var = :response, iters = 1000, outputall = false,
    kin = :kin431,
    manual_typicals = [:age]
)

    mm = deepcopy(mm);

    num_bs = length(pbt.θ);

    # hard-code stratification by kin
    udict = design_dict([vbl, kin], crt, crf);
    # vbl, kin, resp_var, :err, :lower, :upper, :verity, :iter 

    # *2 for verity
    rtype = Float64; # pred prob from logistic
    mdf_len = length(udict[vbl]) * length(udict[kin]) * num_bs * 2;
    iterlen = length(udict[vbl]) * length(udict[kin]) * 2;

    mdf0 = DataFrame(
        vbl => nonmissingtype(eltype(crt[!, vbl]))[],
        kin => nonmissingtype(eltype(crt[!, kin]))[],
        resp_var => rtype[],
        :err => Float64[],
        :lower => Float64[],
        :upper => Float64[],
        :verity => Bool[],
        :iter => Int[]
    );

    mdf = similar(mdf0, mdf_len);

    blocks = [(1:iterlen).+iterlen*(i-1) for i in 1:num_bs];

    # iteration
    # at each iter, install new parameters for `tpr` and `fpr` models
    # each i corresponds to a block in blocks

    _assign_margins!(
        mdf, mm, pbt, pbf, num_bs, blocks, vbl, kin, crt, crf, manual_typicals
    )

    # reduce to a nice format, partly wide, 
    mdf_ = @chain mdf begin
        groupby([kin, :verity, vbl])
        combine(:response => Ref, renamecols = false)
        groupby([kin, vbl])
        combine(:response => Ref, renamecols = false)
    end

    mdf_[!, :peirce] = [fill(NaN, iters) for  _ in eachindex(mdf_.response)];
    mdf_[!, :accuracy_2d] = [
        Vector{Point{2, Float64}}(undef, iters) for  _ in eachindex(mdf_.response)
    ];
    mdf_[!, :peirce_mean] = fill(NaN, nrow(mdf_));
    mdf_[!, :peirce_lwr] = fill(NaN, nrow(mdf_));
    mdf_[!, :peirce_upr] = fill(NaN, nrow(mdf_));
    mdf_[!, :peirce_err] = fill(NaN, nrow(mdf_));
    
    for (k, o) in enumerate(mdf_.response)
        tpr_, fpr_ = o;
        for j in 1:iters
            p1, p2 = rand(tpr_), rand(fpr_)
            mdf_.peirce[k][j] = p1 - p2 # J = TPR - FPR
            mdf_.accuracy_2d[k][j] = Point(p2, p1)
        end
        mdf_[k, :peirce_mean] = est = mean(mdf_.peirce[k])
        mdf_[k, :peirce_err] = std(mdf_.peirce[k], corrected = true);

        # https://www.stat.cmu.edu/~ryantibs/advmethods/notes/bootstrap.pdf
        # basic bootstrap CI
        q25, q975 = quantile(mdf_.peirce[k], [0.025, 0.975])

        mdf_[k, :peirce_lwr] = 2*est − q975;
        mdf_[k, :peirce_upr] = 2*est − q25;
    end

    mdf_.cov = [cov(dd) for dd in mdf_[!, :accuracy_2d]];

    return if outputall
        mdf_
    else
        select(mdf_, Not(resp_var))
    end
end

export bootmargins
