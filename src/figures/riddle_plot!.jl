# riddle_plot!.jl

function _riddleplot!(ax, z, q, rxs, opacity)
    rx = rxs[z, q]
    color = if q == :tpr
        oi[5]
    elseif q == :fpr
        oi[6]
    else
        oi[3]
    end
    x = ifelse(q != :fpr, rx[!, q], 1 .- rx[!, q]);
    y = rx[!, z];
    lw = rx[!, :lower];
    hg = rx[!, :upper];
    lines!(ax, x, y; color = color)
    band!(ax, x, lw, hg; color = (color, opacity))
end

function riddle_plot!(l::GridLayout, z, rxs)
    opacity = 0.6
    ax = Axis(l[1, 1]; xlabel = "Rate", ylabel = "Riddle knowledge");
    ax2 = Axis(l[1, 1]; xaxisposition = :top, xlabel = "J");
    linkyaxes!(ax, ax2)
    hideydecorations!(ax2)

    for q in [:tpr, :fpr]
        _riddleplot!(ax, z, q, rxs, opacity)
    end

    _riddleplot!(ax2, z, :j, rxs, opacity)
    
    elems = [
        [
            PolyElement(
                color = (c, opacity); strokecolor = :black, strokewidth = 0),
            LineElement(color = c)
        ] for c in wc[[5,6,3]]
    ];

    Legend(
        l[1, 2], elems,
        ["TPR", "TNR", "J"],
        "Accuracy",
        framevisible = false,
        tellheight = false, tellwidth = false,
        nbanks = 1
    )
    colsize!(l, 1, Relative(4/5))
end

export riddle_plot!
