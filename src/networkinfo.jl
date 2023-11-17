# networkinfo.jl

# network functions to call by default
node_fund = Dict{Symbol, Function}();
g_fund = Dict{Symbol, Tuple{Function, DataType}}();

let
    # node-level stats
    node_fund[:betweenness_centrality] = g -> betweenness_centrality(g, normalize = true)
    node_fund[:degree_centrality] = g -> degree_centrality(g, normalize = true)
    node_fund[:closeness_centrality] = g -> closeness_centrality(g, normalize = true)
    node_fund[:stress_centrality] = g -> stress_centrality(g)
    node_fund[:radiality_centrality] = g -> radiality_centrality(g)
    node_fund[:local_clustering_coefficient] = g -> local_clustering_coefficient(g)
    node_fund[:triangles] = g -> triangles(g)
    # core-perhiphery
    # cf. https://doi.org/10.1126/sciadv.abc9800
    node_fund[:core_periphery_deg] = g -> core_periphery_deg(g)

    # use separately
    # modularity(g, c, distmx=weights(g), γ=1.0)

    # graph-level stats
    g_fund[:assortivity] = (g -> assortativity(g), Float64)
    g_fund[:clique_percolation] = (g -> clique_percolation(g), Vector{BitSet})
    g_fund[:global_clustering_coefficient] = (g -> global_clustering_coefficient(g), Float64)
    g_fund[:local_clustering] = (g -> local_clustering(g), Tuple{Vector{Int64}, Vector{Int64}})
end

export node_fund, g_fund

function initialize_ndf(cx, cxx, node_fund, g_fund, mods)

    uc2 = unique(cxx[!, [:wave, :village_code, :relationship]])

    uc2[!, :names] = Vector{Vector{String}}(undef, nrow(uc2))
    uc2[!, :names_all] = Vector{Vector{String}}(undef, nrow(uc2))

    for (i, (w, vc)) in (enumerate∘zip)(uc2[!, :wave], uc2[!, :village_code])
        # cx contains all edges in that village
        # need this for full unique set
        c1 = cx[!, :wave] .== w;
        c2 = cx[!, :village_code] .== vc
        n1 = @views cx[c1 .& c2, :ego]
        n2 = @views cx[c1 .& c2, :alter]
        uc2[i, :names_all] = (sort∘unique∘vcat)(n1, n2)
    end

    for (k, _) in node_fund
        uc2[!, k] = Vector{Vector{Float64}}(undef, nrow(uc2))
    end

    for (k, v) in g_fund
        uc2[!, k] = Vector{v[2]}(undef, nrow(uc2))
    end
    
    uc2[!, :graph] = Vector{MetaGraph}(undef, nrow(uc2))
    
    for v in mods
        k = Symbol("modularity_" * string(v))
        uc2[!, k] = Vector{Float64}(undef, nrow(uc2))
    end
    
    rename!(uc2, :relationship => :relation)
    return uc2
end

export initialize_ndf

function network_info(
    cx, cr;
    waves = [1,3,4],
    relnames = ["free_time", "personal_private", "kin", "union", "any"]
)

    cxf = @subset cx :alter_source .== "Census" :wave .∈ Ref(waves);
    select!(cxf, [:wave, :village_code, :relationship, :ego, :alter])

    # set up connections data with relationships
    # for combinations
    let
        relset = sunique(cxf.relationship)
        cxcomb = @subset cxf :relationship .∈ Ref(relset)
        cxcomb.relationship .= "any"
        append!(cxf, cxcomb)
    end

    let
        relset = ["free_time", "personal_private", "kin"]
        cxcomb = @subset cxf :relationship .∈ Ref(relset)
        cxcomb.relationship .= "union"
        append!(cxf, cxcomb)
    end

    @subset! cxf :relationship .∈ Ref(relnames)
    
    mods = [:protestant, :isindigenous]
    @time ndf = initialize_ndf(cx, cxf, node_fund, g_fund, mods);
    @show "initialized"

    gcx = groupby(cxf, [:village_code, :relationship, :wave]);
    @time addgraphs!(ndf, gcx)
    @show "graphs added"

    # modularity partition vectors
    # religion
    let v = :protestant;
        grouppartition!(ndf, cr, v)
        # treat missing as another category
        ndf[!, v] = [replace(x, missing => 1, false => 2, true => 3) for x in ndf[!, v]];
    end;

    # indigeneity
    let v = :isindigenous;
        grouppartition!(ndf, cr, v)
        # treat missing as another category
        ndf[!, v] = [replace(x, missing => 1, false => 2, true => 3) for x in ndf[!, v]];
    end;

    @show "setup complete"

    @time network_info!(ndf, mods);

    return ndf
