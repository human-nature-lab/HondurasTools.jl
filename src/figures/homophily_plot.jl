# homophily_plot.jl

function homophily_plot!(l::GridLayout, X)
    opacity = 0.6
    ax = Axis(l[1,1]; xlabel = "Absolute difference in rate", ylabel = "Tie probability")
    ax2 = Axis(l[1,1]; xlabel = "Absolute difference in J", xaxisposition = :top)
    hideydecorations!(ax2)
    linkyaxes!(ax, ax2)
    
    for (x, qr_) in zip(X, [:tpr_ad, :fpr_ad])

        color = if qr_ == :tpr_ad
            oi[5]
        elseif qr_ == :fpr_ad
            oi[6]
        else
            oi[3]
        end

        lines!(ax, x[!, qr_], x.real, label = string(qr_), color = color)
    end

    lines!(ax2, X[3][!, :j_ad], X[3].real, label = string(qr_), color = oi[3])

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

export homophily_plot!