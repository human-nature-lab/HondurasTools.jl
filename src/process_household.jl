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
        hhwave(hd, noupd; ids = ids, wave = 4)

Household data for a wave, with imputation except for `noupd` variables.
"""
function hhwave(hd, noupd; ids = ids, wave = 4)

    hhids = [ids.vc, ids.b]
    unit = ids.b

    rsps = values(hd)
    has4 = [x.wave[wave] for x in rsps]
    w4set = collect(rsps)[has4];

    # extract variables from structs
    vbls = Dict{Symbol, DataType}();

    # specific to Household
    for (x, v) in [:wave => Int, :village_code => Int, :building_id => String]
        vbls[x] = v
    end

    _extractvariables!(vbls, hd)

    # these were not correct
    vbls[:girls_under12] = Int
    vbls[:boys_under12] = Int

    # no type should only be missing
    @assert !any(collect(values(vbls)) .== Missing)

    nf = DataFrame([(k => v[]) for (k, v) in vbls]...);
    allowmissing!(nf)
    # select!(nf, hhids)
    nf = similar(nf, sum(has4))

    ##

    # make all columns missing (some may be left undefined via `similar`)
    for x in names(nf)
        nf[:, x] .= missing
    end

    unitids = hhids
    wavenote!(nf, w4set, unitids, wave, unit)

    # imputation occurs during r4 DataFrame construction
    populate_datacols!(nf, hd, noupd, unit, wave)

    # nice sorting
    sort!(nf, [ids.vc, ids.b])

    nf.wave .= wave

    return nf
end

export hhwave
