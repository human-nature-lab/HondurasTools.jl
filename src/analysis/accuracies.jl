# bootstrapping.jl

function switch_params!(m1i, β, θ)
    m1i.β = β
    # m1i.σ
    m1i.θ = θ
end

function _bootresponses!(rgrid, m1i, invlink)
    # predictions at margin for bootstrap iter
    effects!(rgrid, m1i; invlink = invlink);
    return rgrid.response
end

# no σ since variance is fixed at 1 for logistic model
# (i, (βi, θi)) = collect(enumerate(zip(βvec, pbi.θ)))[1]
function bootresponses!(
    resps1, resps2, m1i, m2i, rgc, βvec1, pbθ1, βvec2, pbθ2, invlink
)

# pbθ1 = pb11.θ; pbθ2 = pb12.θ

#(i, (β1i, θ1i, β2i, θ2i)) = collect(enumerate(zip(βvec1, pbθ1, βvec2, pbθ2)))[1]
    for (i, (β1i, θ1i, β2i, θ2i)) in enumerate(zip(βvec1, pbθ1, βvec2, pbθ2))
        
        # alter the parameters and predict for bootstrapped param values
        
        # model 1 tpr
        switch_params!(m1i, β1i, θ1i)
        resps1[:, i] = _bootresponses!(rgc, m1i, invlink)

        # model 2 fpr
        switch_params!(m2i, β2i, θ2i)
        resps2[:, i] = _bootresponses!(rgc, m2i, invlink)

    end
end

export bootresponses!

function βextract(pbiβ, m1i)
    iters = maximum([pbib[1] for pbib in pbiβ])
    βvec = [Vector{Float64}(undef, length(m1i.β)) for _ in 1:iters]
    for (i, e) in enumerate(pbiβ)
        ix = i % length(m1i.β)
        ix = ix == 0 ? length(m1i.β) : ix
        βvec[e[1]][ix] = e[3]
    end
    return βvec
end

function booteffects(rgrid, m11, m12, pb11, pb12, invlink)

    rgc = deepcopy(rgrid);

    m1i = deepcopy(m11);
    m2i = deepcopy(m12);

    # bootstrap
    # pb11 = pb1[1];
    # pb12 = pb1[2];

    iters = length(pb11.θ);

    βvec1 = βextract(pb11.β, m1i);
    βvec2 = βextract(pb12.β, m2i);

    # match these to usual effects
    resps1 = fill(0., size(rgc, 1), iters);
    resps2 = fill(0., size(rgc, 1), iters);

    bootresponses!(resps1, resps2, m1i, m2i, rgc, βvec1, pb11.θ, βvec2, pb12.θ, invlink)

    return resps1, resps2
end

export booteffects

function makedesign(vbl, df)
    design = if isa(vbl, Symbol);
        Dict(vbl => unique(skipmissing(df[!, vbl])))
    else
        Dict(
            [vbl => unique(skipmissing(df[!, vbl])) for vbl in vbl]...
            )
    end;
    return design
end

function commondesign(des1, des2)
    design = Dict{Symbol, Vector}()
    for ((k1, v1), (k2, v2)) in zip(des1, des2)
        design[k1] = intersect(v1, v2)
    end
    return design
end

function common_rgrid(vbl, data1, data2)
    des1 = makedesign(vbl, data1)
    des2 = makedesign(vbl, data2)
    design = commondesign(des1, des2)
    return expand_grid(design);
end

"""
        pierce_stat(vbl, m, pb, dats)

Marginal effects for the sum of the TPR and FPR, for the common range across the two models. Confidence intervals are bootstrapped, with normal approximation intervals at 95%.

(function works with two models -- one for each rate.)
"""
function pierce_stat(vbl, m, pb, dats)
    
    m11 = m[1]; m12 = m[2]
    pb11 = pb[1]; pb12 = pb[2]

    rgrid = common_rgrid(vbl, dats[1], dats[2])

    resps1, resps2 = booteffects(
        rgrid, m11, m12, pb11, pb12, logistic
    )

    rt1 = resps1[1, :]
    rt2 = resps2[1, :]
    x = fill(0.0, 10000)
    for i in eachindex(x)
        x[i] = rand(rt1) + rand(rt2)
    end

    effects!(rgrid, m11; invlink = logistic)
    rename!(rgrid, :response => :response1, :err => :err1)
    rgrid[!, :lower1] = rgrid.response1 - rgrid.err1
    rgrid[!, :upper1] = rgrid.response1 + rgrid.err1

    effects!(rgrid, m12; invlink = logistic)
    rename!(rgrid, :response => :response2, :err => :err2)
    rgrid[!, :lower2] = rgrid.response2 - rgrid.err2
    rgrid[!, :upper2] = rgrid.response2 + rgrid.err2

    rgrid[!, :pierce] = rgrid.response1 - rgrid.response2
    rgrid[!, :lower_pierce] .= 0.0
    rgrid[!, :upper_pierce] .= 0.0
    rgrid[!, :err_pierce] .= 0.0

    # r = collect(eachrow(resps1 + resps2))[1]
    for (i, r) in enumerate(eachrow(resps1 - resps2))
        sd = std(r; corrected = true)
        est = rgrid[i, :pierce]
        
        rgrid[i, :err_pierce] = sd
        rgrid[i, :lower_pierce] = est - (2 * sd)
        rgrid[i, :upper_pierce] = est + (2 * sd)
    end
    
    return rgrid
end

export pierce_stat

function ac_extract(m1, pb1, datas, i)
    m = [m1[i], m1[i+1]];
    pb = [pb1[i], pb1[i+1]];
    dats = [datas[i], datas[i+1]];
    return m, pb, dats
end

function marginals(vbl, m1, pb1, datas)

    vbl1, vbl2 = if typeof(vbl) != Symbol
        if (typeof(vbl[2]) <: Vector) | (typeof(vbl[2]) <: Tuple)
            [vbl[1], vbl[2][1]], [vbl[1], vbl[2][2]]
        else
            vbl, vbl
        end
    else
        vbl, vbl
    end

    ac1_kin = pierce_stat(vbl1, ac_extract(m1, pb1, datas, 1)...)
    ac3_kin = pierce_stat(vbl2, ac_extract(m1, pb1, datas, 3)...)

    return ac1_kin, ac3_kin;
end

export marginals
