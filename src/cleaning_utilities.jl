# cleaning_utilities.jl

function regularizecols!(resp)

    dr1 = describe(resp[1])[!, [:variable, :eltype]]

    if length(resp) > 1
        dr2 = describe(resp[2])[!, [:variable, :eltype]]
    end
    
    if length(resp) > 2
        dr3 = describe(resp[3])[!, [:variable, :eltype]]
    end

    if length(resp) > 3
        dr4 = describe(resp[4])[!, [:variable, :eltype]]
    end

    drs = if length(resp) > 3
        unique(vcat(dr1, dr2, dr3, dr4))
    elseif length(resp) > 2
        unique(vcat(dr1, dr2, dr3))
    elseif length(resp) > 1
        unique(vcat(dr1, dr2))
    else
        unique(vcat(dr1, dr2))
    end

    drs = combine(groupby(drs, :variable), :eltype => Ref∘unique => :eltypes);

    drs[!, :type] = Vector{Type}(undef, nrow(drs))
    addtypes!(drs)
    vardict = Dict(drs.variable .=> drs.type);

    for rp in resp
        misvars = setdiff(drs.variable, Symbol.(names(rp)))
        for misvar in misvars
            rp[!, misvar] = Vector{vardict[misvar]}(missing, nrow(rp))
        end
    end
end

function strip_wave!(resp, wnme, wavestring)
    for e in wnme
        rename!(resp, Symbol(e) => Symbol(split(e, wavestring)[1]))
    end
end

function addtypes!(drs)
    for (i, e) in enumerate(drs.eltypes)
        if length(e) > 1
            for ε in e
                tp = if Missing .∈ Ref(Base.uniontypes(ε))
                    drs.type[i] = ε
                    break
                end
                drs.type[i] = Union{e[1], Missing}
            end
        elseif length(e) == 1
            drs.type[i] = Union{e[1], Missing}
        end
    end
end

function convertspend(x)
    return if !ismissing(x)
        if (x == "Dont_Know") | (x == "Refused") | (isnothing(x))
            missing
        else
            parse(Int, x)
        end
    else
        missing
    end
end
