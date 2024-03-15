# effectsplot.jl

function EffectLegend!(ll, elems)
    Legend(
        ll[1, 1], elems, ["TPR", "FPR"], "Accuracy", framevisible = false,
        orientation = :vertical,
        tellheight = false, tellwidth = false, nbanks = 1
    )
end

function effectsplot!(
    l, bpd, jstat; axiskwargs...
)

    vbltype = eltype(bpd[:margins][!, bpd[:margvar]])
    cts = (vbltype <: AbstractFloat) | (vbltype <: Int)

    if cts
        effplot_cts!(l, bpd, jstat; axiskwargs...)
    else
        effplot_cat!(l, bpd, jstat; axiskwargs...)
    end
end

export effectsplot!

function effplot_cat!(layout, bpd, jstat; axiskwargs...)

    vbl = bpd.margvar
    mrgl = bpd.marginslong
    margins = bpd.margins
    varname = bpd.varname

    _mrgl = select(mrgl, [kin, vbl, :response, :ci, :rate])
    
    # if J statistic, add it to `marginslong`
    if jstat
        _mrg = select(margins, [kin, vbl, :peirce, :ci_j])
        _mrg.rate .= :j
        rename!(_mrg, :peirce => :response, :ci_j => :ci)
        mrgl = vcat(_mrgl, _mrg)
    end

    mrg_nk = @subset mrgl .!$kin
    mrg_nk[!, vbl] = categorical(string.(mrg_nk[!, vbl]))

    lvls = string.(levels(mrg_nk[!, vbl]))
    lvls = replace.(lvls, "_" => " ")

    statnum = ifelse(!jstat, 2, 3)

    xticks = (mean(1:statnum):statnum:(statnum*length(levels(mrg_nk[!, vbl]))), lvls)

    ax = Axis(
        layout[1, 1];
        xticks,
        ylabel = "Accuracy",
        xlabel = varname,
        height = 250,
        axiskwargs...
    )

    if jstat
        # if j statistic data is included, add point and rangebars
        # make legend that includes J statistic with color oi[7]

        # right axis for J statistic
        ax2 = Axis(
            layout[1, 1];
            xlabel = varname,
            ylabel = "J",
            yaxisposition = :right,
            height = 250,
            axiskwargs...
        )

        # only include y axis ticks, label, ticklabels
        hidespines!(ax2)
        hidexdecorations!(ax2)
        linkxaxes!(ax, ax2)
    end

    @inline ratecolor(x) = if x == :tpr
        oi[5]
    elseif x == :fpr
        oi[6]
    else
        oi[2]
    end

    sort!(mrg_nk, [vbl, kin])
    mrg_nk.color = ratecolor.(mrg_nk[!, :rate])

    vl = ((statnum+0.5):statnum:(statnum*length(levels(mrg_nk[!, vbl]))))[1:end]

    vlines!(ax, vl, color = :black, linestyle = :solid, linewidth = 0.5)

    mrg_nk.lwr = [x[1] for x in mrg_nk[!, :ci]]
    mrg_nk.upr = [x[2] for x in mrg_nk[!, :ci]]
    mrg_nk.xs = 1:nrow(mrg_nk)
    
    gdf = groupby(mrg_nk, :rate)

    for (k, g) in pairs(gdf)
        ax_ = if (k.rate == :j) & jstat
            ax2
        else ax
        end
        scatter!(
            ax_, g.xs, g.response;
            color = g.color
        )
        rangebars!(
            ax_, g.xs, g.lwr, g.upr;
            color = g.color
        )
    end

    if !jstat
        elems = [
            [
                LineElement(; color = c),
                MarkerElement(;
                    marker = :circle, color = c, strokecolor = :transparent
                )
            ] for c in oi[5:6]
        ]

        EffectLegend!(layout[1, 2], elems)
    else
        elems = [
            [
                LineElement(; color),
                MarkerElement(;marker = :circle, color, strokecolor = :transparent)
            ] for color in oi[[5, 6, 2]]
        ]

        Legend(
            layout[1, 2],
            elems, ["TPR", "FPR", "J"], "Accuracy",
            framevisible = false, orientation = :vertical,
            tellheight = false, tellwidth = false, nbanks = 1
        )        
    end

    return ax
end

export effplot_cat!

