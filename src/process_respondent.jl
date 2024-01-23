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
    resp, vs;
    unit = :name, ids = ids, respvars = respvars, percvars = percvars
)

    resp.man = passmissing(ifelse).(resp.gender .== "man", true, false);

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
function respwave(rd, noupd; ids = ids, wave = 4)

    unit = ids.n

    rsps = values(rd)
    has4 = [x.wave[wave] for x in rsps]
    w4set = collect(rsps)[has4];

    # extract variables from structs
    vbls = Dict{Symbol, DataType}();
    for (x, v) in [
        :village_code => Int, :building_id => String,
        :wave => Int, :name => String,
        :date_of_birth => Date, :man => Bool
    ]
        vbls[x] = v
    end

    _extractvariables!(vbls, rd)

    vbls[:invillage_yrs] = Float64

    # no type should only be missing
    @assert !any(collect(values(vbls)) .== Missing)

    # r4.man = Vector{Union{Missing, Bool}}(undef, nrow(r4))

    nf = DataFrame([(k => v[]) for (k, v) in vbls]...);
    allowmissing!(nf)
    nf = similar(nf, sum(has4))

    # make all columns missing (some may be left undefined via `similar`)
    for x in names(nf)
        nf[:, x] .= missing
    end

    unitids = [ids.vc, ids.b, ids.n];
    wavenote!(nf, w4set, unitids, wave, unit)

    # invariant non-id variables
    ivars = [:man, :dob]
    nvars = [:man, :date_of_birth]
    for (iv, nv) in zip(ivars, nvars)
        for (i, e) in enumerate(nf[!, unit])
           nf[i, nv] = getfield(rd[e], iv)
        end
    end

    # imputation occurs during r4 DataFrame construction
    populate_datacols!(nf, rd, noupd, unit, wave)

    # nice sorting
    sort!(nf, unitids)

    # overwrite existing age variable based on `dob`

    waveyears = Dict(
        1 => Date("2015-09-15"), 2 => Date("2017-05-15"),
        3 => Date("2019-06-15"), 4 => Date("2023-01-01")
    )

    # use survey wave midpoint for missing survey start dates
    ss = nf.survey_start
    ss[ismissing.(ss)] .= waveyears[wave]

    # fixes
    nf.age = age.(ss, nf[!, :date_of_birth])
    
    if "invillage" ∈ names(nf)
        # adjust invillage values when imputed to be correct for survey lag
        nf.invillage_wave_imputed = [get(x, :invillage, missing) for x in nf.impute];
        nf.invillage = invillage_adjust.(nf.invillage, nf.invillage_wave_imputed)
        nf.invillage = categorical(unwrap.(nf.invillage), ordered = true)
    end

    nf.wave .= wave

    return nf
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
