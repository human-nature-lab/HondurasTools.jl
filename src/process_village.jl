# process_village.jl

struct Village
    village_code::Int
    village_name::String
    latlon::Tuple{Union{Missing, Float64}, Union{Missing, Float64}}
    elevation::Union{Missing, Float64}
    properties::Dict{Symbol, Dict{Int, Any}}
    change::Dict{Symbol, Vector{Bool}} # 1->2,1->3, 3->4
    wave::NTuple{4, Bool}
end

export Village

function village(village_code, village_name, latlon, elevation, waves, vs)
    wv = fill(false, 4)
    for i in eachindex(wv)
        if i ∈ waves
            wv[i] = true
        end
    end

    vs2 = setdiff(vs, [:village_code, :village_name, :aldea_latitude, :aldea_longitude, elevation])

    t1 = Dict{Int, Any}
    t2 = Vector{Bool}

    prop = Dict{Symbol, t1}()
    chg = Dict{Symbol, t2}()

    for q in vs2
        prop[q] = t1()
        chg[q] = fill(false, 3)
    end

    return Village(
        village_code,
        village_name,
        latlon,
        elevation,
        prop,
        chg, # 1->2, 1->3, 3->4
        Tuple(wv)
    ) 
end

export village

function villageprocess(vill, vs; unit = ids.vc)

    exts = [:village_name, :aldea_latitude, :aldea_longitude, :elevation];

    rgnu = @chain vill begin
        sort([unit, :wave])
        groupby(unit)
        combine(
            :wave => Ref => :wave,
            [e => Ref∘unique => e for e in exts]...
        )
        transform(
            [e => ByRow(length) => Symbol(string(e) * "_cnt") for e in exts]...,
            [e => ByRow(collect∘skipmissing) => e for e in exts],
        )
        transform([e => ByRow(upck) => e for e in exts])
    end

    # check -> we see that some do differ... but are missing in the second case
    # hcat([unique(rgnu[!, Symbol(string(e) * "_cnt")]) for e in exts], exts)

    @assert nrow(unique(rgnu[!, [unit, :wave]])) == nrow(rgnu)

    vd = Dict{Int, Village}();
    sizehint!(vd, nrow(rgnu));

    for (i, e) in enumerate(rgnu[!, unit])
        ri = @views rgnu[i, :]
        latlon = (ri.aldea_latitude, ri.aldea_longitude)
        rpd = village(e, ri.village_name, latlon, ri.elevation, ri.wave, vs)
        vd[e] = rpd
    end

    vs2 = setdiff(vs, [:wave, :village_code, :village_name, :aldea_latitude, :aldea_longitude, :elevation])

    rgnp = @chain vill begin
        sort([unit, :wave])
        groupby(unit)
        combine([v => Ref => v for v in setdiff(vs, [unit])]...)
    end

    HondurasTools.variableassign!(vd, rgnp, vs2, unit)

    return vd
end

export villageprocess

"""

Village data for a wave, with imputation except for `noupd` variables.
"""
function villwave(vill, vs, vd, noupd; ids = ids, wave = 3)

    unit = ids.vc

    rsps = values(vd)
    has4 = [x.wave[wave] for x in rsps]
    w4set = collect(rsps)[has4];

    rx = select(
        vill,
        intersect(union([ids.vc, vs...]), Symbol.(names(vill)))
    )

    v4 = @chain rx begin
        similar(0)
        select([ids.vc, :village_name])
        similar(sum(has4))
        allowmissing()
    end

    for x in [:village_code, :village_name]
        v4[:, x] .= missing
    end

    for x in [:elevation, :lat, :lon]
        v4[!, x] = fill(NaN, nrow(v4))
    end

    v4.waves = Vector{NTuple{4, Bool}}(undef, nrow(v4))
    let df = v4
        for (i, e) in enumerate(w4set)
            df[i, unit] = getfield(e, unit)
            df[i, :village_name] = getfield(e, :village_name)
            df[i, :elevation] = getfield(e, :elevation)
            lat, lon = getfield(e, :latlon)
            df[i, :lat] = lat
            df[i, :lon] = lon
            df[i, :waves] = getfield(e, :wave)
        end
        sort!(df, unit)
    end

    # imputation occurs during v4 DataFrame construction
    vs2 = setdiff(
        vs, [:wave, :village_code, :village_name, :elevation, :lat, :lon, :aldea_latitude, :aldea_longitude]
    )
    populate_datacols!(v4, vs2, vd, noupd, vill, unit)

    # nice sorting
    sort!(v4, ids.vc)

    return v4
end

export villwave
