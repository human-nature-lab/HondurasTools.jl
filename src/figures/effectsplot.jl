# effectsplot.jl

function effectsplot!(
    l, rg, margvar, margvarname, tnr;
    dropkin = true,
    dotlegend = false,
    dolegend = true,
    axh = 250,
    axw = nothing,
    axiskwargs...
)

    # modify rg if kin are to be dropped
    rg = if dropkin & (string(kin) ∈ names(rg))
        @subset rg .!$kin
    else
        deepcopy(rg)
    end
    vx = intersect(string(kin), [string(margvar)], names(rg))
    sort!(rg, vx)

    vbltype = eltype(rg[!, margvar])
    cts = (vbltype <: AbstractFloat) | (vbltype <: Int)

    # data plot
    func = ifelse(cts, effplot_cts!, effplot_cat!)
    func(l[1, 1], rg, margvar, margvarname, tnr; axw, axh, axiskwargs...)

    # legend
    jstat = "j" ∈ names(rg)
    if dolegend
        effectslegend!(l[1, 2], jstat, cts, dotlegend; tr = 0.6)
        colsize!(l, 2, Auto(0.2))
        colgap!(l, 20)
    end
    
end

export effectsplot!

function effplot_cat!(
    layout, rg, vbl, margvarname, tnr;
    axh = 250,
    axw = 300,
    axiskwargs...
)

    if isnothing(axw)
        axw = 300
    end

    jstat = "j" ∈ names(rg)
    fpronly = any(["tpr", "ci_tpr"] .∉ Ref(names(rg)))

    # in case the variable is not coded properly as a categorical
    # e.g., it may be a binary variable
    rg[!, vbl] = categorical(string.(rg[!, vbl]))
    lvls = string.(levels(rg[!, vbl]))
    lvls = replace.(lvls, "_" => " ")
    rg.lc = levelcode.(rg[!, vbl]);

    statnum = ifelse(!jstat, 2, 3)

    xticks = (
        sunique(rg.lc),
        lvls
    )

    ax = Axis(
        layout;
        xticks,
        ylabel = "Rate",
        xlabel = margvarname,
        height = axh,
        width = axw,
        yticklabelcolor = ratecolor(:tpr) + ratecolor(:fpr),
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
            height = axh,
            width = axw,
            yticklabelcolor = ratecolor(:j),
            axiskwargs...
        )

        # only include y axis ticks, label, ticklabels
        hidespines!(ax_r)
        hidexdecorations!(ax_r)
        linkxaxes!(ax, ax_r)
    end

    vl = sunique(rg[!, :lc])[1:(end-1)] .+ 0.5
    vlines!(ax, vl, color = :black, linestyle = :solid, linewidth = 0.5)

    xshift = ifelse(
        !jstat,
        (tpr = -0.333, fpr = 0.333), (tpr = -0.333, fpr = 0, j = 0.333)
    )

    # plot the data
    for r in [:tpr, :fpr, :j]
        if (string(r) ∉ names(rg)) | fpronly
            continue
        else
            ciname = "ci_" * string(r) |> Symbol
            color = ratecolor(r)
            
            ax_ = if (r == :j) & jstat
                ax_r
            else ax
            end

            xs = rg[!, :lc] .+ xshift[r];
            ys = rg[!, r];
            lwr = [x[1] for x in rg[!, ciname]];
            upr = [x[2] for x in rg[!, ciname]];

            if tnr & (r == :fpr)
                ys = 1 .- ys
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
    layout, rg, margvar, margvarname, tnr;
    tr = 0.4,
    limitx = true,
    axh = 250,
    axw = nothing,
    dropkin = true,
    coloredticks = true,
    axiskwargs...
)

    jstat = "j" ∈ names(rg)
    fpronly = any(["tpr", "ci_tpr"] .∉ Ref(names(rg)))

    tickcolor = if coloredticks
        ratecolor(:tpr) + ratecolor(:fpr)
    else
        :black
    end

    ax = if isnothing(axw)
        Axis(
            layout[1, 1];
            ylabel = "Rate",
            xlabel = margvarname,
            height = axh,
            yticklabelcolor = tickcolor,
            axiskwargs...
        )
    else
        Axis(
            layout[1, 1];
            ylabel = "Rate",
            xlabel = margvarname,
            height = axh,
            width = axw,
            yticklabelcolor = tickcolor,
            axiskwargs...
        )
    end

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
            width = 300,
            yticklabelcolor = ratecolor(:j),
            axiskwargs...
        )

        # only include y axis ticks, label, ticklabels
        hidespines!(ax_r)
        hidexdecorations!(ax_r)
        linkxaxes!(ax, ax_r)
    end

    # plot the data
    
    rt = ifelse(fpronly, [:fpr], [:tpr, :fpr, :j])    

    if ("kin431" ∈ names(rg)) & !dropkin
        gr = groupby(rg, :kin431)
        for (ky, g) in pairs(gr)
            lsty = ifelse(ky.kin431, :dot, :solid)
            
            for r in rt
                ciname = "ci_" * string(r) |> Symbol
                clr = ratecolor(r)
                
                ax_ = if (r == :j) & jstat
                    ax_r
                else ax
                end
        
                xs = g[!, margvar];
                ys = g[!, r];
                lwr = [x[1] for x in g[!, ciname]];
                upr = [x[2] for x in g[!, ciname]];
                
                if tnr & (r == :fpr)
                    ys = 1 .- ys
                    lwr = 1 .- lwr
                    upr = 1 .- upr
                end
        
                lines!(ax_, xs, ys, color = clr, linestyle = lsty)
                band!(ax_, xs, lwr, upr; color = (clr, tr)) # no method for tuples
            end
        end
    else
        for r in rt
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

    return if jstat
        ax, ax_r
    else ax, nothing
    end
end

export effplot_cts!

function effectslegend!(
    layout, jstat, cts, dotlegend;
    fpronly = false,
    tr = 0.6,
    lkwargs = (
        framevisible = false,
        orientation = :vertical,
        tellheight = false,
        tellwidth = false,
        nbanks = 1,
    )
)
    
    rts, rts_names = if fpronly
        ([:fpr], ["TNR"])
    elseif jstat
        ([:tpr, :fpr, :j], ["TPR", "TNR", "J"])
    else
        ([:tpr, :fpr], ["TPR", "TNR"])
    end

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
