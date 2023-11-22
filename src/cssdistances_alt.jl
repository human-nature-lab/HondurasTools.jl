# cssdistances_alt.jl

DistMatDict = Dict{Tuple{Int, Int, String}, Matrix{Float64}}

function cssdistances!(
    css::T, ndf::T;
    nets = nets, ids = ids, rl = rl) where T <: AbstractDataFrame
    
    alters_n = :alters;
    ego_n = :perceiver;

    villes = sunique(css[!, ids.vc]);
    nvc = sunique(ndf[!, ids.vc]);

    @assert all([vl ∈ nvc for vl in vills])
    
    rels = sunique(ndf.relation)
    relnames = rels .* "_dists";

    cc = select(css, :perceiver, :village_code, :village_name, :relation);
    cc[!, alters_n] = [[e1, e2] for (e1, e2) in zip(css.alter1, css.alter2)];

    ndf_ = ndf[!, [:wave, ids.vc, :relation, :graph]];
    
    # preallocate distance matrices
    dd = DistMatDict();
        
    for (w, vc, rel, g) in zip(
        ndf_.wave, ndf_[!, ids.vc], ndf_[!, :relation], ndf_[!, :graph]
    )
        # mutating gdistances!() function does not seem to assign typemax
        # so had to preallocate with Inf
        dd[(w, vc, rel)] = fill(Inf, nv(g), nv(g))
    end


    perceiver_distances!(
        dmatss,
        cc, rels, ndf_, villes, ids.vc, ego_n, alters_n;
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

function _fill_dmats!(dm)
    # populate distance matrix
    for j in 1:nv(g)
        gdistances!(g, j, @views(dm[:, j])) # unweighted only
        # dm[:, j] = dijkstra_shortest_paths(g, j).dists
    end
end

function perceiver_distances!(
    dd::DistMatDict,
    cc, ndf, villes, vg_n, ego_n, alters_n;
)

(w, vc, rel, g) = (collect∘zip)(
        ndf.wave, ndf[!, ids.vc], ndf[!, :relation], ndf[!, :graph]
    )[1]

    # separately for each network type
    for (w, vc, rel, g) in zip(
        ndf.wave, ndf[!, ids.vc], ndf[!, :relation], ndf[!, :graph]
    )
    
        relname = rel * "_dists";
        dm = dd[(w, vc, rel)]
        
        _fill_dmats!(dm)
        

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
