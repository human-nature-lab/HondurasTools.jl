# effects_utilities.jl

function bimargins(ms, vbls, crt, crf; invlink = logistic)

    # create design
    udict = Dict{Symbol, Vector{Any}}();
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

    dsn = Dict(udict...)
    tpr = ms.tpr; # getfield(ms, :tpr);
    fpr = ms.fpr; # getfield(ms, :fpr);
    eff_tpr = effects(dsn, tpr, invlink = invlink);
    eff_tpr.truth .= true;
    eff_fpr = effects(dsn, fpr, invlink = invlink);
    eff_fpr.truth .= false;

    return vcat(eff_tpr, eff_fpr);
end

export bimargins
