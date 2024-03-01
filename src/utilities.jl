# utilities.jl

plusminus(x::Number,y::Number) = (x-y,x+y)

export plusminus

±(x, y) = plusminus(x, y)

export ±

"""
        tuple_addinv(c)

## Description

Replace tuple (v, v) with tuple (1-v, 1-v).
"""
function tuple_addinv(tpl)
    return (1 - tpl[1], 1 - tpl[2])
end

export tuple_addinv

"""
        sunique(x)

Return sorted unique object.
"""
sunique(x) = (sort∘unique)(x)
export sunique

"""
        unilen(x)

Return the number of unique elements.
"""
function unilen(x)
    return x |> unique |> length
end

export unilen

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

export interlen

"""
upck(x)

Return the last element of a vector or give missing if length < 1.
"""
function upck(x)
    return if length(x) > 0
        x[end]
    else
        missing
    end
end

export upck

import Base.names

function names(g::T; name = :name) where T <: AbstractMetaGraph
    return [get_prop(g, i, name) for i in 1:nv(g)]
end

export names

"""
        prp(x; a=3, b=2)

## Description

sum(x .== a)/(sum(x .== b) + sum(x .== a))
"""
function prp(x; a=3, b=2)
    return sum(x .== a)/(sum(x .== b) + sum(x .== a))
end

export prp

"""
        stround(x; digits = 2)

## Description

Return `String` rounded to `d` digits for numeric/integer.
"""
function stround(x; digits = 2)
    return (string∘round)(x; digits)
end

export stround

"""
        sa(a)

Skip `missing` and `NaN`. via Skipper.jl.
"""
sa(a) = skip(x -> ismissing(x) || isnan(x), a) 

export sa

"""
        sai(a)

Skip `Inf` and `NaN`. via Skipper.jl.
"""
sai(a) = skip(x -> isinf(x) || isnan(x), a)

export sai

struct OneHot{T}
    m::T
    assign::Vector{Any}
end

function onehot(x; tp = :float)
    a = unique(x)
    b, t = if tp == :float
        permutedims(a .== permutedims(x)) .* 1.0, Matrix{Float64}
    else
        permutedims(a .== permutedims(x)) .* 1.0, BitMatrix
    end
    return OneHot{t}(b, a)
end

export onehot, OneHot

"""
        tryindex(g::T, a, prop; alt = NaN)

## Description

Try to return index from property for `MetaGraph`, return `NaN` otherwise.
"""
function tryindex(g::T, a, prop; alt = NaN) where T <: AbstractMetaGraph
    return try
        g[a, prop]
    catch
        alt
    end
end

export tryindex, sa, irrelreplace!, binarize!
