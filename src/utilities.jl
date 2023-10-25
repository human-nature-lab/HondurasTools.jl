# utilities.jl

function tryindex(g::T, a, prop; alt = NaN) where T <: AbstractMetaGraph
    return try
        g[a, prop]
    catch
        alt
    end
end


## general

"""
        unilen(x)

Return the number of unique elements.
"""
function unilen(x)
    return x |> unique |> length
end

"""
        interlen(x, y)

Return the length of the intersecting elements.
"""
function interlen(x, y)
    return intersect(x, y) |> length
end

function misstring(x)
    return if ismissing(x)
        missing
    else
        string(x)
    end
end

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
