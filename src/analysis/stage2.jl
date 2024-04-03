# stage2.jl

function stage2_individual_data(kinval, dats, rates, regvars, bimodel, invlink)

    efdicts = let dats = dats
        dt_ = dats.tpr;
        df_ = dats.fpr;
        
        # separate or the same (across rates)?
        ds = [dats[x].dists_p[dats[x].dists_p .!= 0] for x in rates];
        distmean = mean(reduce(vcat, ds))    

        tpr_dict = Dict(
            :kin431 => kinval,
            :dists_p => distmean,
        );

        fpr_dict = deepcopy(tpr_dict);
        fpr_dict[:dists_a] = mean(df_[df_[!, :dists_a] .!= 0, :dists_a])
        (tpr = tpr_dict, fpr = fpr_dict)
    end

    bef = refgrid_stage1(dats, regvars, efdicts; rates = rates);
    apply_referencegrids!(bimodel, bef; invlink)

    tpr_ = select(bef.tpr, :perceiver, :response)
    rename!(tpr_, :response => :tpr);
    jac = leftjoin(bef.fpr, tpr_, on = [:perceiver]);
    rename!(jac, :response => :fpr)
    dropmissing!(jac, [:fpr, :tpr])
    select(jac, Not(:err))
    
    return jac
end

export stage2_individual_data

function makeneighbordata(
    kinval,
    jacc, rhv4, ids, ndf4;
    sl = [
        :age, :man, :isindigenous, :religion,
        :relig_attend, :educated, :toiletkind, :building_id, :occupation,
        :tpr, :fpr, :j
    ]
)

    # filter to CSS villages
    rhv4 = deepcopy(rhv4)

    jacc_ = @subset(jacc, $kin .== kinval)

    leftjoin!(
        rhv4,
        select(jacc_, :perceiver, :tpr, :fpr, :j);
        on = [:name => :perceiver]
    );

    df1 = select(rhv4, [ids.vc, ids.n]);
    df1[!, :relation] .= "free_time"; # specify the network

    df2 = select(rhv4, [ids.vc, ids.n]);
    df2[!, :relation] .= "personal_private"; # specify the network

    df = vcat(df1, df2)

    addneighbors!(
        df, ndf4, rhv4, sl;
    );

    rhv4sel = select(rhv4, Not(:village_code))
    dropmissing!(rhv4sel, [:tpr, :fpr, :j]);

    leftjoin!(df, rhv4sel, on = :name);

    # handle neighbor variables

    # maybe include this in the `addneighbors!` function
    # where `Float64` is generalized

    process_nvariable!(df, :tpr_n, mean);
    process_nvariable!(df, :fpr_n, mean);
    process_nvariable!(df, :j_n, mean);
    df[!, kin] .= kinval
    return df
end

export makeneighbordata

"""
        linksetup()

## Description

Set up link-based data for link-based model specification to test for homophily.
Creates edge dataframe, and joins demographic characteristics from rhv4 for each alter (then reduced for the model, e.g., absolute difference in alter values).
"""
function linksetup(ndf4_, rhv4, sl;)

    edf = DataFrame(
        :edge => Edge[],
        :real => Bool[],
        :relation => String[],
        :dist => Float64[],
        :alter1 => String[],
        :alter2 => String[],
        :village_code => Int[]
    );

    # preallocate, add relation and village_code
    let df = ndf4_ # _ft
        for (g, vc, rl) in zip(df.graph, df.village_code, df.relation)
            edf_g = similar(edf, Int(nv(g) * (nv(g)-1) / 2)); # triang w/o diag
            edf_g[!, :village_code] .= vc;
            edf_g[!, :relation] .= rl
            append!(edf, edf_g)
        end
    end;

    edf_grp = groupby(edf, [:village_code, :relation]);
    let df = ndf4_; # ft
        for (g, vc, rl) in zip(df.graph, df.village_code, df.relation);
            # create possible set of links for a village
            # extract the preallocated dataframe
            edfg = get(edf_grp, (village_code = vc, relation = rl, ), missing)
            prix, _ = parentindices(edfg);
            @assert length(prix) == nv(g) * (nv(g)-1)/2 # check
            ds = fill(Inf, nv(g)) # allocates for each village
            let cnt = 0 # track double index
                for i in 1:nv(g)
                    gdistances!(g, i, ds) # overwrite for each i
                    for j in 1:nv(g)
                        if i < j
                            cnt += 1
                            alter1 = get_prop(g, i, :name)
                            alter2 = get_prop(g, j, :name)
                            # assign
                            prix_ = prix[cnt];
                            edf[prix_, :edge] = Edge(i, j)
                            edf[prix_, :real] = has_edge(g, Edge(i, j))
                            edf[prix_, :dist] = ds[j]

                            edf[prix_, :alter1] = alter1
                            edf[prix_, :alter2] = alter2
                        end
                    end
                end
                @assert sum(edfg.real) == ne(g) # check
            end
        end
    end

    for (a, alter) in enumerate([:alter1, :alter2])
        leftjoin!(edf, rhv4[!, [:name, sl...]], on = [alter => :name]);
        for v in sl
            rename!(edf, v => (string(v) * "_a" * string(a)) |> Symbol)
        end
    end

    # cases where no path exists between i, j
    edf[!, :inf] .= false;
    edf[isinf.(edf.dist), :inf] .= true;
    edf[isinf.(edf.dist), :dist] .= 0.0;
    edf[!, :notinf] .= .!edf[!, :inf]

    return edf
end;

export linksetup