end

export network_info

function addgraphs!(ndf, gcx)
    Threads.@threads for arw in eachrow(ndf)
        tpl = (village_code = arw[:village_code], relationship = arw[:relation], wave = arw[:wave])

        subnet = gcx[tpl]
        
        g = arw[:graph] = MetaGraph(subnet, :ego, :alter)
        set_indexing_prop!(g, :name)
        arw[:names] = [get_prop(g, v, :name) for v in vertices(g)]
    end
end

export addgraphs!

"""
        network_info!(ndf, gcx, mods)

Populate `ndf` with network information.
"""
function network_info!(ndf, mods)
    Threads.@threads for arw in eachrow(ndf)
        # add node-level measures
        for (k, v) in node_fund
            arw[k] = v(arw[:graph])
        end

        # add graph-level measures
        for (k, (v, _)) in g_fund
            arw[k] = v(arw[:graph])
        end

        # modularity
        for v in mods
            k = Symbol("modularity_" * string(v))
            arw[k] = modularity(arw[:graph], arw[v])
        end
    end
end

export network_info!


"""
        network_info!(ndf, gcx)

Populate `ndf` with network information.
"""
function network_info!(ndf, gcx)
    Threads.@threads for arw in eachrow(ndf)
        tpl = (village_code = arw[:village_code], relationship = arw[:relation], wave = arw[:wave])

        subnet = gcx[tpl]
        
        g = arw[:graph] = MetaGraph(subnet, :ego, :alter)
        set_indexing_prop!(g, :name)

        for (k, v) in node_fund
            arw[k] = v(g)
        end

        # add graph-level measures
        for (k, (v, _)) in g_fund
            arw[k] = v(g)
        end

        arw[:names] = [get_prop(g, v, :name) for v in vertices(g)]
    end
end

export network_info!

"""
        grouppartition!(ndf, cr, v)


## Details

`ndf` is a networkinfo DataFrame, with `names` and `village_code` populated.

Create a partition vector from `names` in `ndf` over characteristic `v`, using input information `cr`.

For use with modularity calculation. N.B. further post processing likely required to coerce values into consecutive and distinct integers for groups.
"""
function grouppartition!(ndf, cr, v)
    crv = unique(@views cr[!, [:village_code, :perceiver, v]]; view = true);
    sort!(crv, [:village_code, :perceiver])
    gcrv = groupby(crv, [:village_code]);
    et = eltype(cr[!, v])
    
    ndf[!, v] = Vector{Vector{et}}(undef, nrow(ndf));
    for (i, e) in enumerate(ndf.names)
        ndf[i, v] = missings(Bool, length(e))
    end
    
    for r in eachrow(ndf)
        gdf = gcrv[(r.village_code,)]
        for (j, n) in enumerate(r[:names])
            x = findfirst(gdf.perceiver .== n)
            if !isnothing(x)
                r[v][j] = gdf[x, v]
            end
        end
    end
end

export grouppartition!

function join_ndf_cr!(cr, ndf; rels = ["free_time", "personal_private"])
    for r in rels
        # or subset
        sndf = @views ndf[ndf.relation .== r, :];
        scr = @views cr[cr.relation .== r, [:village_code, :perceiver, [k for k in keys(node_fund)]...]];

        # one person
        Threads.@threads for i in 1:nrow(scr)
            ville = scr.village_code[i]
            vgr = scr.perceiver[i]
            # r = scr.relation[i];
            
            # (sndf.relation .== r) .& 
            rw = findfirst(sndf.village_code .== ville);
            srw = findfirst(sndf.names[rw] .== vgr);

            if !(isnothing(rw) | isnothing(srw))
                for (k, _) in node_fund
                    scr[i, k] = sndf[rw, k][srw]
                end
            end

        end
    end
end

export join_ndf_cr!
