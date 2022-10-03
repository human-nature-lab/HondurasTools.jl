# graph.jl

"""
    graph(egos, alters; directed = true)

vtx: the position of a name in vtx gives its index in the graph object
"""
function graph(egos, alters; directed = true)
    vtx = sort(unique(vcat(egos, alters)));
    
    g = if directed
        SimpleDiGraph(length(vtx))
    else
        SimpleGraph(length(vtx))
    end

    addties!(g, egos, alters, vtx)
    return g, vtx
end

function addties!(g, egos, alters, vtx)
    for (e, a) in zip(egos, alters)
        # convert named node to index for Graphs
        # reconstruct with vtx order
        ei = findfirst(vtx .== e)
        ai = findfirst(vtx .== a)
        add_edge!(g, ei, ai)
    end
end