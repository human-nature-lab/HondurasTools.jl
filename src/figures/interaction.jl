# interaction.jl

function interaction_wealth!(l1, ap, yvar, v, vk; fullylim = true)
    x_ext = extrema(ap[!, v]);
    y_ext = extrema(ap[!, yvar.var]);
    y_ext_adj = floor(y_ext[1]; digits = 1), ceil(y_ext[2]; digits = 1);

    yticks = if fullylim
        0:0.2:1
    else
        y_ext_adj[1]:0.1:y_ext_adj[2]
    end

    ax = Axis(
        l1[1, 1];
        ylabel = yvar.name, xlabel = "Pair wealth (mean)",
        xticks = x_ext[1]:0.2:x_ext[2],
        yticks,
        aspect = 1,
        #width = 250,
        height = 250
    )

    xlims!(ax, x_ext)
    if fullylim
        ylims!(ax, 0, 1.0)
    else
        ylims!(ax, y_ext_adj)
    end
    # lines!(ax, 0:0.1:1, 0:0.1:1; color = :grey, linestyle = :dot)

    for x in sunique(ap[!, v])
        df_ = @subset ap $vk .== x;
        lines!(ax, df_[!, v], df_[!, yvar.var]; color = (berlin[x], 0.6))
    end
    Colorbar(
        l1[1, 2], colormap = :berlin,
        label = "Cognizer wealth", vertical = true
    )
end

export interaction_wealth!
