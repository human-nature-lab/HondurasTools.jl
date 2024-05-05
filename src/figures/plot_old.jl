# effectsplot_old.jl

function effplot_cat!(
    layout, bf, vbl, varname, jstat; legend = true, axiskwargs...
)

    _mrgl = select(mrgl, unique([kin, vbl, :response, :ci, :rate]))
    
    # if J statistic, add it to `marginslong`
    if jstat
        _mrg = select(margins, [kin, vbl, :j, :ci_j])
        _mrg.rate .= :j
        rename!(_mrg, :j => :response, :ci_j => :ci)
        mrgl = vcat(_mrgl, _mrg)
    end

    mrg_nk = @subset mrgl .!$kin
    mrg_nk[!, vbl] = categorical(string.(mrg_nk[!, vbl]))

    lvls = string.(levels(mrg_nk[!, vbl]))
    lvls = replace.(lvls, "_" => " ")

    statnum = ifelse(!jstat, 2, 3)

    xticks = (
        mean(1:statnum):statnum:(statnum*length(levels(mrg_nk[!, vbl]))),
        lvls
    )

    ax = Axis(
        layout[1, 1];
        xticks,
        ylabel = "Rate",
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

    sort!(mrg_nk, unique([vbl, kin]))
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

    if !jstat & legend
        elems = [
            [
                LineElement(; color = c),
                MarkerElement(;
                    marker = :circle, color = c, strokecolor = :transparent
                )
            ] for c in oi[5:6]
        ]

        EffectLegend!(layout[1, 2], elems)
    elseif legend
        elems = [
            [
                LineElement(; color),
                MarkerElement(;marker = :circle, color, strokecolor = :transparent)
            ] for color in oi[[5, 6, 2]]
        ]

        Legend(
            layout[1, 2],
            elems, ["TPR", "TNR", "J"], "Accuracy",
            framevisible = false, orientation = :vertical,
            tellheight = false, tellwidth = false, nbanks = 1
        )        
    end

    return ax
end

export effplot_cat!

function effplot_cts!(
    layout, bpd, tnr, jstat;
    limitx = true, dotlegend = false,
    fpronly = false,
    legend = true,
    kinonly = true, # does not really work, only for special case
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
        ylabel = "Rate",
        xlabel = varname,
        axiskwargs...
    )

    sort!(mrg_nk, vbl)
    mrg_nk.color = ifelse.(mrg_nk[!, :verity], oi[5], oi[6])

    vervals = sunique(mrg_nk[!, :verity])

    nk = if kinonly
        @subset margins .!$kin
    else margins
    end

    for (r, clr) in zip(rates, [oi[5], oi[6]])
        if (r == :fpr) | ((r == :tpr) & !fpronly) 
            
            rci = Symbol("ci_" * string(r))

            xs = nk[!, vbl]
            rs = nk[!, r]
            lwr = [x[1] for x in nk[!, rci]]
            upr = [x[2] for x in nk[!, rci]]

            if r == :fpr
                rs = 1 .- rs
                lwr = 1 .- lwr
                upr = 1 .- upr
            end

            band!(ax, xs, lwr, upr; color = (clr, 0.6)) # no method for tuples
            lines!(ax, xs, rs, color = clr)
        end
    end

    if !jstat & legend
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
        jdf = margins[!, [kin, vbl, :j, :ci_j]]

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
        jpd = (x = jdf[!, vbl], y = jdf[!, :j], lwr = a, upr = b,)

        if !fpronly
            band!(ax2, jpd.x, jpd.lwr, jpd.upr; color = (oi[2], 0.3))
            lines!(ax2, jpd.x, jpd.y; color = oi[2])
        end

        pal = tuple.(oi[[5, 6, 2]], [0.6, 0.6, 0.3])

        if legend
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

            if !fpronly
                Legend(
                    layout[1, 2],
                    elems,
                    ["TPR", "TNR", "J"],
                    "Accuracy",
                    framevisible = false, orientation = :vertical,
                    tellheight = false, tellwidth = false, nbanks = 1
                )
            else
                Legend(
                    layout[1, 2],
                    [elems[2]],
                    ["TNR"],
                    "Accuracy",
                    framevisible = false, orientation = :vertical,
                    tellheight = false, tellwidth = false, nbanks = 1
                )
            end
        end
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
        ylabel = "Rate",
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

###

function rocplot!(
    layout, margins, vbl, varname;
    markeropacity = nothing,
    ellipse = false,
    ellipsecolor = (:grey, 0.3),
    legend = true,
    roctitle = true,
    kinmarker = true,
    kinlegend = true
)

    legargs = (framevisible = false, tellheight = false, tellwidth = false,)

    vbltype = eltype(margins[!, vbl])
    cts = (vbltype <: AbstractFloat) | (vbltype <: Int)

    if isnothing(markeropacity)
        markeropacity = ifelse(cts, 0.5, 1.0)
    end

    margins.color = if !cts
        margins[!, vbl] = categorical(string.(margins[!, vbl])) # make string regardless
        [oi[levelcode(x)] for x in margins[!, vbl]]
    else
        rangescale = extrema(margins[!, vbl])
        get(colorschemes[:berlin], margins[!, vbl], rangescale);
    end;

    if kinmarker
        margins.marker = ifelse.(margins[!, kin], :cross, :rect);
    else
        margins.marker .= :rect
    end
    
    ax = Axis(
        layout[1, 1];
        xlabel = "False positive rate", ylabel = "True positive rate",
        # aspect = 1
        height = 250, width = 250,
        title = ifelse(roctitle, string(varname), "")
    )

    # line of chance
    chanceline!(ax);
    improvementline!(ax);
    
    xlims!(ax, 0, 1)
    ylims!(ax, 0, 1)
    
    # (optionally) plot confidence ellipse
    if ellipse
        jdf = margins[!, [:tpr, :fpr, :Σ]]

        for (fp, tp, Σ) in zip(jdf.fpr, jdf.tpr, jdf.Σ)
            poly!(
                Point2f.(zip(getellipsepoints(Point(fp, tp), Σ)...,));
                color = ellipsecolor
            )
        end
    end

    # plot the data
    scatter!(
        ax,
        margins[!, :fpr], margins[!, :tpr],
        color = [
            (x, markeropacity) for x in margins.color];
            marker = margins.marker, markersize = 8
    )

    if legend
        # legend: variable/color
        roc_legend!(
            layout, margins[!, vbl], varname, ellipse, ellipsecolor, cts;
            kinlegend,
            legargs...
        )
    end
    
    return ax
end

export rocplot!

"""
`bf`: combined (TPR, FPR) marginal effects
"""
function rocplot!(
    layout, bf, vbl, varname;
    markeropacity = nothing,
    ellipse = false,
    ellipsecolor = (:grey, 0.3),
    legend = true,
    roctitle = true,
    kinlegend = true
)

    bf = deepcopy(bf);

    legargs = (framevisible = false, tellheight = false, tellwidth = false,);

    vbltype = eltype(bf[!, vbl])
    cts = (vbltype <: AbstractFloat) | (vbltype <: Int)

    if isnothing(markeropacity)
        markeropacity = ifelse(cts, 0.5, 1.0)
    end

    bf.color = if !cts
        bf[!, vbl] = categorical(string.(bf[!, vbl])) # make string regardless
        [oi[levelcode(x)] for x in bf[!, vbl]]
    else
        rangescale = extrema(bf[!, vbl])
        get(colorschemes[:berlin], bf[!, vbl], rangescale);
    end;

    # if it is not the margin variable
    if ("kin431" ∈ names(bf)) & (vbl != :kin) & (vbl != :kin431)
        bf.marker = ifelse.(bf[!, kin], :cross, :rect);
    else
        bf.marker .= :rect
    end
    
    ax = Axis(
        layout[1, 1];
        xlabel = "False positive rate", ylabel = "True positive rate",
        # aspect = 1
        height = 250, width = 250,
        title = ifelse(roctitle, string(varname), "")
    )

    # line of chance
    chanceline!(ax);
    improvementline!(ax);
    
    xlims!(ax, 0, 1)
    ylims!(ax, 0, 1)
    
    # (optionally) plot confidence ellipse
    if ellipse
        jdf = bf[!, [:tpr, :fpr, :Σ]]

        for (fp, tp, Σ) in zip(jdf.fpr, jdf.tpr, jdf.Σ)
            poly!(
                Point2f.(zip(getellipsepoints(Point(fp, tp), Σ)...,));
                color = ellipsecolor
            )
        end
    end

    # plot the data
    scatter!(
        ax,
        bf[!, :fpr], bf[!, :tpr],
        color = [
            (x, markeropacity) for x in bf.color];
            marker = bf.marker, markersize = 8
    )

    if legend
        # legend: variable/color
        roc_legend!(
            layout, bf[!, vbl], varname, ellipse, ellipsecolor, cts;
            kinlegend,
            legargs...
        )
    end

    colsize!(layout, 1, Auto(3))
    
    return ax
end

export rocplot!

##

function biplotdata(
	bimodel, dats, vbl;
    pbs = nothing,
	varname = nothing,
	invlink = invlink, type = :normal, iters = 1000,
	transforms = nothing, returnpbs = false,
	kinvals = [false, true]
)

	vx = if !isnothing(kinvals)
		[kin, vbl]
	else [vbl]
	end

	effdict = usualeffects(dats, vbl; kinvals)
	refgrids = referencegrid(dats, effdict)
	apply_referencegrids!(bimodel, refgrids; invlink)
	ci!(refgrids)
	for r in refgrids
		sort!(r, vx)
	end
	rgs = deepcopy(refgrids)

	mrg = bidatajoin(rgs)
	truenegative!(rgs)
	mrg_l = bidatacombine(rgs)

	dropmissing!(mrg, vx)
	dropmissing!(mrg_l, vx)

	# add bootstrap info only to the wide `mrg`
	if !isnothing(pbs)
		bs = jboot(
			vbl, bimodel, rgs, pbs, iters; invlink, type,
			confrange = [0.025, 0.975], respvar = :response,
		)
		disallowmissing!(bs)

		# add bootstrap info
		# @assert mrg[!, [:dists_p, :dists_a, kin, vbl]] == bs[!, [:dists_p, :dists_a, kin, vbl]]

		mrg = hcat(mrg, select(bs, setdiff(names(bs), names(mrg))))
	end

	varname = if isnothing(varname)
		replace(string(varname), "_" => " ")
	else
		varname
	end

	# transform margin variable to original range
	if !isnothing(transforms)
		for e in [mrg, mrg_l]
			reversestandards!(e, [vbl], transforms)
		end
	end

	return if !isnothing(pbs) & returnpbs
		(margvar = vbl, margins = mrg, marginslong = mrg_l, dict = effdict, bs = bs, varname = varname)
	else
		(margins = mrg, marginslong = mrg_l, dict = effdict, margvar = vbl, varname = varname)
	end
end

export biplotdata

function biplot!(
	plo,
	bpd;
	jstat = true,
	ellipse = false,
    ellipsecolor = (:grey, 0.3),
	markeropacity = nothing,
	panellabels = false,
	kinlegend = true,
	marginaxiskwargs...,
)

	lroc = plo[1, 1] = GridLayout()
	colsize!(lroc, 1, Relative(4 / 5))
	lef = plo[1, 2] = GridLayout()
	colsize!(lef, 1, Relative(4 / 5))

	rocplot!(
		lroc,
		bpd[:rg], bpd[:margvar], bpd[:margvarname];
		ellipse,
        ellipsecolor,
		markeropacity,
		roctitle = false,
		kinlegend
	)
	
	effectsplot!(
		lef,
		bpd, jstat;
		marginaxiskwargs...,
	)

	if panellabels
		labelpanels!([lroc, lef])
	end

	return plo
end

export biplot!

function biplot(
	vbl, dats, effectsdicts, bimodel, lo, xlabel;
	invlink = identity, markeropacity = nothing,
)

	bpdata = biplotdata(
		bimodel, effectsdicts, dats, vbl; invlink,
	)

	biplot!(lo, bpdata; xlabel, markeropacity)
end

export biplot
