# socionew.jl

function socioassign(cr, ndf;
    θ = (rel = "same", grps = [:village_code, :relation],),
    p = (relation = :relation, vc = :village_code, g = :graph,)
)

    nr = size(cr, 1)
    gcr = groupby(cr, θ.grps);
    ndfsel = ndf[!, [p.vc, p.relation, p.g, :nodes]]

    socionew = missings(Bool, nr);
    sociostat = missings(String, nr);

    _socioassign!(socionew, sociostat, gcr, ndfsel, θ, p)
    
    # if either fails, there is a problem
    # there are nodes missing
    sociostat = disallowmissing(sociostat)
    socionew = disallowmissing(socionew)

    return socionew, sociostat
end

function _socioassign!(socionew, sociostat, gcr, ndf, θ, p)
    Threads.@threads for k in eachindex(gcr)

        # relation to grab
        refrel = if (θ.rel .== "same")
            k[p.relation] # same relation as pair-row
        else
            θ.rel # other specified relation that will be constant across pair-rows
        end

        df = gcr[k]
        rw, _ = parentindices(df)
        ndf_idx = findfirst(
            (ndf[!, p.vc] .== k[p.vc]) .& (ndf[!, p.relation] .== refrel)
        );
        g = ndf[ndf_idx, :graph];
        nds = ndf[ndf_idx, :nodes]

        # c1 = df.alter1 .== crb.alter1[1]; c2 = df.alter2 .== crb.alter2[1];
        # i = findfirst(c1 .& c2)
        # alternate method
        # edg = edges(g) |> collect
        # edgn = [Set([get_prop(g, e.src, :name), get_prop(g, e.dst, :name)]) for e in edg];
        # dfedgn = [Set([a1, a2]) for (a1, a2) in zip(df.alter1, df.alter2)];
        # for (h, s) in enumerate(dfedgn)
        #     df.trck[h] = s ∈ edgn
        # end

        for i in eachindex(df.perceiver)
            a1 = df.alter1[i];
            a2 = df.alter2[i];
            
            # check if each node is present in the network
            a1_ix = try
                g[a1, :name]
            catch
                missing
            end;

            a2_ix = try
                g[a2, :name]
            catch
                missing
            end;

            a1pres = a1 ∈ nds
            a2pres = a2 ∈ nds

            sociostat[rw[i]] = if a1pres & !a2pres
                "A1 missing"
            elseif !a1pres & a2pres
                "A2 missing"
            elseif !a1pres & !a2pres
                "Missing"
            else
                socionew[rw[i]] = if !(ismissing(a1_ix) | ismissing(a2_ix))
                    has_edge(g, a1_ix, a2_ix)
                else
                    false
                end
                "Present"
            end
        end
    end
end

export socioassign
