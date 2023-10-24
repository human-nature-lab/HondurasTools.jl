# cssdistances.jl

function _fill_dmats!(dmats, gs, villes, gcx)
    # construct the village graph, use name as index property
    for (i, ville) in enumerate(villes)
        cxrv = get(gcx, (village_code = ville,), missing)
        g = MetaGraph(cxrv, :ego, :alter)
        set_indexing_prop!(g, :name)
        gs[i] = g
        
        # preallocate distance matrix for graph i
        dm = dmats[i] = fill(Inf, nv(g), nv(g))
    
        # populate distance matrix
        for j in 1:nv(g)
            # mutating function does not seem to assign typemax
            # so had to preallocate with Inf
            gdistances!(g, j, @views(dm[:, j])) # unweighted only
            # dm[:, j] = dijkstra_shortest_paths(g, j).dists
            # dijkstra_shortest_paths(g, 1).dists == gdistances(g, 1)
        end
    end
end

function perceiver_distances!(
    cc, cx, relvals, villes, vg_n, ego_n, alters_n;
    relnames = nothing, symmetric = true
)
    for (c, rel) in enumerate(relvals)

        relname = if isnothing(relnames)
            rel * "_dists";
        else
            relnames[c]
        end

        # preallocate for graphs and distances
        gs = Vector{MetaGraph}(undef, length(villes));
        dmats = Vector{Matrix{Float64}}(undef, length(gs));

        cxr = if typeof(rel) <: Vector
            @views cx[cx.relationship .∈ Ref(rel), :];
        else
            @views cx[cx.relationship .== rel, :];
        end
        
        cxr = unique(cxr[!, [:ego, :alter, :village_code]])

        gcx = groupby(cxr, :village_code);

        _fill_dmats!(dmats, gs, villes, gcx)

        # preallocate for relationship
        rnp = relname * "_p"
        rna = relname * "_a"
        cc[!, rnp] = [fill(0.0, length(v)) for v in cc[!, alters_n]];
        
        cc[!, rna] = if symmetric
            fill(0.0, nrow(cc))
        else
            [fill(0.0, length(v)) for v in cc[!, alters_n]];
        end
        #

        gcc = groupby(cc, :village_code)
        for (k, gdi) in pairs(gcc)
            gidx = findfirst(k[vg_n] .== villes); # safety on order
            dm = dmats[gidx];
            g = gs[gidx]

            for (i, (a, b)) in (enumerate∘zip)(gdi[!, ego_n], gdi[!, alters_n])
                # there may be cases where a villager in css does not appear
                # in the graph (connections)
                
                ii = tryindex(g, a, :name)
                
                # perceiver to alter
                for (j, bi) in enumerate(b)
                    jj = tryindex(g, bi, :name)
                    # if both villagers exist assign distance, NaN otherwise
                    gdi[i, rnp][j] = if !(isnan(ii) | isnan(jj))
                        dm[ii, jj]
                    else NaN
                    end
                end

                # distance between alters (symmetric == true)
                a1 = tryindex(g, b[1], :name)
                a2 = tryindex(g, b[2], :name)
                gdi[i, rna] = if !(isnan(a1) | isnan(a2))
                    dm[a1, a2]
                else NaN
                end

            end
        end
    end
end
