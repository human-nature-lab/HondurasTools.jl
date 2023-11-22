# process_hh.jl

struct Household
    building_id::String
    properties::Dict{Symbol, Dict{Int, Any}}
    change::Dict{Symbol, Vector{Bool}} # 1->2,1->3, 3->4
    village_code::Dict{Int, Union{Int, Missing}}
    members::Dict{Int, Vector{String}}
    wave::NTuple{4, Bool}
end

function household(building_id, waves, vs2)
    wv = fill(false, 4)
    for i in eachindex(wv)
        if i ∈ waves
            wv[i] = true
        end
    end

    t1 = Dict{Int, Any}
    t2 = Vector{Bool}

    prop = Dict{Symbol, t1}()
    chg = Dict{Symbol, t2}()

    for q in setdiff(vs2, [:wave, :village_code, :name, :building_id, :date_of_birth, :man])
        prop[q] = t1()
        chg[q] = fill(false, 3)
    end

    return Household(
        building_id,
        prop,
        chg, # 1->2, 1->3, 3->4
        Dict{Int, Int}(),
        Dict{Int, Vector{String}}(),
        Tuple(wv),
    ) 
end

export Household, household

function householdprocess(
    hh, vs;
    unit = :building_id, ids = ids
)

    rgnu = @chain hh begin
        sort([unit, :wave])
        groupby(unit)
        combine(
            :village_code => Ref => :village_code,
            :wave => Ref => :wave
        )
    end

    @assert nrow(unique(rgnu[!, [unit, :wave]])) == nrow(rgnu)

    hd = Dict{String, Household}();
    sizehint!(hd, nrow(rgnu));
    for (i, e) in enumerate(rgnu[!, unit])
        ri = @views rgnu[i, :]
        rpd = household(e, ri.wave, vs)
        for (w, c) in zip(ri.wave, ri.village_code)
            rpd.village_code[w] = c
        end
        hd[e] = rpd
    end

    vs2 = setdiff(vs, [:wave, :village_code, :village_name, :name, :building_id, :date_of_birth, :man])

    rgnp = @chain hh begin
        sort([unit, :wave])
        groupby(unit)
        combine([v => Ref => v for v in setdiff(vs, [unit])]...)
    end

    variableassign!(hd, rgnp, vs2, unit)

    return hd
end

export householdprocess

"""

Household data for a wave, with imputation except for `noupd` variables.
"""
function hhwave(hh, vs, hd, noupd; ids = ids, wave = 4)

    hhids = [ids.vc, ids.b]
    unit = ids.b

    rsps = values(hd)
    has4 = [x.wave[wave] for x in rsps]
    w4set = collect(rsps)[has4];

    rx = select(
        hh,
        intersect(union([ids.vc, ids.b, vs...]), Symbol.(names(hh)))
    )

    r4 = @chain rx begin
        similar(0)
        select(hhids)
        similar(sum(has4))
        allowmissing()
    end

    for x in hhids
        r4[:, x] .= missing
    end

    r4.waves = Vector{NTuple{4, Bool}}(undef, nrow(r4))
    let df = r4
        for (i, e) in enumerate(w4set)
            for x in hhids
                df[i, x] = if x == unit
                    getfield(e, x)
                else
                    getfield(e, x)[wave]
                end
            end
            df[i, :waves] = getfield(e, :wave)
        end
        sort!(df, hhids)
    end

    # imputation occurs during r4 DataFrame construction
    vs2 = setdiff(vs, [:wave, :village_code, :name, :building_id, :date_of_birth, :man])
    populate_datacols!(r4, vs2, hd, noupd, hh, unit)

    # nice sorting
    sort!(r4, [ids.vc, ids.b])

    return r4
end

export hhwave