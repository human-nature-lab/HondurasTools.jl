# neighbors.jl

function getneighbors(prc, vl, rel, nds; ids = ids, relname = :relation)

    ix = findfirst((vl .== nds[!, ids.vc]) .& (rel .== nds[!, relname]))
    
    return if !isnothing(ix)
        g = nds[ix, :graph]
        vprc = tryindex(g, prc, :name; alt = missing)
        if !ismissing(vprc)
            [get_prop(g, va, :name) for va in neighbors(g, vprc)]
        else missing
        end
    else missing
    end
end

export getneighbors

"""

    addneighbors(cr, ndf4, rhv4, sl)

`sl` variables to select in rhv4.
"""
function addneighbors(cr, ndf4, rhv4, sl; cg = cg)
    
    ucr = unique(cr[!, [ids.vc, cg.p, cg.r]]);
    ucr[!, :neighbors] = missings(Vector{String}, nrow(ucr));

    @eachrow! ucr begin 
        :neighbors = getneighbors(
            :perceiver, :village_code, :relation, ndf4;
            ids = ids, relname = cg.r
        )
    end;

    println("missing: " * string(sum(ismissing.(ucr.neighbors))))

    ucrl = flatten(ucr, [:neighbors], scalar = Missing)
    replace!(ucrl.neighbors, "No_One" => missing) # not sure what happened here: this means that that "No_One" shows up as a node in the networks...
    
    r4sel = rhv4[!, [ids.n, ids.vc, sl...]];

    y = Symbol[]
    for x in sl
        nv = Symbol(string(x) * "_n")
        rename!(r4sel, x => nv)
        push!(y, nv)
    end
    
    y = vcat([:neighbors], y)
    
    # join on NEIGHBORS
    leftjoin!(
        ucrl, r4sel, on = [:neighbors => :name, ids.vc],
        matchmissing = :notequal
    )

    ucrw = @chain ucrl begin
        groupby([ids.vc, cg.p, cg.r])
        combine([x => Ref => x for x in y]...)
    end

    @assert nrow(ucrw) == nrow(ucr)
    @rtransform!(ucrw, :neighbornum = passmissing(length)(:neighbors))

    # enforce consistent type
    for v in sl
        tp = eltype(rhv4[!, v])
        nv = Symbol(string(x) * "_n")
        ucrw[!, nv] = convert(
            Vector{Union{Missing, Vector{tp}}},
            ucrw[!, nv]
        )
    end

    sort!(ucrw, [:village_code, :relation, :perceiver])
    
    return ucrw
end

export addneighbors

"""

    addneighbors!(df, nds, r, sl)

## Description

For an input DataFrame, `df`, find the set of matching neighbors stored in `nds` for specified relationship, given by `relname`.

Neighbor properties, specified in `sl`, are added from DataFrame `r`.
"""
function addneighbors!(
    df, nds, r, sl;
    unitname = :name, relname = :relation, ids = ids
)

    df_a = select(df, [ids.vc, unitname, :relation])
    df = select!(df, [ids.vc, unitname, :relation])

    df_a[!, :neighbors] = missings(Vector{String}, nrow(df));

    @eachrow! df_a begin 
        :neighbors = getneighbors(
            :name, :village_code, :relation, nds;
            ids = ids,
            relname
        )
    end;

    # remove invalid "No_One" entries
    for (i, e) in enumerate(df_a.neighbors)
        df_a.neighbors[i] = passmissing(setdiff)(e, ["No_One"])
    end
    
    # neighbor lists of length 0 => missing
    # not sure what happened here: this means that that "No_One" shows up as a node in the networks...
    df_a.neighbors[coalesce.(passmissing(length).(df_a.neighbors), 0) .== 0] .= missing

    x = @subset df_a ismissing.(:neighbors)

    q2 = @subset nds :relation .== "free_time"
    q = DataFrame(
        :pop => [length(y) for y in q2.names],
        :gpop => [nv(y) for y in q2.graph],
        :village_code => q2.village_code
    )
    leftjoin!(q, q2, on = :village_code)

    @chain x begin
        groupby(:village_code)
        combine(nrow => :count)
        leftjoin(_, q, on = :village_code)
        @transform(:frac_isol = :count ./ :pop)
        select(:village_code, :count, :pop, :frac_isol)
    end

    [degree(g) for g in nds.graph]

    println("missing: " * string(sum(ismissing.(df_a.neighbors))))

    # drop missing entries, we don't want to match these anyway...
    dropmissing!(df_a, :neighbors);

    df_ = flatten(df_a, [:neighbors], scalar = Missing)
    
    # select relevant characteristics in the respondent (and up) level data
    r_ = r[!, [ids.n, ids.vc, sl...]];
    
    y = Symbol[]
    for x in sl
        nv = Symbol(string(x) * "_n")
        rename!(r_, x => nv)
        push!(y, nv)
    end
    
    y = vcat([:neighbors], y)
    
    # join on NEIGHBORS
    leftjoin!(
        df_, r_, on = [:neighbors => :name, ids.vc],
        matchmissing = :notequal
    )

    out = @chain df_ begin
        groupby([ids.vc, unitname, relname])
        combine([x => Ref => x for x in y]...)
    end
    
    @assert nrow(out) == nrow(df_a)
    @rtransform!(out, :neighbornum = passmissing(length)(:neighbors))

    leftjoin!(df, out; on = [ids.vc, unitname, :relation])

    # enforce consistent type
    for v in sl
        tp = eltype(r[!, v])
        nv = Symbol(string(v) * "_n")
        df[!, nv] = convert(
            Vector{Union{Missing, Vector{tp}}},
            df[!, nv]
        )
        # make cases with all missing (where there are neighbors) simply
        # missing the count is stored in `neighbornum`
        df[[all(ismissing.(x)) for x in df[!, nv]], nv] .= missing
    end

    sort!(df, [ids.vc, relname, unitname])
    return df
