# sortedges!.jl

"""
        sortedges!(alters₁, alters₂)

Sort the (person1, person2) pairs based on respondent id. This ensures that the edges are consistently named, and helps to reduce the possibility of invalid (when symmetric) repeated edges. Only apply wen the edges are symmetric.
"""
function sortedges!(alters₁, alters₂)
    for (i, (e1, e2)) in enumerate(zip(alters₁, alters₂))
        if !ismissing(e1) & !ismissing(e2)
            if e1 > e2
                # if e1 is alphanumerically after e2, switch their values
                alters₁[i] = e2
                alters₂[i] = e1
            end
        end
    end
end
