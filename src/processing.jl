# processing.jl


"""
        _extractvariables!(vbls, ds)

## Description

Deduce the variable types from unit structs.
"""
function _extractvariables!(vbls, ds)
    vars_ = unique(reduce(vcat, unique([(collect∘keys)(v.properties) for v in values(ds)])));
    for v_ in vars_
        vbls[v_] = Missing
        for (_, v) in ds
            vals = get(v.properties, v_, missing)
            if !ismissing(vals)
                for w in 1:4
                    val = get(vals, w, missing)
                    if !ismissing(val)
                        vbls[v_] = typeof(val)
                        break
                    end
                end
                if vbls[v_] != Missing
                    break
                end
            end
        end
    end
end

"""
        wavenote!(df, w4set, unitids, wave, unit)

## Description

Report the presence of the unit at each wave and extract the unit ids for
current wave.

Extracts for invariant variables.
"""
function wavenote!(df, w4set, unitids, wave, unit)
    df.waves = Vector{NTuple{4, Bool}}(undef, nrow(df))
    for (i, e) in enumerate(w4set)
        for x in unitids
            df[i, x] = if x == unit
                getfield(e, x)
            else
                getfield(e, x)[wave]
            end
        end
        df[i, :waves] = getfield(e, :wave)
    end
    sort!(df, unitids)
end

"""
        populate_datacols!(nf, vs, ds, noupd, hh, unit)

## Description

Add data from `ds` dictionary of `Respondent` objects, imputing with earlier waves as allowed by `noupd` list of variables to not update.

`hh` only needed for variable types.
"""
function populate_datacols!(nf, ds, noupd, unit, wv)
    
    # ignore invariant variables
    vbls_ = setdiff(
        Symbol.(names(nf)),
        [:waves, :wave, :village_code, :name, :building_id, :date_of_birth, :man, :lat, :lon, :elevation, :village_name]
    )

    nf[!, :impute] = [Dict{Symbol, Int}() for _ in 1:nrow(nf)];
    
    for c in vbls_
        _populate_datacol!(nf, c, ds, noupd, unit, wv)
    end
end

function _populate_datacol!(nf, c, ds, noupd, unit, wv)
    # Threads.@threads 
    for i in eachindex(nf[!, c])
        # @show i
        # if variable `c` is not in blacklist, impute
        nf[i, c] = if c ∉ noupd
            vl, w = firstval(
                ds[nf[i, unit]].properties[c];
                waves = keys(ds[nf[i, unit]].properties[c])
            )
            if !ismissing(vl)
                if typeof(vl) != nonmissingtype(eltype(nf[!, c]))
                    vl = passmissing(parse)(nonmissingtype(eltype(nf[!, c])), vl)
                end
            end
            if (w < wv) & (w > 0)
                # track imputation
                nf[i, :impute][c] = w
            end
            vl
        else
            # otherwise, get current wave value
            get(ds[nf[i, unit]].properties[c], wv, missing)
        end
    end
end

"""
        firstval(x; waves = [4,3,2,1])

## Description

Return most recent value, or missing if all are missing.
"""
function firstval(x; waves = [4,3,2,1])
    for i in waves
        if !ismissing(x[i])
            return x[i], i
        end
    end
    return missing, 0
end

function variableassign!(ds, rgnp, vs2, unit; wave = :wave)
    Threads.@threads for ri in eachrow(rgnp)
        for q in setdiff(vs2, [:wave, :village_code, :name, :building_id, :date_of_birth, :man])
            for (w, vl) in zip(ri[wave], ri[q])
                ds[ri[unit]].properties[q][w] = vl
            end
            
            for j in 2:4
                v1 = get(ds[ri[unit]].properties[q], j-1, missing)
                v2 = get(ds[ri[unit]].properties[q], j, missing)
                
                ds[ri[unit]].change[q][j-1] = if ismissing(v1) & ismissing(v2)
                        false
                elseif ismissing(v1) | ismissing(v2) # if only one missing -> change
                        true
                    elseif v1 != v2
                        true
                    elseif v1 == v2
                        false
                end
            end
        end
    end
end

function imputed_var!(nf, fv)
    imp = nf[!, :impute_r]
    v = Symbol(string(fv) * "_imputed_when")
    nf[!, v] = missings(Int, nrow(nf));
    for (i, e) in enumerate(imp)
        nf[i, v] = get(e, fv, missing)
    end
    @show v
    return v
end

export imputed_var!
