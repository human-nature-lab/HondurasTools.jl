# networkinfo.jl

# network functions to call by default
node_fund = Dict{Symbol, Function}();
g_fund = Dict{Symbol, Tuple{Function, DataType}}();

let
    # node-level stats
    node_fund[:betweenness_centrality] = g -> betweenness_centrality(g, normalize = true)
    node_fund[:betweenness] = g -> betweenness_centrality(g, normalize = false)
    node_fund[:degree_centrality] = g -> degree_centrality(g, normalize = true)
    node_fund[:degree] = g -> degree_centrality(g, normalize = false)
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
    
    if !isnothing(mods)
        for v in mods
            k = Symbol("modularity_" * string(v))
            uc2[!, k] = Vector{Float64}(undef, nrow(uc2))
        end
    end
    
    rename!(uc2, :relationship => :relation)
    return uc2
end

export initialize_ndf

"""
networkinfo(
    cx, cr;
    waves = [1,3,4],
    relnames = ["free_time", "personal_private", "kin", "union", "any"],
    alter_source = "Census"
)

## Description

- `cx`: connections data
- `rr` = nothing: reference DataFrame for modularity calculations
- `mods` = nothing: Vector of variables in `rr` to calculate modularity over. currently, only works for binary variables with missing values.

Construct a DataFrame that contains network statistics and graph objects
from an input edgelist. N.B. that the edgelist should include all possible edges, which is filtered to the desired number of relationships. The larger set is needed to capture nodes that exist but do not have any ties in a particular network. Full sets are stored in `names_all`.

N.B. that combination networks (and therefore `relnames`) is basically only usable as-is.

"""
function networkinfo(
    cx;
    waves = [1, 3, 4],
    relnames = ["free_time", "personal_private", "kin", "union", "any"],
    alter_source = "Census",
    rr = nothing,
    mods = nothing,
    unitname = :perceiver
)

    cxf = @subset cx :wave .∈ Ref(waves);
    if !isnothing(alter_source)
        @subset! cx :alter_source .== alter_source;
    end
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
    
    @time ndf = initialize_ndf(cx, cxf, node_fund, g_fund, mods);
    @info "initialized"

    gcx = groupby(cxf, [:village_code, :relationship, :wave]);
    @time addgraphs!(ndf, gcx)
    @info "graphs added"

    if !isnothing(mods) & !isnothing(rr)
        for v in mods
            @info "modularity: " * string(v)
            # modularity partition vectors
            grouppartition!(ndf, rr, v, unitname)
            # treat missing as another category
            # currently, only works for binary categories with missing!!!
            ndf[!, v] = [
                replace(
                    x, missing => 1, false => 2, true => 3
                ) for x in ndf[!, v]
            ];
        end
        @info "modularity complete"
    end

    @info "setup complete"

    @time network_info!(ndf, mods);

    return ndf
end

export networkinfo

function addgraphs!(ndf, gcx)
    Threads.@threads for arw in eachrow(ndf)
        tpl = (
            village_code = arw[:village_code],
            relationship = arw[:relation],
            wave = arw[:wave]
        )

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

- `mods` requires complex input that isn't really set up yet
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
        if !isnothing(mods) > 0
            for v in mods
                k = Symbol("modularity_" * string(v))
                arw[k] = modularity(arw[:graph], arw[v])
            end
        end
    end
end

export network_info!

"""
        grouppartition!(ndf, rr, v)


## Details

`ndf` is a networkinfo DataFrame, with `names` and `village_code` populated.

Create a partition vector from `names` in `ndf` over characteristic `v`, using input information `cr`.

For use with modularity calculation. N.B. further post processing likely required to coerce values into consecutive and distinct integers for groups.
"""
function grouppartition!(ndf, rr, v, unitname)

    crv = unique(rr[!, [unitname, v]]; view = true)
    crv = Dict(crv[!, unitname] .=> crv[!, v])

    et = eltype(rr[!, v])
    
    ndf[!, v] = Vector{Vector{et}}(undef, nrow(ndf));
    for (i, e) in enumerate(ndf.names)
        ndf[i, v] = missings(Bool, length(e))
    end
    
    for r in eachrow(ndf)
        for (j, n) in enumerate(r[:names])
            x = get(crv, n, missing)
            r[v][j] = x
        end
    end
