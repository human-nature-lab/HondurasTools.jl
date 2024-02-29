# stress-focus coordinates

using HondurasTools.Distributions

"""
        focuslayout(
            g, v; iter = 500, tol = 0.0001, maxdist = nothing
        )

Generate positions and distances for GraphMakie plot centered around focal node
`v`. Removes nodes that have infinite distance to (are discconnected from) `v`.
"""
function focuslayout(
    g, v; iter = 500, tol = 0.0001, maxdist = nothing, compress = false
)

    # figure weights out later
    # weights = nothing

    # could figure out components out later
    # really, want same component as v
    # comps <- igraph::components(g,"weak")
    # if(comps$no>1){
    # stop("g must be a connected graph.")
    # }
  
    # set seed if want deterministic

    # remove nodes that have infinite distance to focal node
    dtov = fill(Inf, nv(g))
    gdistances!(g, v, dtov) # dijkstra_shortest_paths(g, i).dists
    q = if isnothing(maxdist) | (compress != false)
        isinf.(dtov)
    else
        isinf.(dtov) .| (dtov .> maxdist)
    end

    infs = findall(q);

    println(string(sum(q)) * " removed. " * string(sum(isinf.(dtov))) * " were infinite.")
    
    g2 = deepcopy(g);
    rem_vertices!(g2.graph, infs);

    n = nv(g2)
    D = fill(Inf, n, n)
    for i in 1:n
        gdistances!(g2, i, @views(D[:, i])) # dijkstra_shortest_paths(g, i).dists
    end
    
    W = 1 ./ (D.^2)
    for i in 1:n
        W[i, i] = 0.0
    end

    Z = fill(0, n, n)

    Z[v, :] .= 1
    Z[:, v] .= 1
    Z = W .* Z

    unif = Uniform(-0.1, 0.1)
    rmat = Matrix{Float64}(undef, 2, n)
    for i in eachindex(rmat)
        rmat[i] = rand(unif)
    end

    M = MultivariateStats.fit(
        MultivariateStats.MDS, D; maxoutdim = 2, distances = true
    )

    xinit = rmat + MultivariateStats.predict(M); # jitter

    # xinit <- igraph::layout_with_mds(g) + rmat

    tseq = 0:0.1:1.0;

    # xinitp = Point.(zip(xinit[:,1], xinit[:,2]))

    x = stressfocus(xinit, W, D, Z, tseq, iter, tol);

    offset = x[:, v]
    for i in 1:n
        x[:, i] = x[:, i] - offset
    end

    if !isnothing(maxdist) & (compress != false)
        for (i, pt) in enumerate(eachcol(x))
            odist = origindist(pt, tol)
            a, b = pt
            
            if odist > maxdist 
                _, θ = topolar(a, b)
                ad = if typeof(compress) <: Function
                    compress(odist - maxdist)
                else
                    1
                end
                x[:, i] = tocart(maxdist+ad, θ)
            end
        end
    end

    pos = Vector{Tuple{Float64, Float64}}()
    for e in eachcol(x)
        push!(pos, (e[1], e[2]))
    end

    distance = D[:, v]
    return g2, pos, distance
end

export focuslayout

function stressfocus(
    y::Matrix{Float64},
    W::Matrix{Float64},
    D::Matrix{Float64},
    Z::Matrix{Float64},
    tseq, # vector
    iter::Int,
    tol::Float64
)

    n = size(y, 2);
    x = copy(y)

    wsum = vec(sum(W; dims = 2))
    zsum = vec(sum(Z; dims = 2))

    stress_oldW = stress2(x, D, W)
    stress_old = copy(stress_oldW)
    
    #double stress_oldW = stress(x,W,D);
    # // double stress_oldZ = stress(x,Z,D);
    # double stress_old = stress_oldW;

    for t in tseq
        for _ in 1:iter
            # xnew = Matrix{Float64}(undef, n, 2)
            xnew = fill(0.0, 2, n)
            for (i, ci) in enumerate(eachcol(x))
                for (j, cj) in enumerate(eachcol(x))
                    if (i != j)
                        
                        denom = norm(ci - cj)
    
                        denom = if denom > 0.00001
                            1 / denom
                        else
                            0
                        end

                        xnew[1, i] += updateval(x[1, i], x[1, j], W[i,j], Z[i,j], D[i,j], denom, t)
                        
                        xnew[2, i] += updateval(x[2, i], x[2, j], W[i,j], Z[i,j], D[i,j], denom, t)

                    end
                end
                xnew[1, i] = xnew[1, i] / ((1 - t) * wsum[i] + t * zsum[i]);
                xnew[2, i] = xnew[2, i] / ((1 - t) * wsum[i] + t * zsum[i]);
            end
            stress_newW = stress2(xnew, D, W);
            stress_newZ = stress2(xnew, D, Z);
            stress_new = (1 - t) * stress_newW + t * stress_newZ;

            for i in 1:n
                x[1, i] = xnew[1, i]
                x[2, i] = xnew[2, i]
            end

            eps = (stress_old - stress_new) / stress_old;
            if eps <= tol
                break
            end
            stress_old = stress_new;
        end
    end
    return x
end

function updateval(xi, xj, wij, zij, dij, denom, t)
    return ((1 - t) * wij + t * zij) * (xj + dij * (xi - xj) * denom)
end

"""
Stress function to majorize
Input:
    positions: A particular layout (coordinates in rows)
    d: Matrix of pairwise distances
    weights: Weights for each pairwise distance
See (1) of Reference

from NetworkLayouts.jl
"""
function stress2(positions, d, weights)
    s = zero(eltype(positions))
    n = size(positions, 2)
    @assert n == size(d, 1) == size(d, 2) == size(weights, 1) == size(weights, 2)
    for j in 1:n, i in 1:(j - 1)
        s += weights[i, j] * (norm(positions[:, i] - positions[:, j]) - d[i, j])^2
    end
    @assert isfinite(s)
    return s
end

function origindist(pt, tol)
    round(norm(pt); digits = floor(Int, log10(1/tol)))
end

function topolar(x, y)
    return sqrt(x^2 + y^2), atan(y, x)
end

function tocart(r, θ)
    return [r * cos(θ), r * sin(θ)]
end
