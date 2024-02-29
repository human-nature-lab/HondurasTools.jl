# accuracy_functions.jl

function nodecolor(x, v)
    return if ismissing(x)
        (:black, 0.001)
    else
        if v == :j_q
            (wc[x+1], 0.90)
        else
            (berlin[x], 0.90)
        end
    end
end

function net_accuracy!(
    ll, i, ndf4; r = :j_ur, clusts = nothing,
    layout = GraphMakie.SFDP(Ptype = Float32, tol = 0.01, C = 0.2, K = 1)
)
    l_ = []

    lo = ll[1, 1] = GridLayout();
    push!(l_, lo)
    
    ax1 = Axis(lo[1, 1], title = "union");
    ax2 = Axis(lo[2, 1], title = "personal private");
    ax3 = Axis(lo[1, 2], title = "free time");
    
    q = if r == :j_ur
        :j
    else
        r
    end

    zp = zip(["union", "personal_private", "free_time"], [ax1, ax2, ax3]);
    for (e, ax) in zp
        ix = findfirst((ndf4.village_code .== i) .& (ndf4.relation .== e))
        g = ndf4[ix, :graph];
        
        node_color = [nodecolor(get_prop(g, i, r), r) for i in 1:nv(g)];
        
        graphplot!(
            ax, g;
            node_color, edge_color = (:black, 0.2),
            node_strokewidth = 0.10, layout
        )
        hidedecorations!(ax)
        # hidespines!(ax)

        if e == "union" # only plot once, just pick one
            ax4 = Axis(lo[2, 2][1,1], xlabel = "cluster", ylabel = "count")

            hh = [get_prop(g, i, q) for i in 1:nv(g)]
            if !all(ismissing.(hh))
                h = (collect∘skipmissing)(hh)
                ch = countmap(h)
                suh = sunique(h)
                barplot!(ax4, suh, [ch[h_] for h_ in suh])
            end
        end
    end
    
    # lmt = if (r == :j) | (r == :j_ur)
    #     (-1, 1)
    # else (0, 1)
    # end

    # Colorbar(
    #     lo[1, 3], limits = lmt,
    #     colormap = :berlin, flipaxis = false,
    #     label = string(r)
    # )

    elems = [
        MarkerElement(
            marker = :circle, color = e,
            strokecolor = :transparent) for e in wc[2:4]
    ]

    push!(
        elems,
        MarkerElement(
            marker = :circle, color = (:black, 0.001),
            strokecolor = :black, strokewidth = 0.1)
        )

    if !isnothing(clusts)
        Legend(lo[2, 2][1,2], elems, vcat(clusts, "missing"), "perceiver accuracy", tellwidth = false)
    end

    Label(ll[0, 1], "village " * string(i), rotation = 0, tellheight = true, tellwidth = false, fontsize = 25)
end

export net_accuracy!
