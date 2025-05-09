# stage2_figure.jl

"""

        stage2_figure()

## Description

Plot marginal effects from second-stage models.
"""
function stage2_figure(
    ef2;
    savefig = false,
    yr = :riddle,
    xr = :response,
    fg = Figure(size = (800, 600))
)
    
    # plot parameters
    opacity = 0.4; # for CI band
    pos = [[1,1], [1,2], [2,1], [2,2]];
    ls = [];

    for p_ in pos
        lo = fg[p_...] = GridLayout()
        push!(ls, lo)
    end

    # fix colors, and transparency
    # also x and ylim

    gdfs = [groupby(df, :outcome) for df in ef2];
    kys = keys(gdfs[1]);

    ax1 = [];

    for (ky, lo) in zip(kys, ls)

        xlabel = "accuracy"

        ax1 = lo[1, 1] = Axis(
            fg;
            ylabel = string(yr) * " knowledge", xlabel,
        );

        ax2 = lo[1, 1] = Axis(
            fg,
            xlabel = "J statistic",
            xaxisposition = :top,
            # title = string(ky[:outcome])
        )

        linkyaxes!(ax1, ax2)

        es = [gdf[(outcome = ky[:outcome],)] for gdf in gdfs];

        ext = extrema(reduce(vcat, [e[!, xr] for e in es[1:2]]))
        xlims!(ax1, ext)

        extj = extrema(es[3][!, xr])
        xlims!(ax2, extj)

        for (df, type) in zip(es, ["tpr", "fpr", "j"])

            # pull data
            x = df[!, xr];
            y = df[!, yr];
            yl, yu = df[!, :lower], df[!, :upper];

            label, c = if type == "tpr"
                "true positive", wc[5]
            elseif type == "fpr"
                "true negative", wc[6]
            elseif type == "j"
                "youden's J", wc[3]
            end

            ax_ = ifelse(type == "j", ax2, ax1)

            lines!(ax_, x, y; label, color = c)
            band!(ax_, x, yl, yu; color = (c, opacity))
        end
    end

    # legend
    ll = ls[end]

    elems = [
        [
            PolyElement(
                color = (c, opacity); strokecolor = :black, strokewidth = 0),
            LineElement(color = c)
        ] for c in wc[[5,6,3]]
    ];

    Legend(
        ll[1, 1], elems,
        ["true positive", "true negative", "Youden's J"],
        "rate",
        framevisible = false,
        tellheight = false, tellwidth = false,
        nbanks = 1
    )

    for lo in ls[1:(end-1)]
        colsize!(lo, 1, Aspect(1, 1.0))
    end

    labelpanels!(ls[1:(end-1)])

    colsize!(fg.layout, 1, Aspect(1, 1.0))
    colsize!(fg.layout, 2, Aspect(1, 1.0))

    resize_to_layout!(fg)

    caption = "Riddle knowledge. Second-stage regression results of the effect of accuracy on knowledge of exogenously introduced riddles related to knowledge of three public health interventions related to (A) zinc usage, (B) umbilical cord care, and (C) prenatal care. N.B. that the second-stage results only display the estimated marginal means over the range of predicted values observed (estimated) in the first stage model.";

    if savefig
        savemdfigure(prj.pp, prj.css, "riddle-stage-2", caption, fg)
    end
    fg    
end

export stage2_figure

