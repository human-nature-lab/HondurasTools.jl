# groupdescribe.jl

function procinnerstring(vals)
    instr = string.(vals);
    instr[1:(end-1)] = instr[1:(end-1)] .* "; ";
    return reduce(*, instr)
end

"""
        groupdescribe(df, grpvars)

Separately describe each group (by `grpvars`) of `df`, and concatenate.
"""
function groupdescribe(df, grpvars; maxlevels = 20)

    desc = DataFrame();
    gs = groupby(df, grpvars)
    
    for (k, g) in pairs(gs)
        ng = g |> DataFrame |> describe
        ng.wave .= k.wave
        ng.pct_missing = round.(100 * ng.nmissing ./ nrow(g); digits = 2)
        ng.eltype = nonmissingtype.(ng.eltype)
        ng.values = fill("", nrow(ng))
        ng.values .= ""
        for (c, v) in enumerate(ng.variable)
            su = sunique(g[!, v])
            c1 = (length(su) > maxlevels) | (
                nonmissingtype(eltype(su)) <: AbstractFloat) |
                (nonmissingtype(eltype(su)) <: Signed
            )
            if !c1
                ng.values[c] = procinnerstring(su)
            end
        end
        append!(desc, ng)
    end

    return desc
end

export groupdescribe
