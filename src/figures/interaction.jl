# interaction.jl

function interaction_wealth!(l1, ap, yvar, v, vk)
    x_ext = extrema(ap[!, v]);
    y_ext = extrema(ap[!, yvar.var]);
    y_ext_adj = floor(y_ext[1]; digits = 1), ceil(y_ext[2]; digits = 1);

    ax = Axis(
        l1[1, 1];
        ylabel = yvar.name, xlabel = "Pair household wealth (Avg.)",
        xticks = x_ext[1]:0.1:x_ext[2],
        yticks = y_ext_adj[1]:0.1:y_ext_adj[2],
        width = 250, height = 250
    )

    xlims!(ax, x_ext)
    ylims!(ax, y_ext_adj)
    # lines!(ax, 0:0.1:1, 0:0.1:1; color = :grey, linestyle = :dot)

    for x in xd
        df_ = @subset df $vk .== x;
        lines!(ax, df_[!, v], df_[!, yvar.var]; color = berlin[x])
    end
    Colorbar(
        l1[1, 2], colormap = :berlin,
        label = "Cognizer household wealth", vertical = true
    )
end

export interaction_wealth!
