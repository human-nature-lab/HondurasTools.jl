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

"""
        sortedges!(alters₁, alters₂)

Sort the (person1, person2) pairs based on respondent id. This ensures that the edges are consistently named, and helps to reduce the possibility of invalid (when symmetric) repeated edges. Only apply wen the edges are symmetric.
"""
function sortedges!(alters₁, alters₂)
    for (i, (e1, e2)) in enumerate(zip(alters₁, alters₂))
        if e1 > e2
            # if e1 is alphanumerically after e2, switch their values
            alters₁[i] = e2
            alters₂[i] = e1
        end
    end
end

"""
        tuplevec(alters1, alters2; sort = true)

Create a vector of tuples from the columns of an edgelist. If asymmetric, sort should be false.
"""
function tuplevec(alters1, alters2; sort = false)
    tups = Vector{Tuple{String, String}}(undef, length(alters1))
    for (i, (e1, e2)) in enumerate(zip(alters1, alters2))
        tups[i] = if sort
            tups[i] = if e1 > e2
                (e2, e1)
            else
                (e1, e2)
            end
        else
            (e1, e2)
        end
    end
    return tups
end
