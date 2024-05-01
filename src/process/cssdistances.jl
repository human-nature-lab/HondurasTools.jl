# cssdistances.jl

DistMatDict = Dict{Tuple{Int, Int, String}, Matrix{Float64}}

# add variables denoting whether variable isinf, isnan, or both
@inline usable(x) = !(isnan)(x) & !(isnan)(x)

"""
        cssdistances(
            css::T, ndf::T;
            nets = nets, ids = ids, rl = rl,
            ego_n = :perceiver, alters_n = :alters,
            post = true) where T <: AbstractDataFrame

## Description

Use `ndf` to construct distances between alters, and perceiver to alters in css.

- `post = true` further reduces the data (mean of alters to perceiver).
"""
function cssdistances(
    css::T, ndf::T;
    nets = nets, ids = ids, rl = rl,
    ego_n = :perceiver, alters_n = :alters,
    post = true
) where T <: AbstractDataFrame
    
    villes = sunique(css[!, ids.vc]);
    nvc = sunique(ndf[!, ids.vc]);

    @assert all([vl ∈ nvc for vl in villes])
    
    rels = sunique(ndf.relation)
    relnames = rels .* "_dists";

    cc = select(css, :perceiver, :village_code, :village_name, :relation);
    cc[!, alters_n] = [[e1, e2] for (e1, e2) in zip(css.alter1, css.alter2)];

    ndf_ = ndf[!, [:wave, ids.vc, :relation, :graph, :names]];

    # preallocate distances
    dd = DistMatDict();
    _preallocate_distances!(
        dd, cc, ndf_, alters_n, !any(is_directed.(ndf_.graph))
    )

    gcc = groupby(cc, [ids.vc]);
    
    # zero not possible so code that way
    # to drop NaN and Inf
    _distances!(dd::DistMatDict, gcc, ndf, ego_n, alters_n; ids = ids)

    if !post
        return cc
    else
        return _distances_post(cc, css, relnames)
    end
end

export cssdistances

"""

## Description

Preallocate for the distances.
"""
function _preallocate_distances!(dd, cc, ndf_, alters_n, symmetric)
    for rel in unique(ndf_[!, :relation])
        # preallocate for relationship, distance columns in css
        rnp = rel * "_dists" * "_p"
        rna = rel * "_dists" * "_a"
        cc[!, rnp] = if symmetric
            [fill(0.0, length(v)) for v in cc[!, alters_n]]
        else
            error("not done yet")
        end
        cc[!, rna] = if symmetric
            fill(0.0, nrow(cc))
        else
            error("not done")
        end
    end

    for (w, vc, rel, g) in zip(
        ndf_.wave, ndf_[!, ids.vc], ndf_[!, :relation], ndf_[!, :graph]
    )

        # The mutating `gdistances!` function does not assign typemax
        # so, preallocate with `Inf`
        dd[(w, vc, rel)] = fill(Inf, nv(g), nv(g))
    end
end

"""
        _fill_dmats!(dm, g)

## Description

Populate distance matrix using `gdistances!`.
"""
function _fill_dmats!(dm, g)
    for j in 1:nv(g)
        gdistances!(g, j, @views(dm[:, j])) # unweighted only
        # dm[:, j] = dijkstra_shortest_paths(g, j).dists
    end
end

"""
        _matchdistances!(gdi, dm, g, ego_n, alters_n, rnp, rna; unit = :name)

## Description

Match calculated distances into rows of the `css` edgelist. Assign `NaN` when distance is not defined.

"""
function _matchdistances!(gdi, dm, g, ego_n, alters_n, rnp, rna; unit = :name)
    for (i, (a, b)) in (enumerate∘zip)(gdi[!, ego_n], gdi[!, alters_n])
        # there may be cases where a villager in css does not appear
        # in the graph (connections)
        
        ii = tryindex(g, a, unit)
        
        # perceiver to alter
        for (j, bi) in enumerate(b)
            jj = tryindex(g, bi, unit)
            # if both villagers exist assign distance, NaN otherwise
            gdi[i, rnp][j] = if !(isnan(ii) | isnan(jj))
                dm[ii, jj]
            else NaN
            end
        end

        # distance between alters (symmetric == true)
        a1 = tryindex(g, b[1], unit)
        a2 = tryindex(g, b[2], unit)
        gdi[i, rna] = if !(isnan(a1) | isnan(a2))
            dm[a1, a2]
        else NaN
        end
    end
end

function _distances!(dd::DistMatDict, gcc, ndf, ego_n, alters_n; ids = ids)

    for (w, vc, rel, g) in zip(
        ndf.wave, ndf[!, ids.vc], ndf[!, :relation], ndf[!, :graph]
    )
    
        # add distances
        dm = dd[(w, vc, rel)]

        _fill_dmats!(dm, g)

        # cc does not handle wave -> could be added later
        gdi = gcc[(village_code = vc,)]

        rnp = rel * "_dists" * "_p"
        rna = rel * "_dists" * "_a"
        
        _matchdistances!(gdi, dm, g, ego_n, alters_n, rnp, rna; unit = :name)
    end
end

function _distances_post(cc, css, relnames)
    # post processing

    # tag each distance as to perceiver to between alters
    rnsp = relnames .* "_p"; # transform to scalar (cc1)
    rnsa = relnames .* "_a"; # don't need to transform, scalar already

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
    Threads.@threads for i in eachindex(cc1.relation)
        e = cc1.relation[i]
        r = if e == "know_each_other"
            "any"
        # elseif e == "are_related"
        #     "kin"
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

    # the relationships to include for the distances
    relset = vcat(["dists_p", "dists_a"], rnsp, rnsa)

    transform!(
        cc1,
        [x => ByRow(x -> !(isinf)(x)) => Symbol(string(x) * "_notinf") for x in relset],
        [x => ByRow(x -> !(isnan)(x)) => Symbol(string(x) * "_notnan") for x in relset],
        [x => ByRow(x -> usable(x)) => Symbol(string(x) * "_finite") for x in relset]
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
    # distance models will only include distance when interacted with is notinf
    # so that we have an effect of not being infinite, and then for those who
    # are not infinite, we assess the effect of distance

    return css
end
