
"""
        updatevalues!(resp, wave, variable)

Update missing values in for  selected wave from the response data with
those from the next most recent wave.
"""
function updatevalues!(resp, wave, variable)
    vrs = [:name, :wave, variable]

    sdf = @views resp[resp.wave .== wave, vrs];
    rdf = @views resp[resp.wave .< wave, :];
    _updatevalues!(sdf, rdf, vrs, wave)
end

function _updatevalues!(sdf, rdf, vrs, wave)
    for nm in unique(sdf.name)
        w4val = sdf[(sdf.name .== nm) .& (sdf.wave .== wave), vrs[3]]
        if !isnothing(w4val) 
            if (length(w4val) > 0) & ismissing(w4val[1])
                y = rdf[rdf.name .== nm, vrs[3]]
                if length(y) > 0 # there may not be a prior entry for nnm

                    # find the most recent entry that is not missing
                    # necessarily isolates a single value
                    fl = findlast(!ismissing(y))
                    sdf[(sdf.name .== nm) .& (sdf.wave .== wave), vrs[3]] .= y[fl]
                end
            end
        end
    end
end

for nm in unique(sdf.name)
        cnt +=1 
        w4val = sdf[(sdf.name .== nm) .& (sdf.wave .== wave), vrs[3]]
        if !isnothing(w4val)
            if (length(w4val) > 0) & ismissing(w4val[1])
                y = rdf[rdf.name .== nm, vrs[3]]
                if length(y) > 0 # there may not be a prior entry for nnm

                  # find the most recent entry that is not missing
                  # necessarily isolates a single value
                  fl = findlast(!ismissing(y))
                  sdf[(sdf.name .== nm) .& (sdf.wave .== wave), vrs[3]] .= y[fl]
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
