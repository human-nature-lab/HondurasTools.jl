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
function villwave(vd, noupd; ids = ids, wave = 3)

    unit = ids.vc
    unitids = [ids.vc]

    rsps = values(vd)
    has4 = [x.wave[wave] for x in rsps]
    w4set = collect(rsps)[has4];

    # extract variables from structs
    vbls = Dict{Symbol, DataType}();

    _extractvariables!(vbls, vd)

    # specific to Village
    for (x, v) in [
        :wave => Int,
        :village_code => Int, :village_name => String,
        :lat => Float64,
        :lon => Float64,
        :elevation => Float64
    ]
        vbls[x] = v
    end

    vbls[:price_charcoal] = Int

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

    wavenote!(nf, w4set, unitids, wave, unit)

    # imputation occurs during v4 DataFrame construction
    populate_datacols!(nf, vd, noupd, unit, wave)

    # invariant variables
    let df = nf
        for (i, e) in enumerate(nf[!, unit])
            vil = vd[e]
            df[i, :village_name] = getfield(vil, :village_name)
            df[i, :elevation] = getfield(vil, :elevation)
            lat, lon = getfield(vil, :latlon)
            df[i, :lat] = lat
            df[i, :lon] = lon
        end
        sort!(df, unit)
    end

    # nice sorting
    sort!(nf, ids.vc)

    nf.wave .= wave

    return nf
end

export villwave