"""

        stage2_figure()

## Description

Plot marginal effects from second-stage models.
"""
function stage2_figure(
    ef2, eos;
    savefig = false,
    yr = :riddle,
    xr = :response,
    fg = Figure(size = (800, 600))
)
    
    # plot parameters
    opacity = 0.4; # for CI band
    pos = [[1,1], [1,2], [2,1], [2,2]];
    ls = [];

    for p_ in pos
        lo = fg[p_...] = GridLayout()
        push!(ls, lo)
    end

    # fix colors, and transparency
    # also x and ylim

    gdfs = [groupby(df, :outcome) for df in ef2];
    ptiles = sunique(eos.dist)
    gdfs2 = groupby(eos, :outcome)
    
    kys = keys(gdfs[1]);

    ax1 = [];

    for (ky, lo) in zip(kys, ls)

        xlabel = "accuracy"

        ax1 = lo[1, 1] = Axis(
            fg;
            ylabel = string(yr) * " knowledge", xlabel,
        );

        ax2 = lo[1, 1] = Axis(
            fg,
            xlabel = "J statistic",
            xaxisposition = :top,
            # title = string(ky[:outcome])
        )

        linkyaxes!(ax1, ax2)

        ky2 = (outcome = ky[:outcome],);

        es = [];
        for gdf in gdfs
            push!(es, gdf[ky2])
        end

        ext = extrema(reduce(vcat, [e[!, xr] for e in es[1:2]]))
        xlims!(ax1, ext)

        extj = extrema(es[3][!, xr])
        xlims!(ax2, extj)

        for (df, type) in zip(es, ["tpr", "fpr", "j"])

            # pull data
            x = df[!, xr];
            y = df[!, yr];
            yl, yu = df[!, :lower], df[!, :upper];

            label, c = if type == "tpr"
                "true positive", wc[5]
            elseif type == "fpr"
                "true negative", wc[6]
            elseif type == "j"
                "youden's J", wc[3]
            end

            ax_ = ifelse(type == "j", ax2, ax1)

            lines!(ax_, x, y; label, color = c)
            band!(ax_, x, yl, yu; color = (c, opacity))

            if type == "tpr"
                gs_ = groupby(gdfs2[ky2], :dist)
                for (pt, q) in zip(ptiles, [0.0, 0.25, 0.5, 0.75, 1.0])
                    e = gs_[(dist = pt,)]
                    x_ = e[!, xr]
                    y_ = e[!, yr]
                    lines!(
                        ax_, x_, y_;
                        label, color = berlin[q], linestyle = :dot
                    )
                end
            end
        end
    end

    # legend
    ll = ls[end]

    elems1 = [
        [
            PolyElement(
                color = (c, opacity); strokecolor = :black, strokewidth = 0),
            LineElement(color = c)
        ] for c in wc[[5,6,3]]
    ];

    labs1 = ["true positive", "true negative", "Youden's J"]

    qts_ = [0.1, 0.25, 0.5, 0.75, 0.9];

    elems2 = [
        [
            PolyElement(
                color = (c, opacity); strokecolor = :black, strokewidth = 0
            ),
        ] for c in berlin[qts_]
    ];

    labs2 = string.(qts_);

    Legend(
        ll[1, 1],
        [elems1, elems2],
        [labs1, labs2],
        ["rate", "quantile"],
        framevisible = false, tellheight = false, tellwidth = false,
        nbanks = 2
    )

    for lo in ls[1:(end-1)]
        colsize!(lo, 1, Aspect(1, 1.0))
    end

    labelpanels!(ls[1:(end-1)])

    colsize!(fg.layout, 1, Aspect(1, 1.0))
    colsize!(fg.layout, 2, Aspect(1, 1.0))

    resize_to_layout!(fg)

    caption = "Riddle knowledge. Second-stage regression results of the effect of accuracy on knowledge of exogenously introduced riddles related to knowledge of three public health interventions related to (A) zinc usage, (B) umbilical cord care, and (C) prenatal care. N.B. that the second-stage results only display the estimated marginal means over the range of predicted values observed (estimated) in the first stage model. Dotted lines represent quantiles [0.1, 0.25, 0.5, 0.75, 0.9] of the distance between a perceiver and a tie. Perceiver-tie distance is explicitly varied due to its effect size, and since the observed (first-stage estimated) range of accuracies differs meaningfully from that of the mean estimate. The range of observed accuracies for the true positive rate. Note that the true positive rate only dips below 50% at the 90th percentile.";

    if savefig
        savemdfigure(prj.pp, prj.css, "riddle-stage-2-dist-qte", caption, fg)
    end
    fg 
end
