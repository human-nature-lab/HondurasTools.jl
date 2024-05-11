# effects_utilities.jl

function bimargins(
    ms, vbls;
    tnr = true, invlink = logistic,
    vrs = [:response, :lower, :upper]
)

    # create design
    udict = design_dict(vbls, crt, crf)

    # basically, it seems like when there is a function of a variable
    # things do not work. manually specify.
    if !isnothing(manual_typicals)
        for v_ in manual_typicals
            udict[v_] = (mean∘skipmissing)(vcat(crt[!, v_], crf[!, v_]))
        end
    end

    dsn = Dict(udict...)
    tpr = ms.tpr; # getfield(ms, :tpr);
    fpr = ms.fpr; # getfield(ms, :fpr);
    eff_tpr = effects(dsn, tpr, invlink = invlink);
    eff_tpr.verity .= true;
    eff_fpr = effects(dsn, fpr, invlink = invlink);
    eff_fpr.verity .= false;

    lnkc = (invlink == logistic) | (invlink == ncdf)
    
    if tnr & lnkc
        eff_fpr[!, vrs]  = 1 .- eff_fpr[!, vrs] 
    elseif tnr & !lnkc
        error("scale error")
    end

    eff = vcat(eff_tpr, eff_fpr);
    select!(eff, Not(manual_typicals))
    return eff
end

export bimargins

function design_dict(vbls, crt, crf)
    udict = Dict{Symbol, Any}();
    for v in vbls

        udict[v] = unique(crt[!, v])

        ucrt = unique(crt[!, v]);
        ucrf = unique(crf[!, v]);
        ucr = intersect(ucrt, ucrf);
        if eltype(crt[!, v]) <: CategoricalValue
            ucr = categorical(ucr)
        end
        
        udict[v] = ucr |> skipmissing |> collect |> sort;
    end
    return udict
end

export design_dict

function truenegative!(rgs::Union{NamedTuple, BiData})
    rgs[:fpr][!, :response] = 1 .- rgs[:fpr][!, :response]
    rgs[:fpr][!, :ci] = tuple_addinv.(rgs[:fpr][!, :ci])
end

function truenegative!(df::AbstractDataFrame)
    df[!, :fpr] = 1 .- df[!, :fpr]
    df[!, :ci_fpr] = tuple_addinv.(df[!, :ci_fpr])
end

export truenegative!

"""
        usualeffects(dats; kinvals = [false, true])

Construct the dictionary foundation of the reference grids for most analyses.
"""
function usualeffects(dats; kinvals = [false, true])
    
    df_ = dats.fpr;
    
    # separate or the same (across rates)?
    ds = [dats[x][!, :dists_p][dats[x][!, :dists_p] .!= 0] for x in rates];
    distmean = mean(reduce(vcat, ds))    

    tpr_dict = Dict{Symbol, Any}()

    tpr_dict[:dists_p] = distmean

    if !isnothing(kinvals)
        tpr_dict[:kin431] = kinvals
    end

    fpr_dict = deepcopy(tpr_dict);
    fpr_dict[:dists_a] = mean(df_[df_[!, :dists_a] .!= 0, :dists_a])
    return (tpr = tpr_dict, fpr = fpr_dict,)
end

export usualeffects

"""
        usualeffects(dats, vbls; kinvals = [false, true])

Construct the dictionary foundation of the reference grids for most analyses. Include the range of a focal variable(s), `vbls`, observed in the data.
"""
function usualeffects(dats, vbls::Union{Vector{Symbol}, Symbol}; kinvals = [false, true])
    
    if typeof(vbls) <: Symbol
        vbls = [vbls]
    end

    df_ = dats.fpr;
    
    # separate or the same (across rates)?
    ds = [dats[x][!, :dists_p][dats[x][!, :dists_p] .!= 0] for x in rates];

    tpr_dict = Dict{Symbol, Any}()
    tpr_dict[:dists_p] = mean(reduce(vcat, ds))
    tpr_dict[:age] = mean(dats[:fpr].age)

    if !isnothing(kinvals)
        tpr_dict[:kin431] = kinvals
    end

    fpr_dict = deepcopy(tpr_dict);
    fpr_dict[:dists_a] = mean(df_[df_[!, :dists_a] .!= 0, :dists_a])

    effectsdicts = (tpr = tpr_dict, fpr = fpr_dict,)

    # add the range of the focal variable
    for r in rates
        for vbl in vbls
            effectsdicts[r][vbl] = (unique∘skipmissing∘vcat)(dats[:tpr][!, vbl], dats[:fpr][!, vbl])
        end
    end

    return effectsdicts
