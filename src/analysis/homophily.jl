# homophily.jl

function graph_addaccuracy!(ndf, df)
    es = select(df, [:perceiver, :tpr, :fpr, :j]);
    for j in 1:nrow(ndf)
        g = ndf.graph[j]

        gndf = DataFrame(g);
        select!(gndf, :node, :name)
        
        @assert gndf.name == [g[i, :name] for i in 1:nv(g)]

        leftjoin!(gndf, es, on = [:name => :perceiver]);

        @eachrow gndf begin
            set_prop!(g, :node, Symbol("tpr"), :tpr)
            set_prop!(g, :node, Symbol("fpr"), :fpr)
            set_prop!(g, :node, Symbol("j"), :j)
        end
    end
end

export graph_addaccuracy!

function accuracy_node_color!(gdf, measure; trans = 0.8)
    meas = Symbol(string(measure)*"_color")

    y = gdf[!, measure]
    mn,mx = (extrema∘collect∘skipmissing)(y)
    y = (y .- mn) .* inv.(mx - mn)

    gdf[!, meas] = [
        if !ismissing(x)
            (berlin[x], trans)
        else (RGB(1,1,1), 0.0)
        end for x in y
    ]
    return mn, mx
end

export accuracy_node_color!

function accuracyplot!(ll, r, g) 

    ax = Axis(ll[1, 1]);

    gdf = DataFrame(g);

    exts = Tuple[]
    for rx in [:tpr, :fpr, :j]
        mn, mx = accuracy_node_color!(gdf, rx)
        push!(exts, (mn, mx))
    end

    lbl, h = if r == :tpr
        "TPR", 1
    elseif r == :fpr
        "FPR", 2
    elseif r == :j
        "J", 3
    end

    clr = gdf[!, Symbol(string(r)*"_color")]

    hidedecorations!(ax);
    graphplot!(
        ax, g;
        node_color = clr,
        node_stroke_color = :black,
        node_strokewidth = 1.0
    )
    Colorbar(ll[2, 1], limits = exts[h], colormap = :berlin,
    label = lbl, vertical = false, flipaxis = false)
    return ll
end

export accuracyplot!