end

export addneighbors!

function process_nvariable(e::Union{Missing, Vector{Union{Missing, T}}}, stat) where T <: Real
    return if ismissing(e)
        1, missing
    else
        if typeof(e) <: AbstractFloat
            0, e
        else
            sum(ismissing.(e)), (stat∘skipmissing)(e)
        end
    end
end

function process_nvariable(x::T, stat) where T <: AbstractVector
    l = length(x)
    vcnt = missings(Int, l);
    vbar = missings(Float64, l);

    for (i, e) in enumerate(x)
        vcnt[i], vbar[i] = process_nvariable(e, stat)
    end
    return vcnt, vbar
end

"""
        process_nvariable!(
            df::DataFrame, v::Union{Symbol, String}, stat::Function
        )

## Description

Calculate number missing and a scalar statistic (e.g., the mean) over each entry of Vector{Union{Missing, Real}}
"""
function process_nvariable!(
    df::DataFrame, v::Union{Symbol, String}, stat::Function
)
    v1 = string(v) * "_c" |> Symbol
    v2 = string(v) * "_" * string(stat) |> Symbol
    df[!, v1], df[!, v2] = process_nvariable(df[!, v], stat)
end

export process_nvariable, process_nvariable!

"""
        neighborprops(g::AbstractGraph, v::Int; property = :name)

## Description

Get the specified property for each neighbor of `v`, where `v` is the vertex index in the graph object.
"""
function neighborprops(g::AbstractGraph, v::Int; property = :name)
    return [get_prop(g, a, property) for a in neighbors(g, v)]
end

"""
        neighborprops(g::AbstractGraph, v::AbstractString; property = :name)

## Description

Get the specified property for each neighbor of `v`, where `v` is the property of that node.
"""
function neighborprops(g::AbstractGraph, v::AbstractString; property = :name)
    return [get_prop(g, a, property) for a in neighbors(g, get_prop(g, v, property))]
end

export neighborprops

"""
        neighborprops!(
            nb::Vector{Vector{S}}, g::AbstractGraph; property = :name
        )

## Description

Get the property for each neighbor, for each node in the graph.
"""
function neighborprops!(
    nb::Vector{Vector{S}}, g::AbstractGraph; property = :name
) where S <: Any
    for v in 1:nv(g)
        nb[v] = neighborprops(g, v; property)
    end
end

"""
        neighborprops!(
            nb::Vector{Vector{Vector{S}}}, gs::Vector{T}; property = :name
        )

## Description

Get the property for each neighbor, for each node in the graph, for a vector of graphs.
"""
function neighborprops!(
    nb::Vector{Vector{Vector{S}}}, gs::Vector{T}; property = :name
) where {T <: AbstractGraph, S <: Any}
    for (i, g) in enumerate(gs)
        neighborprops!(@views(nb[i]), g; property)
    end
end

export neighborprops!

"""
        neighbordata(ndfw; additionals = nothing, flat = true)

## Description

- `additionals`: additional variables to include from `ndfw`

Extract neighbor names from `ndfw` network info DataFrame.
"""
function neighbordata(
    ndfw; additionals = nothing, vector_additionals = nothing,
    flat = true
)
    
    nb = Vector{Vector{Vector{String}}}(undef, length(ndfw[!, :graph]));
    for (i, x) in enumerate(ndfw.names)
        nb[i] = Vector{Vector{String}}(undef, length(x))
    end

    neighborprops!(nb, ndfw[!, :graph])

    nfo = if isnothing(additionals)
        DataFrame(
            :village_code => ndfw[!, :village_code],
            :names => ndfw[!, :names],
            :neighbors => nb
        )
    else
        DataFrame(
        :village_code => ndfw.village_code,
        :names => ndfw.names,
        :neighbors => nb,
        [e => ndfw[!, e] for e in additionals]...,
        [e => ndfw[!, e] for e in vector_additionals]...
    )
    end

    return if flat
        nfo_ = @chain nfo begin
            flatten(
                [
                    :names, :neighbors,
                    vector_additionals...
                ],
                scalar = Missing
            )
            flatten([:neighbors], scalar = Missing)
        end
        rename!(nfo_, :names => :name) 
        nfo_
    else
        nfo
    end
end

export neighbordata
