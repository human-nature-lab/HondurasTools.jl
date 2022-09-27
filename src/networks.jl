# networks.jl
# functions for processing the Honduras network data

"""
        mk_graph(el; ego = :ego, alter = :alter)

Make a directed graph object from an edgelist.
"""
function mk_graph(el; ego = :ego, alter = :alter)
    egos = el[!, ego]
    alters = el[!, alter]
    vtx = unique(vcat(egos, alters));
    g = DiGraph(length(vtx));
    addties!(g, egos, alters)
    return g, vtx
end

"""
        mk_graph(egos, alters)

Make a directed graph object from vectors of egos and alters.
"""
function mk_graph(egos, alters)
    vtx = unique(vcat(egos, alters));
    g = DiGraph(length(vtx));
    addties!(g, egos, alters)
    return g, vtx
end

function addties!(g, egos, alters)
    for (e, a) in zip(egos, alters)
        ei = findfirst(egos .== e)
        ai = findfirst(alters .== a)
        add_edge!(g, ei, ai)
    end
end

function egoreduct(g, vtx, code, codename)
    nf = DataFrame(:name => vtx, codename => code)
    nf[!, :degree] = zscore(degree(g));
    nf[!, :between] = zscore(betweenness_centrality(g));
    nf[!, :eigen] = zscore(eigenvector_centrality(g));
    nf[!, :close] = zscore(closeness_centrality(g));
    return nf
end

"""
        egoreducts(els, codes, codename)

Calculate individual network characteristics, and return a DataFrame.

ARGS
====
- els : edgelist
- codes : village codes to include
- codename : name of village code variable
"""
function egoreducts(els, codes, codename)
    nf = DataFrame();

    nets, egos, alters = eachcol(els[!, [codename, :ego, :alter]]);
    _egoreducts!(nf, nets, egos, alters, codes, codename)
    
    return nf
end

function _egoreducts!(nf, nets, egos, alters, codes, codename)
    for code in codes
        println(code)
        egos_c = @views egos[nets .== code]
        alters_c = @views alters[nets .== code]

        g, vtx = mk_graph(egos_c, alters_c)
        nf_code = egoreduct(g, vtx, code, codename)
        append!(nf, nf_code)
    end
end
