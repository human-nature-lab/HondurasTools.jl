# jointnetwork.jl

"""
        jointnetwork(con, net_name1, net_name2, new_name; add_symmetric = false)

## ARGS

- `con` : connections data for multiple waves, villages. The function will filter to the relevant relationships (R and Q).
- `net_name1` : first relationship (R)
- `net_name2` : second relationship (Q)
- `new_name` : name for new joint relationship (W)

## Description

Take two paired networks; e.g., borrow and lend money, and construct an edgelist (network) based on a compound relationship, for relationships R, Q and new relationship W: such that if (aRb) & (bQa), then aWb. The function will also note whether each (new) edge is (i) symmetric, and (ii) whether the alter in the edge also exists as an ego (N.B., using only the data in the new set. If you want to use the larger node-set run `addsymmetric()` on the full, combined, data). Return a dataframe with columns identical to `con` that contains the edges.

"""
function jointnetwork(
    con, net_name1, net_name2, new_name;
    add_symmetric = false
)
    ndf = similar(con, 0); # store by push
    _jointnetwork!(ndf, con, net_name1, net_name2, new_name)
    if add_symmetric
        addsymmetric!(ndf) # move this to data processing
    end
    return ndf
end

function _jointnetwork!(ndf, con, net_name1, net_name2, new_name)
    for w in sort(unique(con.wave))

        conw = @views con[con.wave .== w, :];

        ## a->b if (a would borrow from b) & (b would lend to a)
        conrb = @views conw[conw[!, :relationship] .== net_name1, :];
        conrl = @views conw[conw[!, :relationship] .== net_name2, :];

        for vc in sort(unique(conw.village_code))
            conrbi = @views conrb[conrb[!, :village_code] .== vc, :];
            conrli = @views conrl[conrl[!, :village_code] .== vc, :];

            vtx = unique(vcat(conrbi.ego, conrbi.alter, conrli.ego, conrli.alter));

            g1 = SimpleDiGraph(length(vtx));
            g2 = SimpleDiGraph(length(vtx));

            samevillage = Bool[]
            samebldg = Bool[]
            tie = Set{Int}[]
            # borrow
            for (i, (a, b)) in enumerate(zip(conrbi.ego, conrbi.alter))
                ai, bi = findfirst(vtx .== a), findfirst(vtx .== b)
                add_edge!(g1, ai => bi)

                push!(tie, Set([ai, bi]))
                push!(samevillage, conrbi.same_village[i])
                push!(samebldg, conrbi.same_building[i])
            end

            # lend
            for (i, (a, b)) in enumerate(zip(conrli.ego, conrli.alter))
                ai, bi = findfirst(vtx .== a), findfirst(vtx .== b)
                add_edge!(g2, ai => bi)

                push!(tie, Set([ai, bi]))
                push!(samevillage, conrli.same_village[i])
                push!(samebldg, conrli.same_building[i])
            end

            g3 = SimpleDiGraph(length(vtx));

            # two loops to grab all cases where a => b exists in g(i) and b => a exists in g(j)

            for e in edges(g1)
                # a borrow from b and b would lend
                if has_edge(g2, dst(e) => src(e))
                    add_edge!(g3, e)
                end
            end

            for e in edges(g2)
                # b lend to a and a would borrow
                if has_edge(g1, dst(e) => src(e))
                    add_edge!(g3, dst(e) => src(e))
                end
            end

            for e in edges(g3)
                idx = findfirst(isequal(Set([src(e), dst(e)])), tie)
                push!(
                    ndf,
                    [
                        vtx[src(e)],
                        vtx[dst(e)],
                        "none", new_name, samevillage[idx], samebldg[idx], vc, w, missing, "", false, false
                    ]
                )
            end
        end
    end
end
