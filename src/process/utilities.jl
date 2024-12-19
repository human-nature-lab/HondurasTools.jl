# utilities.jl

# make_data.jl

function gendercat(a, b)
    return if a & b
        "Men"
    elseif !(a | b)
        "Women"
    else
        "Mixed"
    end
end

export gendercat

function relcat(a, b)
    return if ismissing(a) | ismissing(b)
        missing
    elseif a == b
        "Both " * string(a)
    else
        string(a) * ", " * string(b)
    end
end

export relcat

function indigcat(a, b)
    return if ismissing(a) | ismissing(b)
        missing
    elseif a & b
        "Indigenous"
    elseif !(a | b)
        "Mestizo"
    else
        "Mixed"
    end
end

export indigcat

function educat(a, b; basic = true)
    return if basic
        if ismissing(a) | ismissing(b)
            missing
        elseif a == b
            "Same"
        else
            "Mixed"
        end
    elseif !basic
        if ismissing(a) | ismissing(b)
            missing
        elseif a == b
            "Both " * string(a)
        else
            string(a) * ", " * string(b)
        end
    end
end

export educat

#%%

# the most recent version of this is not correctly loaded
# in HondurasCSS or HondurasTools
function DataFrame2(gr::T; type = :node) where T <:AbstractMetaGraph
    fl, prps, en, nu = if type == :node
        :node => Int[], gr.vprops, vertices, nv
    elseif type == :edge
        :edge => Edge[], gr.eprops, edges, ne
    else
        error("You must specify type as :node or :edge")
    end

    dx = DataFrame(fl)

    # this block only applies if there are defined properties
    # on the MetaGraph object `gr`
    if length(values(prps)) > 0
        x = unique(reduce(vcat, values(prps)))
        for y in x
            for (k, v) in y
                if typeof(v) != Missing # update if there are non-missing entries
                    dx[!, k] = typeof(v)[]
                end
                if string(k) ∈ names(dx)
                    allowmissing!(dx, k)
                end
            end
        end
    end
    
    dx = similar(dx, nu(gr))

    for (i, e) in (enumerate∘en)(gr)

        dx[i, type] = e
        pr = props(gr, e)
        for (nme, val) in pr
            dx[i, nme] = val
        end
    end
    
    for v in Symbol.(names(dx))
        if !any(ismissing.(dx[!, v]))
            disallowmissing!(dx, v)
        end
    end
    return dx
end

export DataFrame2

# fill in the remaining ties (that do not exist)
function addfake!(gdf, g)
    for i in 1:nv(g)
        for j in 1:nv(g)
            if i < j
                if !has_edge(g, i, j)
                    push!(gdf, [Edge(i, j), g[i, :name], g[j, :name], false])
                end
            end
        end
    end
end

export addfake!