end

"""
        usualeffects(dats, additions; stratifykin = true, rates = rates)

Construct the dictionary foundation of the reference grids for most analyses. Include the range of a focal variable(s), specified as pairs in `additions`.
"""
function usualeffects(dats, additions; stratifykin = true, rates = rates)

    df_ = dats.fpr;
    
    # separate or the same (across rates)?
    ds = [dats[x][!, :dists_p][dats[x][!, :dists_p] .!= 0] for x in rates];

    tpr_dict = Dict{Symbol, Any}()
    tpr_dict[:dists_p] = mean(reduce(vcat, ds))
    tpr_dict[:age] = mean(dats[:fpr].age)

    fpr_dict = deepcopy(tpr_dict);
    fpr_dict[:dists_a] = mean(df_[df_[!, :dists_a] .!= 0, :dists_a])

    effectsdicts = (tpr = tpr_dict, fpr = fpr_dict,);

    if stratifykin
        for r in rates
            push!(effectsdicts[r], kin => [false, true])
        end
    end

    # add the range of the focal variable
    for r in rates
        for x in additions
            push!(effectsdicts[r], x)
        end
    end

    return effectsdicts
end

export usualeffects

function perceiver_efdicts(dats; kinvals = [false])
    dt_ = dats.tpr;
    df_ = dats.fpr;
    
    # separate or the same (across rates)?
    ds = [dats[x].dists_p[dats[x].dists_p .!= 0] for x in rates];
    distmean = mean(reduce(vcat, ds))    

    tpr_dict = Dict(
        :kin431 => kinvals,
        :dists_p => distmean,
    );

    fpr_dict = deepcopy(tpr_dict);
    fpr_dict[:dists_a] = mean(df_[df_[!, :dists_a] .!= 0, :dists_a])
    return (tpr = tpr_dict, fpr = fpr_dict)
end

export perceiver_efdicts

##

function adj_table(m, ses)
    ct1 = DataFrame(GLM.coeftable(m));
    x = coef(m) .± (ses .* 1.96)
    ct1[!, "Std. Error (Corrected)"] = ses
    ct1[!, "Lower 95% (Corrected)"] = [minimum(v) for v in x]
    ct1[!, "Upper 95% (Corrected)"] = [maximum(v) for v in x]
    ct1[!, "Pr(>|z|) (Corrected)"] = pvalues(m, ses)
    return ct1
end

export adj_table

function adjtable(mos, stds, z, r, i)
    m = mos[i][z][r]
    ses = stds[z][r][i]
    ct1 = DataFrame(GLM.coeftable(m));
    x = coef(m) .± (ses .* 1.96)
    ct1[!, "Std. Error (Corrected)"] = ses
    ct1[!, "Lower 95% (Corrected)"] = [minimum(v) for v in x]
    ct1[!, "Upper 95% (Corrected)"] = [maximum(v) for v in x]
    ct1[!, "Pr(>|z|) (Corrected)"] = pvalues(m, ses)
    return ct1
end

function adjtable(mos, stds, z, i)
    a = adjtable(mos, stds, z, :tpr, i)
    b = adjtable(mos, stds, z, :fpr, i)
    a.rate .= "tpr"
    b.rate .= "fpr"
    return vcat(a, b)
end

export adjtable

function pvalues(m)
    zstat = coef(m) ./ stderror(m)
    return 2 .* cdf(Distributions.Normal(), -abs.(zstat))
end

function pvalues(m, ses)
    zstat = coef(m) ./ ses
    return 2 .* cdf(Distributions.Normal(), -abs.(zstat))
end

export pvalues

function pvalue(est, se)
    zstat = est * inv(se)
    return 2 .* cdf(Distributions.Normal(), -abs(zstat))
end

export pvalue

"""
Generalize this.
"""
function ci(x, se; area = 1.96)
    return x ± se * area
end

export ci

function ci!(
    rgs::Union{NamedTuple, BiData}; x = :response, rates = rates, area = 1.96
)
    for r in rates
        if !isempty(rgs[r])
            rgs[r][!, :ci] = ci.(rgs[r][!, x], rgs[r][!, :err]; area)
        end
    end
end

export ci!

function ci!(rg::DataFrame; x = :response, area = 1.96)
        rg[!, :ci] = ci.(rg[!, x], rg[!, :err]; area)
end

export ci!