function effplot_cts!(
    layout, bpd, jstat;
    limitx = true, dotlegend = false,
    axiskwargs...
)

    margins = bpd.margins
    marginslong = bpd.marginslong
    vbl = bpd.margvar
    varname = bpd.varname

    mrg_nk = if !isnothing(kin)
        @subset marginslong .!$kin
    else
        marginslong
    end

    ax = Axis(
        layout[1, 1];
        ylabel = "Accuracy",
        xlabel = varname,
        axiskwargs...
    )

    sort!(mrg_nk, vbl)
    mrg_nk.color = ifelse.(mrg_nk[!, :verity], oi[5], oi[6])

    vervals = sunique(mrg_nk[!, :verity])

    clrs = if vervals == [false, true]
        [5, 6]
    elseif vervals == [true]
        [5]
    elseif vervals == [false]
        [6]
    end
    
    idxs = [mrg_nk.verity .== v for v in vervals]

    for (ix, cx) in zip(idxs, clrs)
        xs = mrg_nk[ix, vbl]
        rs = mrg_nk[ix, :response]
        lwr = [x[1] for x in mrg_nk[ix, :ci]]
        upr = [x[2] for x in mrg_nk[ix, :ci]]
        band!(ax, xs, lwr, upr; color = (oi[cx], 0.6)) # no method for tuples
        lines!(ax, xs, rs, color = oi[cx])
    end

    if !jstat
        elems = []
        for (color, tr) in zip(oi[5:6], [0.6, 0.6])
            x = if dotlegend
                [
                    PolyElement(; color = (color, tr)),
                    LineElement(; color),
                    MarkerElement(; marker = :circle, color)
                ]
            else
                [
                    PolyElement(; color = (color, tr)),
                    LineElement(; color)
                ]
            end
            push!(elems, x)
        end

        EffectLegend!(layout[1, 2], elems)
    else
        # if j statistic data is included, add line and band
        # make legend that includes J statistic with color oi[7]
        jdf = margins[!, [kin, vbl, :peirce, :ci_j]]

        # right axis for J statistic
        ax2 = Axis(
            layout[1, 1];
            xlabel = varname,
            ylabel = "J statistic",
            yaxisposition = :right,
            axiskwargs...
        )

        hidespines!(ax2)
        hidexdecorations!(ax2)
        linkxaxes!(ax, ax2)

        # hlines!(ax2, [0.0], color = :grey, linestyle = :dot)

        if !isnothing(kin)
            jdf = @subset jdf .!$kin
        end
        sort!(jdf, vbl)

        a, b = detuple(jdf.ci_j)
        jpd = (x = jdf[!, vbl], y = jdf[!, :peirce], lwr = a, upr = b,)

        band!(ax2, jpd.x, jpd.lwr, jpd.upr; color = (oi[2], 0.3))
        lines!(ax2, jpd.x, jpd.y; color = oi[2])

        pal = tuple.(oi[[5, 6, 2]], [0.6, 0.6, 0.3])

        elems = []
        for c in pal
            x = if dotlegend
                [
                    PolyElement(; marker = :rect, color = c),
                    LineElement(color = c[1]),
                    MarkerElement(; marker = :circle, color = c)
                ]
            else
                [
                    PolyElement(; marker = :rect, color = c),
                    LineElement(color = c[1])
                ]
            end
            push!(elems, x)
        end

        Legend(
            layout[1, 2],
            elems,
            ["TPR", "FPR", "J"],
            "Accuracy",
            framevisible = false, orientation = :vertical,
            tellheight = false, tellwidth = false, nbanks = 1
        )
    end

    ax_ = if jstat
        ax2
    else ax
    end
    
    if limitx
        xlims!(ax_, extrema(mrg_nk[!, vbl]))
    end

    return ax
end

export effplot_cts!

function effplot_cts_pr!(layout, bpd; axiskwargs...)
    
    vbl = bpd.margvar

    mrg_nk = @subset mrg .!$kin

    ax = Axis(
        layout[1, 1];
        xlabel = bpd.varname,
        ylabel = "Accuracy",
        axiskwargs...
    )

    sort!(mrg_nk, vbl)
    mrg_nk.color = ifelse.(mrg_nk[!, :verity], oi[5], oi[6])

    if sum(mrg_nk.verity) > 0
        for ix in [mrg_nk.verity]
            xs = mrg_nk[ix, vbl]
            rs = mrg_nk[ix, :response]
            lw = mrg_nk[ix, :lower]
            hg = mrg_nk[ix, :upper]
            band!(ax, xs, lw, hg, color = (oi[5], 0.6))
            lines!(ax, xs, rs, color = oi[5])
        end
    end

    if sum(.!mrg_nk.verity) > 0
        for ix in [.!m1_mrg_nk.verity]
            xs = mrg_nk[ix, vbl]
            rs = mrg_nk[ix, :response]
            lw = mrg_nk[ix, :lower]
            hg = mrg_nk[ix, :upper]
            band!(ax, xs, lw, hg, color = (oi[6], 0.6))
            lines!(ax, xs, rs, color = oi[6])
        end
    end

    if !isnothing(layout)
        if sum(mrg_nk.verity) > 0
            elems = [LineElement(color = oi[5])]
                
            EffectLegend!(layout[1, 2], elems)
        end

        if sum(.!mrg_nk.verity) > 0
            elems = [LineElement(color = oi[6])]
                
            EffectLegend!(layout[1, 2], elems)
        end
    end

    xlims!(ax, extrema(mrg_nk[!, vbl]))

    return ax
end

export effplot_cts_pr!
