# effects_utilities.jl

function bimargins(
    ms, vbls, crt, crf;
    tnr = true, invlink = logistic,
    manual_typicals = [:age],
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
