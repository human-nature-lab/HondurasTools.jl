# networks.jl
# functions for processing the Honduras network data

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

function _egoreducts!(nf, nets, egos, alters, codes, codename; directed = true)
    for code in codes
        println(code)
        egos_c = @views egos[nets .== code]
        alters_c = @views alters[nets .== code]

        g, vtx = graph(egos_c, alters_c; directed = directed)
        nf_code = egoreduct(g, vtx, code, codename)
        append!(nf, nf_code)
    end
end
