
"""
        updatevalues!(resp, wave, variable, when = :allprior)

Update missing values for selected wave from the response data with
those from the next most recent wave.

`when` = `:allprior` or `:justprior`. For the latter, only values from the just previous wave will be used.
"""
function updatevalues!(resp, wave, variable; unit = :name, when = :allprior)
    vrs = [unit, :wave, variable]

    sdf = @views resp[resp.wave .== wave, vrs];
    
    wavecond = if when == :allprior
        resp.wave .< wave
    elseif when == :justprior
        resp.wave .== (wave - 1)
    else
        error("bad specification")
    end
    rdf = @views resp[wavecond, :];
    _updatevalues!(sdf, rdf, vrs, wave, unit)
end

function _updatevalues!(sdf, rdf, vrs, wave, unit)
    for nm in unique(sdf[!, unit])
        w4val = sdf[(sdf[!, unit] .== nm) .& (sdf.wave .== wave), vrs[3]]
        if !isnothing(w4val) 
            if (length(w4val) > 0) & ismissing(w4val[1])
                y = rdf[rdf[!, unit] .== nm, vrs[3]]
                if length(y) > 0 # there may not be a prior entry for nnm

                    # find the most recent entry that is not missing
                    # necessarily isolates a single value
                    fl = findlast(!ismissing(y))
                    sdf[(sdf[!, unit] .== nm) .& (sdf.wave .== wave), vrs[3]] .= y[fl]
                end
            end
        end
    end
end

"""
        updatevalues!(resp, variable)

Update by replacing all with most recent value. Basically, don't use this.
"""
function updatevalues!(resp, variable)
    # assume sorted by wave
    # variable = :educated
    gdf = groupby(resp, :name);

    multiplevals = Vector{String}()

    for g in gdf
        # takes first value  -> not particularly safe
        if nrow(g) > 1
            if length(unique(collect(skipmissing(g[!, variable])))) > 1
                println("multiple values for person ", g.name[1])
                push!(multiplevals, g.name[1])

            end
            if !all(ismissing.(g[!, variable])) & any(ismissing.(g[!, variable]))
                # end: take most recent value
                rpl = collect(skipmissing(g[!, variable]))[end]
                resp[parentindices(g)[1], variable] .= rpl
            end
        end
    end
    return multiplevals
end
