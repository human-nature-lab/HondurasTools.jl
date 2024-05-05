# bivariate_perceiver.jl

"""
        perceivercontour!(
            lo, sbar; kin = :kin431, nlevels = 10, colormap = :berlin
        )

## Description

`sbar`: unadjusted subject-level means. should also contain marginal means
estimates from some selected `EModel`.
"""
function perceivercontour!(
    lo, sbar;
    kin = kin,
    nlevels = 10, colormap = :berlin,
    axsz = 250
)

    # bivariate density kernels
    sbar.dens = Vector{BivariateKDE}(undef, nrow(sbar));
    for i in 1:nrow(sbar)
        sbar.dens[i] = kde((sbar.fpr[i], sbar.tpr[i]))
    end

    # one color range for all four plots (extrema over all densities)
    lv = range(
        extrema(reduce(vcat, [x.density for x in sbar.dens]))...;
        length = nlevels
    );
        
    axs = []

    # positions for each type
    # kin on top row, non-kin on bottom
    pdict = Dict(
        ("free_time", true) => (1, 1),
        ("free_time", false) => (2, 1),
        ("personal_private", true) => (1, 2),
        ("personal_private", false) => (2, 2),
    ) |> sort

    psx = Any[];
    for i in 1:nrow(sbar)
        ps = pdict[(sbar.relation[i], sbar[i, kin])]
        title = replace(unwrap(sbar.relation[i]), "_" => " ")
        title = uppercase(title[1]) * title[2:end]
        ax = Axis(
            lo[ps...];
            ylabel = "True positive rate",
            xlabel = "False positive rate",
            xgridvisible = false, ygridvisible = false,
            # title,
            # titlefontsize = 26,
            yticks = [0, 0.25, 0.5, 0.75, 1],
            xticks = [0, 0.25, 0.5, 0.75, 1],
            width = axsz,
            height = axsz
        )

        push!(axs, ax)
        push!(psx, ps)
    end

    axs[3].ylabel = ""
    axs[4].ylabel = ""
    axs[2].xlabel = ""
    axs[4].xlabel = ""

    labelfontsize = 18

    Label(
        lo[1, 2, Right()], "Kin",
        rotation = 0,
        font = :bold,
        fontsize = labelfontsize,
        justification = :right,
        halign = :left,
        padding = (10, 0, 0, 0)
    )

    Label(
        lo[2, 2, Right()], "Non-kin",
        rotation = 0,
        font = :bold,
        fontsize = labelfontsize,
        justification = :left,
        halign = :left,
        padding = (10, 0, 0, 0)
    )
    
    Label(
        lo[1, 1, Top()], "Free time",
        rotation = 0,
        font = :bold,
        fontsize = labelfontsize,
        padding = (0, 0, 10, 0)
    )

    Label(
        lo[1, 2, Top()], "Personal private",
        rotation = 0,
        font = :bold,
        fontsize = labelfontsize,
        padding = (0, 0, 10, 0)
    )
  
    cos = [];

    # same order as axes above...
    for (r, ax) in zip(eachrow(sbar), axs)        
        lines!(ax, 0:0.1:1, 0:0.1:1; linestyle = :dot, color = :grey);
        
        vlines!(ax, [0, 1], color = (:black, 0.3));
        hlines!(ax, [0, 1], color = (:black, 0.3));

        chanceline!(ax);
        improvementline!(ax);

        # distribution
        co = contour!(ax, r.dens; levels = lv, colormap)
        push!(cos, co)

        # marginal means
        # marker = ifelse(!r[kin], :rect, :cross);
        scatter!(ax, (r[:fpr_adj], r[:tpr_adj]); color = oi[4])
        scatter!(ax, r[:fpr_tpr_bar]; color = :black)
        
        ylims!(ax, -0.02, 1.02)
        xlims!(ax, -0.02, 1.02)
    end

    ylims!(axs[1], -0.02, 1.02)
    xlims!(axs[1], -0.02, 1.02)

    linkaxes!(axs...)

    lol = lo[1:2, 3] = GridLayout();

    Colorbar(
        lol[1:2, 1];
        limits = extrema(lv), colormap,
        flipaxis = false, vertical = true,
        label = "Density"
    )

    group_color = [
        MarkerElement(;
            color, strokecolor = :transparent, marker = :circle
        ) for color in [:black, oi[4]]
    ]

    color_leg = ["No", "Yes"];
    leg_titles = ["Adjusted"];

    Legend(
        lol[3, 1],
        [group_color],
        [color_leg],
        leg_titles,
        tellheight = false, tellwidth = false,
        orientation = :vertical,
        # titleposition = :left,
        nbanks = 1, framevisible = false
    )

    # set equal axes
    # colsize!(lo, 1, Aspect(1, 1.0))
    # colsize!(lo, 2, Aspect(1, 1.0))
end

export perceivercontour!

"""

## Description

- `plo`: parent layout
"""
function bivariate_perceiver!(
    plo, sbar; kin = :kin431, nlevels = 12, colormap = :berlin
)

    lxx = plo[1, 1:2] = GridLayout();
    lo = lxx[1, 1] = GridLayout();

    # Panel A, B
    
    los, cos, lo1, lop, lop2, ll = perceivercontour!(
        lo, sbar; kin, nlevels, colormap
    )

    # panel B
    # marginal effects plot
    
    # end legend
    
    labelpanels!([los[[1, 2]]..., l2])
end

export bivariate_perceiver