end

export grouppartition!

"""
join_ndf_df!(df, ndf; name = :name)

## Description

Join network info DataFrame `ndf` to respondent-level DataFrame `df`. This is not a simple join because `ndf` must be row-expanded as it is joined.

`ndf` should be filtered appropriately to the same number of waves, and no more than one relationship.
"""
function join_ndf_df!(df, ndf; name = :name, node_fund = node_fund)
    # preallocate in df
    for (k, _) in node_fund
        df[!, k] = missings(Float64, nrow(df))
    end

    for (k, _) in g_fund
        df[!, k] = missings(Float64, nrow(df))
    end

    join_ndf_df!(df, ndf, name)
end

function join_ndf_df!(df, ndf, name)

    if (length∘unique)(ndf.relation) > 1
        error("only one relationship type allowed")
    end

    # or subset
    sndf = ndf
    sdf = @views df[!, [:village_code, name, [k for k in keys(node_fund)]...]];

    # one person
    Threads.@threads for i in 1:nrow(sdf)
        ville = sdf.village_code[i]
        vgr = sdf[i, name]
        # r = sdf.relation[i];
        
        # (sndf.relation .== r) .& 
        rw = findfirst(sndf.village_code .== ville);
        if !isnothing(rw)
            srw = findfirst(sndf.names[rw] .== vgr);

            if !isnothing(srw)
                for (k, _) in node_fund
                    sdf[i, k] = sndf[rw, k][srw]
                end
            end
        end
    end
end

export join_ndf_df!

"""
join_ndf_cr!(
    df, ndf; name = :perceiver, rels = ["free_time", "personal_private"]
)

## Description

Join ndf network info DataFrame to `cr` CSS DataFrame.
"""
function join_ndf_cr!(
    df, ndf; name = :perceiver, rels = ["free_time", "personal_private"]
)

    for r in rels
        # or subset
        sndf = @views ndf[ndf.relation .== r, :];
        sdf = @views df[df.relation .== r, [:village_code, name, [k for k in keys(node_fund)]...]];

        # one person
        Threads.@threads for i in 1:nrow(sdf)
            ville = sdf.village_code[i]
            vgr = sdf[i, name]
            # r = sdf.relation[i];
            
            # (sndf.relation .== r) .& 
            rw = findfirst(sndf.village_code .== ville);
            if !isnothing(rw)
                srw = findfirst(sndf.names[rw] .== vgr);

                if !isnothing(srw)
                    for (k, _) in node_fund
                        sdf[i, k] = sndf[rw, k][srw]
                    end
                end
            end

        end
    end
end

export join_ndf_cr!

function pairdiff!(crj, v)
    voutname = Symbol(string(v) * "_diff")
    crj[!, voutname] = missings(Float64, nrow(crj))
    for (i, c) in enumerate(crj[!, v])
        crj[i, voutname] = if ismissing(c)
            missing
        else
            abs(c[1] - c[2])
        end
    end
end

export pairdiff!

function pairmean!(crj, v)
    voutname = Symbol(string(v) * "_mean")
    crj[!, voutname] = missings(Float64, nrow(crj))
    for (i, c) in enumerate(crj[!, v])
        crj[i, voutname] = if ismissing(c)
            missing
        else
            (c[1] + c[2]) * inv(2)
        end
    end
end

export pairmean!

"""
        addnetworkdata!(df, ndf)

## Description

Add the network data.
"""
function addnetworkdata!(df, ndf)
    # preallocated in css
    for (k, _) in node_fund
        df[!, k] = missings(Float64, nrow(df))
    end

    for (k, _) in g_fund
        df[!, k] = missings(Float64, nrow(df))
    end

    join_ndf_cr!(df, ndf; rels = ["free_time", "personal_private"]);
end;

export addnetworkdata!
