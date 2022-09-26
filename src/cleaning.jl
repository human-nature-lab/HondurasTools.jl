# cleaning.jl

function missingize!(r3, variable)
    for (i,e) in enumerate(r3[!, variable])
        if !ismissing(e)
            if (e == "Refused") | (e == "Dont_Know")
                r3[i, variable] = missing
            end
        end
    end
end

function gender_cleaning!(gendvec)
    for (i,e) in enumerate(gendvec)
        if !ismissing(e)
            gendvec[i] = if e == "male"
                "man"
            elseif e == "female"
                "woman"
            end
        end
    end
    return gendvec
end

"""
        replace_withold!(resp3, resp2, resp1, misvar)

Replace missing W3 values with values from previous waves, where available.
Some variables were not recollected at later waves, and were only present in a
later wave if it was not collected earlier (for some reason).
N.B. this should only be applied to variables that are definitely static.

ARGS
====
- resp3: wave 3 data to be updated
- resp2: wave 2 data
- resp1: wave 1 data

"""
function replace_withold!(resp3, resp2, resp1, misvar)
    w3names = resp3[ismissing.(resp3[!, misvar]), :name];
    resp3[ismissing.(resp3[!, misvar]), misvar];

    _replaceold!(resp3, resp2, misvar, w3names)

    _replaceold!(resp3, resp1, misvar, w3names)
end

function _replaceold!(newresp, aresp, misvar, w3names)
    mnme = [:name, misvar]
    ww = aresp[(aresp.name .∈ Ref(w3names)) .& (.!ismissing.(aresp[!, misvar])), mnme];


    for r in eachrow(ww)
        newresp[(newresp.name .== r[:name]), misvar] = [r[misvar]]
    end
end

