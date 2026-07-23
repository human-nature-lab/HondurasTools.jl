# cleaningtools.jl

function strclean!(v, nv, rf, rf_desc, namedict)
    if v ∈ rf_desc.variable
        namedict[nv] = v;
        rename!(rf, v => nv);
        irrelreplace!(rf, nv);
    end
end

export strclean!

function bstrclean!(v, nv, rf, rf_desc, namedict)
    if v ∈ rf_desc.variable
        namedict[nv] = v;
        rename!(rf, v => nv);
        irrelreplace!(rf, nv);
        binarize!(rf, nv);
    end
end

export bstrclean!

function numclean!(v, nv, rf, rf_desc, namedict; tpe = Int)
    if v ∈ rf_desc.variable
        namedict[nv] = v;
        rename!(rf, v => nv);
        irrelreplace!(rf, nv);
        # fpass step in case parser has mixed and/or weird typing
        fpass = passmissing(string).(rf[!, nv])
        rf[!, nv] = passmissing(parse).(tpe, fpass);
    end;
end

export numclean!

"""
        irrelreplace!(cr, v; extra = String[])

values equal to any of
["Don't know", "Don't Know", "Dont_Know", "Refused", "Removed"]
become missing. Pass `extra` for dataset-specific additions (e.g., `["NA"]`).
"""
function irrelreplace!(cr, v; extra = String[])
    replace!(cr[!, v], [x => missing for x in vcat(HondurasTools.rms, extra)]...);
end

export irrelreplace!

"""
        binarize!(cr, v)

Values == `yes` -> `true`; other values -> `false`.
Missing values are retained as `missing`.
"""
function binarize!(cr, v; yes = "Yes")
    if (eltype(cr[!, v]) == Union{Missing, Bool}) || (eltype(cr[!, v]) == Bool)
        println(string(v) * " already converted")
    else
        irrelreplace!(cr, v)
        cr[!, v] = passmissing(ifelse).(cr[!, v] .== yes, true, false);
    end
end

export binarize!

replmis(x) = ismissing(x) ? false : true

boolstring(x) = return if x == "Yes"
    true
elseif x == "No"
    false
else error("not Yes/No")
end

function boolvec(vector)
    return if nonmissingtype(eltype(vector)) <: AbstractString
        passmissing(boolstring).(vector)
    elseif nonmissingtype(eltype(vector)) <: Signed
        vals = sort(collect(skipmissing(unique(vector))))
        if vals == [1, 2] || vals == [1] || vals == [2]
            passmissing(Bool).(vector .- 1)
        elseif vals == [0, 1] || vals == [0] || vals == Int[]
            passmissing(Bool).(vector)
        else
            error("unexpected integer values: $vals (expected [0,1] or [1,2])")
        end
    else error("check type")
    end
end

export boolvec

"""
    recode_outcome(vector; na = "NA", dk = 0, refused = 999)

Recode a raw survey outcome vector to `Union{Missing, Bool}`.

Handles both string columns (with `"NA"` values that force CSV.jl to parse as
strings) and integer columns. The codebook convention is:
- `na` string → `missing` (not applicable / not surveyed)
- `dk` (default 0) → `missing` (don't know)
- `refused` (default 999) → `missing` (refused)
- 1 → `false` (negative outcome)
- 2 → `true` (positive outcome)

Uses `boolvec` for the final [1,2] → Bool conversion.
"""
function recode_outcome(vector; na = "NA", dk = 0, refused = 999)
    # String columns: parse to Int, replacing na with missing
    v = if nonmissingtype(eltype(vector)) <: AbstractString
        [ismissing(x) || x == na ? missing : parse(Int, x) for x in vector]
    else
        collect(vector)
    end
    # Remove don't know / refused codes
    v = [ismissing(x) ? missing : (x == dk || x == refused) ? missing : x for x in v]
    return boolvec(v)
end

export recode_outcome

rms = ["Don't know", "Don't Know", "Dont_Know", "Refused", "Removed"];
freqscale = ["Never", "Rarely", "Sometimes", "Always"];
goodness = ["Bad", "Neither", "Good"];
