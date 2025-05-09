# clustdiff.jl

"""
        clustdiff!(lo, bs_r; saveplot = true)

## Description

Plot cluster assignment patterns for the two different clustering strategies.
"""
function clustdiff!(lo, bs_r; saveplot = true)
    cm = countmap(tuple.(bs_r.j_q, bs_r.r_q));
    ks = String[];
    vs = Int[];
    for (k, v) in cm
        push!(ks, string(k))
        push!(vs, v)
    end
    
    ax = lo[1, 1] = Axis(fg, xticks = (eachindex(vs), ks));
    barplot!(ax, eachindex(vs), vs)

    caption = "Cluster assignment of each node across K-means clustering on Youden's J (first index) and the true positive rate and the true negative rate (jointly, on the two dimensions). Given that more than 3 bars are have significant counts, we infer that the clustering of notes meaningfully changes when we reduce on a 1D vs. a 2D accuracy score. No attempt has been made to verify whether K=3 is a particularly reasonable choice."
    if saveplot
        save_typ(
            "j_plots_mb/" * "cluster_difference.svg", fg;
            caption, label = nothing
        )
    end
    fg
end

export clustdiff!
