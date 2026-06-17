# processing.jl


"""
        _extractvariables!(vbls, ds)

## Description

Deduce the variable types from unit structs.
"""
function _extractvariables!(vbls, ds)
    vars_ = let ks = Set{Symbol}()
        for v in values(ds); union!(ks, keys(v.properties)); end
        collect(ks)
    end
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

    unit_ids = nf[!, unit]   # pre-extract to avoid repeated DataFrame row indexing

    for c in vbls_
        _populate_datacol!(nf, c, ds, noupd, unit_ids, wv)
    end
end

function _populate_datacol!(nf, c, ds, noupd, unit_ids, wv)
    col_type  = nonmissingtype(eltype(nf[!, c]))
    impute_by_wave = c ∉ noupd
    for i in eachindex(nf[!, c])
        entity = ds[unit_ids[i]]
        prop   = entity.properties[c]
        nf[i, c] = if impute_by_wave
            # use most-recent wave value (default waves=[4,3,2,1] gives correct ordering;
            # passing keys(prop) was wrong — Dict keys are unordered)
            vl, w = firstval(prop)
            if !ismissing(vl) && typeof(vl) != col_type
                vl = passmissing(parse)(col_type, vl)
            end
            if (w < wv) & (w > 0)
                nf[i, :impute][c] = w
            end
            vl
        else
            get(prop, wv, missing)
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
        val = get(x, i, missing)
        if !ismissing(val)
            return val, i
        end
    end
    return missing, 0
end

function variableassign!(ds, rgnp, vs2, unit; wave = :wave)
    vs3 = setdiff(vs2, [:wave, :village_code, :name, :building_id, :date_of_birth, :man])
    Threads.@threads for ri in eachrow(rgnp)
        for q in vs3
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
