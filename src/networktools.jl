# networktools.jl

"""
        reciprocated(con)

Add a column indicating whether tie is recipricated. In constrast to using
non-unique, this marks both directions.

"""
function reciprocated(con)
    df = select(con, [:ego, :alter, :relationship, :village_code, :wave]);
    sortedges!(df.ego, df.alter)
    nu = df[nonunique(df), :]; # one of every duplicate
    nu2 = deepcopy(nu);
    rename!(nu2, :ego => :a, :alter => :ego)
    rename!(nu2, :a => :alter)
    append!(nu, nu2)
    nu[!, :reciprocated] .= true; # both directions (both are true for duplicated entries under ego-alter sort)

    # match duplicated entries to each direction present in the con data
    con = leftjoin(con, nu, on = [:ego, :alter, :relationship, :village_code, :wave]);
    con.reciprocated[ismissing.(con.reciprocated)] .= false
    disallowmissing!(con, :reciprocated)
    return con
end

# network level
function initialize_networks_info() 
    gf = DataFrame(:village_code => Int[], :relationship => String[]);
    gf.nv = Int[];
    gf.ne = Int[];
    gf.global_clustering_coef = Float64[];
    gf.cliques = Vector{Union{Vector{BitSet}, Missing}}();
    gf.label_prop = Tuple{Vector{Int64}, Vector{Int64}}[];

    nfs = DataFrame();

    nd = DataFrame(
        :alter1 => String[], :alter2 => String[],
        :village_code => Int[], :relationship => String[],
        :distance => Float64[]
    );
    
    return nfs, gf, nd
end

# need to add kin; union
function networksinfo!(nfs, gf, css_villages, relationships)
    for w in [1, 3, 4], i in css_villages, (rel, directed) in relationships
        # w = 4
        # i = 152
        # rel = "free_time"

        # @show(w, i, rel, directed)

        cgw = @views con[(con.wave .== w), :];
        cwi = cgw[cgw.village_code .== i, :];
        cwig = cwi[cwi.relationship .== rel, :];

        cwig = unique(cwig[!, [:ego, :alter, :village_code, :wave]]) # questions not unqique for directed

        gt = graphtable( # new object, inefficient
            cwig; ego = :ego, alter = :alter,
            directed = directed, edgedata = true
        )
        # add wave and relationship information
        gt.nf.wave .= w;
        gt.nf.relationship .= rel;
        
        # node reductions
        nodemeasure!(gt, degree_centrality; normalize = false, on = :vertex)
        nodemeasure!(gt, betweenness_centrality; normalize = true, on = :vertex)
        nodemeasure!(gt, closeness_centrality; normalize = true, on = :vertex)
        # nodemeasure!(gt, eigenvector_centrality; on = :vertex)
        nodemeasure!(gt, local_clustering_coefficient; on = :vertex)
        nodemeasure!(gt, triangles; on = :vertex)

        append!(nfs, gt.nf)

        cp = if !directed
            clique_percolation(gt.g, k=3)
        else
            missing 
        end
        
        # network level
        push!(
            gf,
            [
                i, string(rel),
                nv(gt.g), ne(gt.g),
                global_clustering_coefficient(gt.g),
                cp,
                label_propagation(gt.g)
            ]
        );
    end
end

function nodedistances!(nd, css_villages, relationships)
    
    for w in [1, 3, 4], i in css_villages, (rel, directed) in relationships
        # w = 4
        # i = 152
        # rel = "free_time"

        # @show(w, i, rel, directed)

        cgw = @views con[(con.wave .== w), :];
        cwi = cgw[cgw.village_code .== i, :];
        cwig = cwi[cwi.relationship .== rel, :];

        cwig = unique(cwig[!, [:ego, :alter, :village_code, :wave]]) # questions not unqique for directed

        gt = graphtable( # new object, inefficient
            cwig; ego = :ego, alter = :alter,
            directed = directed, edgedata = true
        )
        # add wave and relationship information
        gt.nf.wave .= w;
        gt.nf.relationship .= rel;
        vtx = gt.nf.name;
        
        # node reductions
        n = nv(gt.g)
        # nl = Int((n*(n-1))/2)
        fill!(dists, 0)
        D = Matrix{Int}(undef, n, n)
        
        _distances!(D, gt.g, n)
        _distances_add!(nd, D, gt.g, vtx, i, rel)
    end

    nd.distance[nd.distance .> 10000.0] .= NaN        
    return dists, a1, a2
end

function _distances!(D, g, n)
    for i in 1:n
        D[:, i] = dijkstra_shortest_paths(g, i).dists
    end
end

function _distances_add!(nd, D, g, vtx, v, rel)
    for i in 1:nv(g), j in 1:nv(g)
        if i < j
            a1, a2 = sort([vtx[i], vtx[j]])
            push!(nd, [a1, a2, v, rel, D[i,j]])
        end
    end
end