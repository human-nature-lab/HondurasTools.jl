# utilities.jl

import Base.names
function names(g::T; name = :name) where T <: AbstractMetaGraph
    return [get_prop(g, i, name) for i in 1:nv(g)]
end

"""
        sa(a)

Skip missing and NaN.
via Skipper.jl
"""
sa(a) = skip(x -> ismissing(x) || isnan(x), a) 

sunique(x) = (sort∘unique)(x)

"""
        nicedisplay(
            v::Vector; crop = :none, rows = nothing,
            colnum = 7
        )

Display a vector in a multicolumn format.
"""

function nicedisplay(
    v::Vector; crop = :none, rows = nothing,
    colnum = 6
)
    # reasonable width for default
    ln = length(v);
    rows = if isnothing(rows)
        (Int∘ceil)(ln/colnum)
    else
        rows
    end

    cls = (Int∘ceil)(ln/rows)
    shw = similar(v, rows, cls);
    shw[1:ln] .= v

    return pretty_table(
        shw;
        max_num_of_rows = rows, compact_printing = true,
        limit_printing = false, show_header = false,
        show_row_number = true, vlines = :all,
        renderer = :print,
        crop = crop
    )
end

function nicedisplay(df::DataFrame; crop = :none, rows = nothing, colnum = 6)
    return nicedisplay(names(df), crop = crop, rows = rows, colnum = colnum)
end

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

function irrelreplace!(cr, v)
    replace!(cr[!, v], [x => missing for x in HondurasTools.rms]...);
end

function binarize!(cr, v)
    if (eltype(cr[!, v]) == Union{Missing, Bool}) | (eltype(cr[!, v]) == Bool)
        println("already converted")
    else
        irrelreplace!(cr, v)
        cr[!, v] = passmissing(ifelse).(cr[!, v] .== "Yes", true, false);
    end
end

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
