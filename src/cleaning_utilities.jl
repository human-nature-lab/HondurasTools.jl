# cleaning_utilities.jl

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
