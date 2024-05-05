# effectsplot.jl

function effectsplot!(
    l, rg, margvar, margvarname, tnr, jstat;
    dropkin = true, kin = kin, dotlegend = false,
    axiskwargs...
)

    rg = deepcopy(rg)
    if dropkin  & (string(kin) ∈ names(rg))
        @subset! rg .!$kin
    end
    vx = intersect(string(kin), [string(margvar)], names(rg))
    sort!(rg, vx)

    vbltype = eltype(rg[!, margvar])
    cts = (vbltype <: AbstractFloat) | (vbltype <: Int)

    func = ifelse(cts, effplot_cts!, effplot_cat!)
    func(l[1, 1], rg, margvar, margvarname, tnr, jstat; axiskwargs...)
    # Box(l[1,1], color = (:red, 0.3))
    effectslegend!(l[1, 2], jstat, cts, dotlegend; tr = 0.6)
    # Box(l[1,2], color = (:blue, 0.3))
    
    colsize!(l, 2, Auto(0.2))
    colgap!(l, 10)
end

export effectsplot!

function effplot_cat!(
    layout, rg, vbl, margvarname, tnr, jstat;
    axh = 250,
    axiskwargs...
)

    # in case the variable is not coded properly as a categorical
    # e.g., it may be a binary variable
    rg[!, vbl] = categorical(string.(rg[!, vbl]))
    lvls = string.(levels(rg[!, vbl]))
    lvls = replace.(lvls, "_" => " ")

    statnum = ifelse(!jstat, 2, 3)

    xticks = (
        mean(1:statnum):statnum:(statnum*length(levels(mrg_nk[!, vbl]))),
        lvls
    )

    ax = Axis(
        layout;
        xticks,
        ylabel = "Rate",
        xlabel = margvarname,
        height = axh,
        axiskwargs...
    )

    if jstat
        # add secondary axis right for J
        # if j statistic data is included, add point and rangebars
        # make legend that includes J statistic with color oi[7]

        ax_r = Axis(
            layout;
            xlabel = margvarname,
            ylabel = "J",
            yaxisposition = :right,
            height = 250,
            axiskwargs...
        )

        # only include y axis ticks, label, ticklabels
        hidespines!(ax_r)
        hidexdecorations!(ax_r)
        linkxaxes!(ax, ax_r)
    end

    vl = ((statnum+0.5):statnum:(statnum*length(levels(mrg_nk[!, vbl]))))[1:end]

    vlines!(ax, vl, color = :black, linestyle = :solid, linewidth = 0.5)

    # plot the data
    for r in [:tpr, :fpr, :j]
        if (string(r) ∉ names(rg)) | fpronly
            continue
        else
            ciname = "ci_" * string(r) |> Symbol
            color = ratecolor(r)
            
            ax_ = if (r == :j) & jstat
                ax2
            else ax
            end

            xs = rg[!, margvar];
            ys = rg[!, r];
            lwr = [x[1] for x in rg[!, ciname]];
            upr = [x[2] for x in rg[!, ciname]];

            if tnr & (r == :fpr)
                ys = 1 - ys
                lwr = 1 .- lwr
                upr = 1 .- upr
            end

            scatter!(ax_, xs, ys; color);
            rangebars!(ax_, xs, lwr, upr; color)
        end
    end

    return ax
end

export effplot_cat!

function effplot_cts!(
    layout, rg, margvar, margvarname, tnr, jstat;
    tr = 0.6,
    limitx = true, fpronly = false,
    axh = 250,
    axiskwargs...
)

    ax = Axis(
        layout[1, 1];
        ylabel = "Rate",
        xlabel = margvarname,
        height = axh,
        axiskwargs...
    )

    if jstat
        # add secondary axis right for J
        # if j statistic data is included, add point and rangebars
        # make legend that includes J statistic with color oi[7]

        ax_r = Axis(
            layout;
            xlabel = margvarname,
            ylabel = "J",
            yaxisposition = :right,
            height = 250,
            axiskwargs...
        )

        # only include y axis ticks, label, ticklabels
        hidespines!(ax_r)
        hidexdecorations!(ax_r)
        linkxaxes!(ax, ax_r)
    end

    # plot the data
    
    for r in [:tpr, :fpr, :j]
        if (string(r) ∉ names(rg)) | fpronly
            continue
        else
            ciname = "ci_" * string(r) |> Symbol
            clr = ratecolor(r)
            
            ax_ = if (r == :j) & jstat
                ax_r
            else ax
            end

            xs = rg[!, margvar];
            ys = rg[!, r];
            lwr = [x[1] for x in rg[!, ciname]];
            upr = [x[2] for x in rg[!, ciname]];
            
            if tnr & (r == :fpr)
                ys = 1 .- ys
                lwr = 1 .- lwr
                upr = 1 .- upr
            end

            lines!(ax_, xs, ys, color = clr)
            band!(ax_, xs, lwr, upr; color = (clr, tr)) # no method for tuples
        end
    end
    
    if limitx
        xlims!(ax, extrema(rg[!, margvar]))
        if jstat
            xlims!(ax_r, extrema(rg[!, margvar]))
        end
    end

    return ax
end

export effplot_cts!

function effectslegend!(
    layout, jstat, cts, dotlegend;
    tr = 0.6,
    lkwargs = (
        framevisible = false,
        orientation = :vertical,
        tellheight = false,
        tellwidth = false,
        nbanks = 1,
    )
)
    
    rts = ifelse(jstat, [:tpr, :fpr, :j], [:tpr, :fpr]);
    rts_names = ifelse(jstat, ["TPR", "TNR", "J"], ["TPR", "TNR"]);

    elems = [];

    if !cts
        for r in rts
            e = [
                LineElement(; color = ratecolor(r)),
                MarkerElement(;
                    marker = :circle, color = ratecolor(r), strokecolor = :transparent
                )
            ]
            push!(elems, e)
        end

        Legend(
            layout,
            elems, rts_names, "Accuracy";
            lkwargs...
        )
    else
        for r in rts
            x = if dotlegend
                [
                    PolyElement(; color = (ratecolor(r), tr)),
                    LineElement(; color = ratecolor(r)),
                    MarkerElement(; marker = :circle, color = ratecolor(r))
                ]
            else
                [
                    PolyElement(; color = (ratecolor(r), tr)),
                    LineElement(; color = ratecolor(r))
                ]
            end
            push!(elems, x)
        end
        Legend(
            layout, elems, rts_names, "Accuracy";
            lkwargs...
        )
    end
end

# old
function EffectLegend!(ll, elems)
    Legend(
        ll[1, 1], elems, ["TPR", "TNR"], "Accuracy", framevisible = false,
        orientation = :vertical,
        tellheight = false, tellwidth = true, nbanks = 1,
    )
end
