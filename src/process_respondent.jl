# process_respondent.jl

struct Respondent
    name::String
    dob::Union{Date, Missing}
    man::Union{Bool, Missing}
    properties::Dict{Symbol, Dict{Int, Any}}
    change::Dict{Symbol, Vector{Bool}} # 1->2,1->3, 3->4
    building_id::Dict{Int, Union{String, Missing}}
    village_code::Dict{Int, Union{Int, Missing}}
    wave::NTuple{4, Bool}
end

function respondent(name, date_of_birth, man, waves, vs2)

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

    return Respondent(
        name,
        date_of_birth,
        man,
        prop,
        chg, # 1->2, 1->3, 3->4
        Dict{Int, String}(),
        Dict{Int, Int}(),
        Tuple(wv)
    )
end

export Respondent, respondent


function respprocess(
    resp, vs; unit = :name, ids = ids, respvars = respvars, percvars = percvars
)

    rgnu = @chain resp begin
        sort([unit, :wave])
        groupby(unit)
        combine(
            :date_of_birth => Ref∘unique∘skipmissing => :date_of_birth,
            :man => Ref∘unique∘skipmissing => :man,
            :building_id => Ref => :building_id,
            :village_code => Ref => :village_code,
            :wave => Ref => :wave
        )
        @rtransform(:dob_len = length(:date_of_birth), :man_len = length(:man))
    end

    let
        rgdob = @subset rgnu :dob_len .> 1
        @assert nrow(rgdob) == 0
    end

    # sent to Liza
    # rgman = @subset rgnu :man_len .> 1
    # rgman.name

    @assert !any(rgnu.dob_len .> 1)
    # @assert !any(rgnu.man_len .> 1)

    rgnu.date_of_birth = upck.(rgnu.date_of_birth);
    rgnu.man = upck.(rgnu.man);

    rd = Dict{String, Respondent}();
    sizehint!(rd, nrow(rgnu));
    for (i, e) in enumerate(rgnu.name)
        ri = @views rgnu[i, :]
        rpd = respondent(e, ri.date_of_birth, ri.man, ri.wave, vs)
        for (w, b, c) in zip(ri.wave, ri.building_id, ri.village_code)
            rpd.building_id[w] = b
            rpd.village_code[w] = c
        end
        rd[e] = rpd
    end

    vs2 = setdiff(vs, [:wave, :village_code, :name, :building_id, :date_of_birth, :man])

    rgnp = @chain resp begin
        sort([:name, :wave])
        groupby(:name)
        combine([v => Ref => v for v in setdiff(vs, [unit])]...)
    end

    variableassign!(rd, rgnp, vs2, :name)

    return rd
end

export respprocess

"""

Respondent data for a wave, with imputation except for `noupd` variables.
"""
function respwave(resp, vs, rd, noupd; ids = ids, wave = 4)

    unit = ids.n

    rsps = values(rd)
    has4 = [x.wave[wave] for x in rsps]
    w4set = collect(rsps)[has4];

    rx = select(
        resp,
        intersect(union(ids, respvars, percvars), Symbol.(names(resp))), :date_of_birth
    )

    r4 = @chain rx begin
        similar(0)
        select([ids.n, ids.b, ids.vc, :date_of_birth])
        similar(sum(has4))
        allowmissing()
    end

    r4.man = Vector{Union{Missing, Bool}}(undef, nrow(r4))

    for x in ids
        r4[:, x] .= missing
    end

    r4.waves = Vector{NTuple{4, Bool}}(undef, nrow(r4))
    let df = r4
        for (i, e) in enumerate(w4set)
            for x in ids
                df[i, x] = if x == :name
                    getfield(e, x)
                else
                    getfield(e, x)[wave]
                end
            end
            df[i, :waves] = getfield(e, :wave)
            df[i, :date_of_birth] = getfield(e, :dob)
            df[i, :man] = getfield(e, :man)
        end
        sort!(df, [ids.vc, ids.b, ids.n])
    end

    # imputation occurs during r4 DataFrame construction
    vs2 = setdiff(vs, [:wave, :village_code, :name, :building_id, :date_of_birth, :man])
    populate_datacols!(r4, vs2, rd, noupd, resp, unit, wave)

    # nice sorting
    sort!(r4, [ids.vc, ids.b, ids.n])

    # overwrite existing age variable based on `dob`

    waveyears = Dict(
        1 => Date("2015-09-15"), 2 => Date("2017-05-15"),
        3 => Date("2019-06-15"), 4 => Date("2023-01-01")
    )

    ss = r4.survey_start
    ss[ismissing.(ss)] .= waveyears[wave]

    r4.age = age.(ss, r4[!, :date_of_birth])
    return r4
end

export respwave

"""
        invillage_adjust(x, wi)

Adjust invillage based on imputation.
"""
function invillage_adjust(x, wi)
    return if !ismissing(x)
        if (x == "Less than a year") & !ismissing(wi)
            "More than a year"
        else
            x
        end
    else
        x
    end
end

export invillage_adjust
