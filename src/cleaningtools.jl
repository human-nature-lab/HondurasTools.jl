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
        irrelreplace!(cr, v)

values equal to any of
["Don't know", "Don't Know", "Dont_Know", "Refused", "Removed"]
become missing.
"""
function irrelreplace!(cr, v)
    replace!(cr[!, v], [x => missing for x in HondurasTools.rms]...);
end

export irrelreplace!

"""
        binarize!(cr, v)

Values == `yes` -> `true`; other values -> `false`.
Missing values are retained as `missing`.
"""
function binarize!(cr, v; yes = "Yes")
    if (eltype(cr[!, v]) == Union{Missing, Bool}) | (eltype(cr[!, v]) == Bool)
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
        if sort(collect(skipmissing(unique(vector)))) == [1, 2]
            passmissing(Bool).(vector .- 1)
        elseif sort(collect(skipmissing(unique(vector)))) == [0, 1]
            passmissing(Bool).(vector)
        end
    else error("check type")
    end
end

rms = ["Don't know", "Don't Know", "Dont_Know", "Refused", "Removed"];
freqscale = ["Never", "Rarely", "Sometimes", "Always"];
goodness = ["Bad", "Neither", "Good"];
