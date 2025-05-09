# cssdistances_without_ndf.jl

function cssdistances(
    css, con, wave;
    alter_source = "Census", nets = nets, ids = ids, rl = rl
)
    alters_n = :alters;
    ego_n = :perceiver;

    villes = sunique(css.village_code);
    cx = @subset con :village_code .∈ Ref(villes) :wave .== wave;
    replace!(cx.relationship, "are_related" => "kin");
    
    if !isnothing(alter_source)
        @subset! cx :alter_source .== "Census"
    end

    relvals = [
        rl.ft, rl.pp, "kin",
        nets.union, unique(cx.relationship)
    ];

    relnames = [rl.ft, rl.pp, "kin", "union", "any"] .* "_dists";

    cc = select(css, :perceiver, :village_code, :village_name, :relation);
    cc[!, alters_n] = [[e1, e2] for (e1, e2) in zip(css.alter1, css.alter2)];

    # preallocate for graphs and distances
    gss = [Vector{MetaGraph}(undef, length(villes)) for _ in relvals];
    dmatss = [Vector{Matrix{Float64}}(undef, length(villes)) for _ in relvals];

    perceiver_distances!(
        gss, dmatss,
        cc, cx, relvals, villes, ids.vc, ego_n, alters_n;
        relnames = relnames
    )

    # zero not possible so code that way
    # to drop NaN and Inf
    # reduce(vcat, cc.personal_private_dists_p) |> sunique

    # tag each distance as to perceiver to between alters
    rnsp = relnames .* "_p";
    rnsa = relnames .* "_a";

    cc1 = transform(
        cc, [x => ByRow(x -> mean(x)) for x in rnsp], renamecols = false
    );

    if cc.perceiver != css.perceiver
        error("cannot concat: row mismatch")
    end

    cc1[!, :dists_p] = missings(Float64, nrow(cc1));
    cc1[!, :dists_a] = missings(Float64, nrow(cc1));

    # assign distance for that relationship
    # e.g., `dists_p` gives free time when `relation` == rl.ft
    for (i, e) in enumerate(cc1.relation)
        r = if e == "know_each_other"
            "any"
        elseif e == "are_related"
            "kin"
        else
            e
        end
        cc1[i, :dists_p] = cc1[i, findfirst(r * "_dists_p" .== names(cc1))]
        cc1[i, :dists_a] = cc1[i, findfirst(r * "_dists_a" .== names(cc1))]
    end;

    disallowmissing!(cc1, [:dists_p, :dists_a]);

    # whether tie exists
    # perfect match
    # cc1.socio4 = cc1.dists_a .== 1.0;
    # css.socio4 == cc1.socio4

    # add variables denoting whether variable isinf, isnan, or both
    @inline usable(x) = !(isnan)(x) & !(isnan)(x)

    rnsp2 = vcat(rnsp, ["dists_p", "dists_a"])

    transform!(
        cc1,
        [x => ByRow(x -> !(isinf)(x)) => Symbol(string(x) * "_notinf") for x in rnsp2],
        [x => ByRow(x -> !(isnan)(x)) => Symbol(string(x) * "_notnan") for x in rnsp2],
        [x => ByRow(x -> usable(x)) => Symbol(string(x) * "_finite") for x in rnsp2]
    );

    #=
    set distance to 0 for infinite or NaN distances

    those that are from disconnected components, or don't exist together
    the NaN decision is more questionable, but I have noted it
    distance models will only include distance when interacted with isnotinf
    so that we have an effect of not being infinite, and then for those who are
    not infinite, we assess the effect of distance
    =#

    css = hcat(
        css,
        select(cc1, Not([:perceiver, :village_code, :village_name, :relation, :alters]))
    );

    ## set distance to 0 for infinite or NaN distances
    # those that are from disconnected components, or don't exist together
    # the NaN decision is more questionable
    # distance models will only include distance when interacted with isnotinf
    # so that we have an effect of not being infinite, and then for those who are
    # not infinite, we assess the effect of distance

    distance_interaction!(css, :dists_p)
    distance_interaction!(css, :dists_a)
    
    return css
end

export cssdistances

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
    gss, dmatss,
    cc, cx, relvals, villes, vg_n, ego_n, alters_n;
    relnames = nothing, symmetric = true
)

    # separately for each network type
    for (c, rel) in enumerate(relvals)

        gs = @views gss[c]
        dmats = @views dmatss[c]

        relname = if isnothing(relnames)
            rel * "_dists";
        else
            relnames[c]
        end

        cxr = if typeof(rel) <: Vector
            @views cx[cx.relationship .∈ Ref(rel), :];
        else
            @views cx[cx.relationship .== rel, :];
        end
        
        cxr = unique(cxr[!, [:ego, :alter, :village_code]])

        gcx = groupby(cxr, :village_code);

        # iterates over villages (and nodes)
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
