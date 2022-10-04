# utilities.jl

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
