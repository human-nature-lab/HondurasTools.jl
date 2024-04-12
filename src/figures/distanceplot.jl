# distanceplot.jl

"""
		marg_dist_data(de, d, dname, bimodel, dats, invlink)

## Description

Construct data for geodesic distance marginal plots
"""
function marg_dist_data(
	de, d, dname, bimodel, dats, invlink;
	iters = 1000,
	pbs = nothing, transforms = nothing,
	type = :normal,
	returnpbs = false,
)

	effdict = usualeffects(dats, d)
	for r in rates
		effdict[r][de] = 1
	end

	effdict_nopath = deepcopy(effdict)
	for r in rates
		effdict_nopath[r][d] = 0.0
		effdict_nopath[r][de] = 0
	end

	refgrids = referencegrid(dats, effdict)
	apply_referencegrids!(bimodel, refgrids; invlink)

	refgrids2 = referencegrid(dats, effdict_nopath)
	apply_referencegrids!(bimodel, refgrids2; invlink)

	for e in [refgrids, refgrids2]
		ci!(e)
		for r in e
			sort!(r, [kin, de, d])
		end
	end

	rgs = (
		tpr = vcat(refgrids.tpr, refgrids2.tpr),
		fpr = vcat(refgrids.fpr, refgrids2.fpr),
	)

	vbls = [de, d]
	mrg = bidatajoin(rgs)
	truenegative!(rgs)
	mrg_l = bidatacombine(rgs)

	dropmissing!(mrg, [vbls..., kin])
	dropmissing!(mrg_l, [vbls..., kin])

	# add bootstrap info only to the wide `mrg`
	if !isnothing(pbs)
		bs = jboot(
			vbls, bimodel, rgs, pbs, iters; invlink, type,
			confrange = [0.025, 0.975], respvar = :response,
		)
		disallowmissing!(bs)

		# add bootstrap info
		us = sunique([kin, vbls..., :dists_p, :dists_a])
		sort!(mrg, us)
		sort!(bs, us)
		@assert mrg[!, us] == bs[!, us]

		mrg = hcat(mrg, select(bs, setdiff(names(bs), names(mrg))))
	end

	# transform margin variable to original range
	if !isnothing(transforms)
		for e in [mrg, mrg_l]
			reversestandards!(e, [d], transforms)
		end
	end

	return if !isnothing(pbs) & returnpbs
		(
			margins = mrg, marginslong = mrg_l, margvar = d, existvar = de,
			varname = dname, pbs = pbs,
		)
	else
		(
			margins = mrg, marginslong = mrg_l, margvar = d, existvar = de,
			varname = dname,
		)
	end
end

export marg_dist_data

function distance_roc!(
	l, mrg;
	markeropacity = nothing,
	ellipse = false,
	#legend = true,
	fpronly = false
)

	margins, _, d, de, varname = mrg

	margins_finite = @subset(margins, $de)
	margins_notfinite = @subset(margins, .!$de)
	sort!(margins_notfinite, kin)

	ax = rocplot!(
        l, margins_finite, d, varname;
        markeropacity, ellipse, legend = false
    )
    # legend: variable/color
    roc_legend!(
        l, margins_finite[!, d], varname, ellipse, (:grey, 0.3), true,
        extraelement = true
    )
	# add points for no path
	# want a color that stands out from the :berlin color scale
	# and does not cross J
	existcolor = colorschemes[:Anemone][1] # :managua10
	scatter!(
		ax,
		margins_notfinite.fpr, margins_notfinite.tpr;
		marker = [:rect, :cross], color = existcolor,
	)
	return ax
end

export distance_roc!

function distance_eff!(l, mr; jstat = false, fpronly = false, legend = true)
	de = mr.existvar
	mg = deepcopy(mr)
	@subset!(mg.marginslong, .!($kin))
	@subset!(mg.margins, .!($kin))

	# extrema for distance
	mn, mx = extrema(mg.marginslong[!, mr.margvar])

	# set up xticks
	digits = 2
	xtv = round.(Makie.get_tickvalues(WilkinsonTicks(10), identity, mn, mx); digits)
	xtvl = string.(xtv)

	dff = round(diff(xtv)[1]; digits)

	mid1 = (mn + mx) * inv(2)

	mg_ = deepcopy(mg)
	@subset!(mg_.marginslong, $de)
	@subset!(mg_.margins, $de)
	ax = effplot_cts!(
		l, mg_, jstat; dotlegend = true, limitx = false, fpronly, legend
	)

	mg_ = deepcopy(mg)
	select!(mg_.marginslong, Not([:err, :verity]))
	@subset!(mg_.marginslong, .!$de)
	@subset!(mg_.margins, .!$de)
	sort!(mg_.marginslong, :rate)

	if jstat
		us = [
            intersect(names(mg_.marginslong), names(mg_.margins))...,
            "peirce", "ci_j"
        ]

		mj = mg_.margins[!, us]
		rename!(mj, :peirce => :response, :ci_j => :ci)
		mj.rate .= :j
		append!(mg_.marginslong, mj)
	end

	df_ = DataFrame(
		:rate => [:tpr, :fpr, :j], :x => [mx + (i * dff * inv(2)) for i in 1:3],
		:color => [oi[5], oi[6], oi[2]],
	)

	leftjoin!(mg_.marginslong, df_; on = :rate)
	x_, y_, c_, clr = eachcol(mg_.marginslong[!, [:x, :response, :ci, :color]])
	c_ = detuple(c_)

	vlines!(ax, 1; color = :black, linestyle = :dot)
	scatter!(ax, x_, y_; color = clr)
	rangebars!(ax, x_, c_...; color = clr)

	mid2 = (sum ∘ extrema)(mg_.marginslong.x) * inv(2)
	ax.xticks = (xtv, xtvl)

	ax_ = Axis(
		l[1, 1];
		xticks = ([mid1, mid2], ["Yes", "No"]),
		xlabel = "Path exists",
		xaxisposition = :top,
	)
	hideydecorations!(ax_)
	linkxaxes!(ax, ax_)
	xlims!(ax_; low = 0, high = maximum(x_) + (minimum(x_) - mx))
	return ax, ax_
end

export distance_eff!
