# roc_distance.jl

"""
		distance_roc!(
			layout,
			rg, margvar, margvarname;
			ellipsecolor = (yale.grays[end], 0.3),
			markeropacity = nothing,
			roctitle = true,
			kinlegend = true,
			extramargin = false
		)

## Description

"""
function distance_roc!(
    layout,
    rg, margvar, margvarname;
    ellipsecolor = (yale.grays[end], 0.3),
	ellipsehull = nothing,
    markeropacity = nothing,
    roctitle = true,
    kinlegend = true,
    extramargin = false
)

	# existence variable
	margvar2 = Symbol(string(margvar) * "_notinf")

	ellipse = ifelse("Σ" ∈ names(rg), true, false)
	
	# distance range (has path)
	margins_finite = @subset(rg, $margvar2)
	
	# plot the continuous portion (distance)
	ax = rocplot_!(
		layout, margins_finite, margvar, margvarname;
		markeropacity,
		ellipse,
		ellipsecolor,
		ellipsehull,
		roctitle,
		kinmarker = true,
		axsz = 250,
		extramargin,
	)

	# no path
	margins_notfinite = @subset(rg, .!$margvar2)
	sort!(margins_notfinite, kin)

	# color for point representing effect of no path
	existcolor = columbia.secondary[1]
	cmap = ColorScheme([existcolor])

	mkr = [ifelse(m, :cross, :circle) for m in margins_notfinite[!, kin]]

	# plot the discrete portion (no path)
	scatter!(
		ax,
		margins_notfinite[!, :fpr], margins_notfinite[!, :tpr];
		marker = mkr, color = existcolor,
	)

    # legend: variable/color
	# create partially overlapping color bars
	#
	l_ = layout[1, 2] = GridLayout()
	lx = l_[1:14, 1] = GridLayout()
	yl_ = 14

	# distance range
	rangescale = extrema(margins_finite[!, margvar])

	Colorbar(
		lx[1:yl_, 1];
		limits = (0,1), colormap = :berlin,
		flipaxis = true, vertical = true,
		label = "",
		tellheight = false,
		ticks = ([0.47], ["Path"]),
		ticksvisible = false,
	)

	Colorbar(
		lx[1:yl_, 1];
		limits = (0,1),
		colormap = cmap,
		flipaxis = true, vertical = true,
		label = "",
		tellheight = false,
		ticks = ([0.97], ["No path"]),
		ticksvisible = false,
	)

	Colorbar(
		lx[2:yl_, 1];
		limits = rangescale, colormap = :berlin,
		flipaxis = false, vertical = true,
		label = margvarname,
		tellheight = false,
		#ticksvisible = false,
	)
	
	if kinlegend
		elems = [[
			MarkerElement(;
				marker = m, color = :black, strokecolor = :transparent
			) for m in [:circle, :cross]
		]]
		lvls = [["No", "Yes"]];
		nms = ["Kin tie"]
	else
		elems = [elems]
		lvls = [lvls]
		nms = [varname]
	end
	
	return ax
end

export distance_roc!
