# tiestrength.jl

# there is a common neighbors function in Graphs.jl
# probably use that

"""
        tiestrength(g, i, j)

Bidirectional measure
"""
function tiestrength(g, i, j)
    ni = neighbors(g, i)
    nj = neighbors(g, j)
    mij = (length∘intersection)(ni, nj)
    mij * inv(length(ni)+length(nj)-mij-2)
end

function tiestrength(g, e::AbstractEdge)
    ni = neighbors(g, src(e))
    nj = neighbors(g, dst(e))
    mij = (length∘intersection)(ni, nj)
    mij * inv(length(ni)+length(nj)-mij-2)
end

export tiestrength
