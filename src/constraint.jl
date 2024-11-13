# constraint.jl

doc"""
        constraint(g, i)

## Description

Network constraint as defined in Burt (1993).

Currently defined only for unweighted (binary) graphs.

"""
function constraint(g, i)
    c = 0
    for j in neighbors(g, i)
        c += dyadicconstraint(g, i, j)
    end
    return c
end

"""
        dyadicconstraint(g, i, j)

## Description

"""
function dyadicconstraint(g, i, j)
    (pij(g, i, j) + psum(g, i, j))^2
end

"""
energy i invests into j.
"""
function pij(g, i, j)
    return (has_edge(g, i, j) + has_edge(g, j, i)) * inv(_pij_denom(g, i))
end

function _pij_denom(g, i)
    c = 0
    for k in neighbors(g, i)
        c += has_edge(g, i, k) + has_edge(g, k, i)
    end
    return c
end

function psum(g, i, j)
    c = 0
    for q in neighbors(g, i)
        if q != j
            c += pij(g, i, q) * pij(g, q, j)
        end
    end
    return c
end

export constraint
