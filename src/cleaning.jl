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
    for (i, e) in enumerate(gendvec)
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
