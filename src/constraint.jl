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

Constraint for (i,j), defined in Burt (1993).
"""
function dyadicconstraint(g, i, j)
    return (investment(g, i, j) + investment_sum(g, i, j))^2
end

"""
        investment(g, i, j)

## Description

The energy i invests into j.

Generalize from `has_edge` to include non-binary ties.
"""
function investment(g, i, j)
    numer = has_edge(g, i, j) + has_edge(g, j, i)
    return numer * inv(_investment_denom(g, i))
end

function _investment_denom(g, i)
    c = 0
    for k in neighbors(g, i)
        c += has_edge(g, i, k) + has_edge(g, k, i)
    end
    return c
end

function investment_sum(g, i, j)
    c = 0
    for q in neighbors(g, i)
        if q != j
            c += investment(g, i, q) * investment(g, q, j)
        end
    end
    return c
end

export constraint
