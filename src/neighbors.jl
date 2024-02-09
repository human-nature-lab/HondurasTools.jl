# neighbors.jl

function getneighbors(prc, vl, rel, nds; ids = ids, relname = :relation)

    ix = findfirst((vl .== nds[!, ids.vc]) .& (rel .== nds[!, relname]))
    g = nds[ix, :graph]
    vprc = tryindex(g, prc, :name; alt = missing)

    return if !ismissing(vprc)
        [get_prop(g, va, :name) for va in neighbors(g, vprc)]
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

    # allowmissing!(out, :neighbors)
    # for i in 1:nrow(out)
    #     if all(ismissing.(out[i, :neighbors]))
    #         out[i, :neighbors] = missing
    #     end
    # end
    # out.neighbors[coalesce.(passmissing(length).(out.neighbors), 0) .== 0] .= missing;
    # out.neighbors = [passmissing(disallowmissing)(out.neighbors[i]) for i in 1:nrow(out)]

    @assert nrow(out) == nrow(df_a)
    @rtransform!(out, :neighbornum = passmissing(length)(:neighbors))

    leftjoin!(df, out; on = [ids.vc, unitname, :relation])

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
