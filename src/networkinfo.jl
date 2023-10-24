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

function network_info!(
    ndf, cx, relvals, villes;
    moddict = nothing, relnames = nothing
    #, symmetric = true
)

    relnames = if isnothing(relnames)
        relvals
    else
        relnames
    end

    cnt = 0

    for (rel, relname) in zip(relvals, relnames)
        # preallocate for graphs and distances
        # dmats = Vector{Matrix{Float64}}(undef, length(gs));

        cxr = if typeof(rel) <: Vector
            @views cx[cx.relationship .∈ Ref(rel), :];
        else
            @views cx[cx.relationship .== rel, :];
        end
        
        cxr = unique(cxr[!, [:ego, :alter, :village_code]])
        gcx = groupby(cxr, :village_code);

        for (i, ville) in enumerate(villes)
            cnt += 1
            
            cxrv = get(gcx, (village_code = ville,), missing)
            g = MetaGraph(cxrv, :ego, :alter)
            set_indexing_prop!(g, :name)
            
            ndf[cnt, :village_code] = ville
            ndf[cnt, :relation] = relname
            ndf[cnt, :names] = [get_prop(g, i, :name) for i in 1:nv(g)];

            for (k, v) in node_fund
                ndf[cnt, k] = v(g)
            end

            for (k, (v, _)) in g_fund
                ndf[cnt, k] = v(g)
            end

            if !isnothing(moddict)
                ndfv = fill(0, length(ndf.names[cnt]))
                for (k, e) in enumerate(ndf.names[cnt])
                    ndfv[k] = get(moddict, e, 0)
                end
                #ndf[cnt, :modularity_religion] = modularity(g, ndfv)
            end

            ndf[cnt, :graph] = g
        end
    end
end

# propertyvec for modularity
function modudict(cr, v)
    ucr = unique(select(cr, [:perceiver, :religion]));
    replace!(ucr[!, v], missing => "Missing")
    levels(ucr[!, v])
    moddict = Dict(ucr.perceiver .=> levelcode.(ucr[!, v]));
    misdx = findfirst(levels(ucr[!, v]) .== "Missing")
    moddict, misdx
end

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
