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

"""
        referencegrid(df::BiData, effectsdicts; rates = rates)

## Description

Apply `referencegrid` to a BiData object.
"""
function referencegrid(df::BiData, effectsdicts; rates = rates)
    return (; [r => referencegrid(df[r], effectsdicts[r]) for r in rates]...)
end

"""
        referencegrid(df::AbstractDataFrame, effectsdict)

## Description

Construct a reference grid DataFrame from all possible combinations of the
input effects dictionary `effectsdict` values.
"""
function referencegrid(df::AbstractDataFrame, effectsdict)
    
    kys = collect(keys(effectsdict));
    cp = vec(collect(Iterators.product(values(effectsdict)...)));
    df = similar(df, length(cp));
    df = select(df, kys)

    for (i, c) in (enumerate∘eachcol)(df)
        c .= [e[i] for e in cp]
    end

    return df
end

export referencegrid

function apply_referencegrids!(
    m::EModel, referencegrids;
    invlink = identity, multithreaded = true
)
    if multithreaded
        Threads.@threads for r in rates
            effects!(referencegrids[r], m[r]; invlink)
        end
    else
        for r in rates
            effects!(referencegrids[r], m[r]; invlink)
        end
    end
end

export apply_referencegrids!

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
        usualeffects(dats)

Construct the dictionary foundation of the reference grids for most analyses.
"""
function usualeffects(dats)
    
    df_ = dats.fpr;
    
    # separate or the same (across rates)?
    ds = [dats[x][!, :dists_p][dats[x][!, :dists_p] .!= 0] for x in rates];
    distmean = mean(reduce(vcat, ds))    

    tpr_dict = Dict(
        :kin431 => [false, true],
        :dists_p => distmean
    );

    fpr_dict = deepcopy(tpr_dict);
    fpr_dict[:dists_a] = mean(df_[df_[!, :dists_a] .!= 0, :dists_a])
    return (tpr = tpr_dict, fpr = fpr_dict,)
end

export usualeffects

"""
        usualeffects(dats, vbl)

Construct the dictionary foundation of the reference grids for most analyses. Include the range of a focal variable, `vbl`, observed in the data.
"""
function usualeffects(dats, vbl)
    
    df_ = dats.fpr;
    
    # separate or the same (across rates)?
    ds = [dats[x][!, :dists_p][dats[x][!, :dists_p] .!= 0] for x in rates];
    distmean = mean(reduce(vcat, ds))    

    tpr_dict = Dict(
        :kin431 => [false, true],
        :dists_p => distmean
    );

    fpr_dict = deepcopy(tpr_dict);
    fpr_dict[:dists_a] = mean(df_[df_[!, :dists_a] .!= 0, :dists_a])

    effectsdicts = (tpr = tpr_dict, fpr = fpr_dict,)

    # add the range of the focal variable
    for r in rates
        effectsdicts[r][vbl] = (
            unique∘skipmissing∘vcat)(dats[:tpr][!, vbl], dats[:fpr][!, vbl]
        )
    end

    return effectsdicts
end

export usualeffects
