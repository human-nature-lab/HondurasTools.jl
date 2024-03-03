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
    lo, sbar; kin = :kin431, nlevels = 10, colormap = :berlin
)

    # bivariate density kernels
    sbar.dens = Vector{BivariateKDE}(undef, nrow(sbar));
    for i in 1:nrow(sbar)
        sbar.dens[i] = kde((sbar.type1[i], sbar.tpr[i]))
    end

    # one color range for all four plots (extrema over all densities)
    lv = range(
        extrema(reduce(vcat, [x.density for x in sbar.dens]))...;
        length = nlevels
    );
        
    axs = []

    # positions for each type
    pdict = Dict(
        ("free_time", false) => (1, 1),
        ("free_time", true) => (2, 1),
        ("personal_private", false) => (1, 2),
        ("personal_private", true) => (2, 2)
    )

    psx = Any[];
    for i in 1:nrow(sbar)
        ps = pdict[(sbar.relation[i], sbar[i, kin])]
        ax = Axis(
            lo[ps...];
            ylabel = "True positive rate",
            xlabel = "False positive rate",
            xgridvisible = false, ygridvisible = false,
            title = replace(unwrap(sbar.relation[i]), "_" => " "),
            yticks = [0, 0.25, 0.5, 0.75, 1],
            xticks = [0, 0.25, 0.5, 0.75, 1]
        )

        push!(axs, ax)
        push!(psx, ps)
    end

    axs[3].ylabel = ""
    axs[4].ylabel = ""
    axs[1].xlabel = ""
    axs[3].xlabel = ""
    axs[2].title = ""
    axs[4].title = ""

    Label(
        lo[1, 2, Right()], "kin",
        rotation = -π/2,
        font = :bold,
        padding = (5, 0, 0, 0)
    )

    Label(
        lo[2, 2, Right()], "non-kin",
        rotation = -π/2,
        font = :bold,
        padding = (5, 0, 0, 0)
    )
  
    cos = [];

    (r, ax) = collect(zip(eachrow(sbar), axs))[1];

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
        scatter!(ax, r.accuracy; color = oi[4])
        scatter!(ax, r.accuracy_unadj; color = :black)
        
        ylims!(ax, -0.02, 1.02)
        xlims!(ax, -0.02, 1.02)
    end

    ylims!(axs[1], -0.02, 1.02)
    xlims!(axs[1], -0.02, 1.02)

    linkaxes!(axs...)

    Colorbar(
        lo[3, 1];
        limits = extrema(lv), colormap,
        flipaxis = false, vertical = false,
        label = "Density"
    )

    group_color = [
        MarkerElement(;
            color, strokecolor = :transparent, marker = :circle
        ) for color in [:black, oi[4]]
    ]

    color_leg = ["Yes", "No"];
    leg_titles = ["Adjusted"];

    Legend(
        lo[3, 2],
        [group_color],
        [color_leg],
        leg_titles,
        tellheight = false, tellwidth = false,
        orientation = :horizontal,
        titleposition = :left,
        nbanks = 1, framevisible = false
    )

    # set equal axes
    colsize!(lo, 1, Aspect(1, 1.0))
    colsize!(lo, 2, Aspect(1, 1.0))
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
