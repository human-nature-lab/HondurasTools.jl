# individualpredictions!.jl

function individualpredictions!(
    parent_lo,
    refgrid, refgrids, refgrid_kin, refgrids_kin;
    rates, numlev = 10
)
   
    l1_ = parent_lo[1, 1] = GridLayout();
    l1 = l1_[1:4, 1] = GridLayout();
    l2 = parent_lo[1, 2] = GridLayout();

    colsize!(l2, 1, Aspect(1, 1.0)) # roc-space

    ax1a = Axis(l1[1, 1]; xlabel = "True positive rate");
    ax1b = Axis(l1[2, 1]; xlabel = "False positive rate");
    ax1c = Axis(l1[3, 1]; xlabel = "Youden's J");

    linkaxes!(ax1a, ax1b);

    for (r, ax) in zip(rates, [ax1a, ax1b])
        hist!(ax, refgrids[r][!, :response], bins = 100)
        xlims!(ax, 0, 1)
    end

    for (r, ax) in zip(rates, [ax1a, ax1b])
        hist!(ax, refgrids_kin[r][!, :response], bins = 100, color = oi[2])
        xlims!(ax, 0, 1)
    end

    hist!(ax1c, refgrid[!, :youden], bins = 100)
    hist!(ax1c, refgrid_kin[!, :youden], bins = 100, color = oi[2])
    
    xlims!(ax1c, -1, 1)

    ax2 = Axis(
        l2[1, 1],
        ylabel = "True positive rate",
        xlabel = "False positive rate"
    );

    # line of chance
    lines!(ax2, (0:0.1:1), 0:0.1:1; linestyle = :dot, color = (:black, 0.5))

    # line of improvement
    lines!(ax2, (1:-0.1:0.5), 0:0.1:0.5; linestyle = :solid, color = (oi[6], 0.5))
    lines!(ax2, (0.5:-0.1:0), 0.5:0.1:1; linestyle = :solid, color = (oi[3], 0.5))


    kd = KernelDensity.kde((refgrid.fpr, refgrid.tpr))
    co = contour!(
        ax2, kd, levels = numlev, colormap = :berlin,
    )

    kd_kin = KernelDensity.kde((refgrid_kin.fpr, refgrid_kin.tpr))

    co = contour!(
        ax2, kd_kin, levels = numlev, colormap = :berlin,
    )
    
    ylim = (0.0, 1.0)
    xlim = (0.0, 1.0)

    ylims!(ax2, ylim)
    xlims!(ax2, xlim)

    # legend

    elem1 = MarkerElement(color = oi[1], marker = :circle)
    elem2 = MarkerElement(color = oi[2], marker = :circle)

    Legend(
        l1[4, 1],
        [elem1, elem2],
        ["non-kin", "kin"],
        "(Possible) tie between";
        nbanks = 1,
        framevisible = false,
        valign = :top,
        orientation = :horizontal,
        titleposition = :left
    )

    lv = extrema(kd.density)
    lv_k = extrema(kd_kin.density)

    Colorbar(
        l2[2, 1], limits = lv, colormap = :berlin, flipaxis = true,
        vertical = false, label = "Density (non-kin)"
    )

    Colorbar(
        l2[2, 1], limits = lv_k, colormap = :berlin, flipaxis = false,
        vertical = false, label = "Density (kin)",
    )

    labelpanels!([l1, l2])
    
    colsize!(l1, 1, Relative(0.60))
    rowsize!(l1, 4, Relative(0.0))

    rowgap!(l1, 10)
    colgap!(parent_lo, -50)
end

export individualpredictions!
