# distanceplot.jl

function distance_eff!(
	layout, rg, margvar, margvarname;
	dropkin = true,
	tnr = true,
	trp = 0.4,
	coloredticks = false,
	axiskwargs...
)

	fpronly = any(["tpr", "ci_tpr"] .∉ Ref(names(rg)))

	# modify rg if kin are to be dropped
	rg = if dropkin & (string(kin) ∈ names(rg))
		@subset rg .!$kin
	else
		deepcopy(rg)
	end
	vx = intersect(string(kin), [string(margvar)], names(rg))
	sort!(rg, vx)

	# existence variable
	margvar2 = Symbol(string(margvar) * "_notinf")

	# distance range (has path)
	rg_fin = @subset(rg, $margvar2)

	# extrema for distance
	mn, mx = extrema(rg_fin[!, margvar])

	# set up xticks

	ax, ax_r = effplot_cts!(
		layout[1, 1], rg_fin, margvar, margvarname, tnr;
		dropkin,
		limitx = false,
		tr = trp,
		coloredticks,
		axiskwargs...
	)

	if fpronly
		ax.ylabel = "True negative rate"
		#ax_r.ylabel = "True negative rate"
	end

	colsize!(layout, 1, Auto(3))

	rg_inf = @subset(rg, .!$margvar2);

	interval = mean(diff(rg_fin[!, margvar]))

	vlines!(ax, mx; color = :black, linestyle = :dot)

	# number of post of no path points, one for each rate mult. by the number
	# of rows (usually one, possibly two for kin)
	nrates = if !fpronly
		sum(["tpr", "fpr", "j"] .∈ Ref(names(rg)))
	else
		nrates = 1
	end

	x_ = fill(NaN, nrow(rg_inf), nrates)
	for i in eachindex(x_)
		x_[i] = mx + interval*i
	end
	
	rt = ifelse(fpronly, [:fpr], [:tpr, :fpr, :j])

	# (r, x) = collect(zip(rt, eachcol(x_)))[1]

	for (r, x) in zip(rt, eachcol(x_))
		x = convert(Vector{AbstractFloat}, x)
		est = rg_inf[!, r]

		mkr = replace(rg_inf.kin431, true => :cross, false => '●')

		ci_name = Symbol("ci_" * string(r))
		lwr = [first(a) for a in rg_inf[!, ci_name]]
		upr = [last(a) for a in rg_inf[!, ci_name]]

		if tnr * (r == :fpr)
			est = 1 .- est
			lwr = 1 .- lwr
			upr = 1 .- upr
		end

		ax_current = if r == :j
			ax_r
		else
			ax
		end

		scatter!(ax_current, x, est; color = ratecolor(r), marker = mkr)
		rangebars!(ax_current, x, lwr, upr; color = ratecolor(r))
	end

	mid1 = (mn + mx) * inv(2)
	mid2 = (sum ∘ extrema)(x_) * inv(2)
	ax_ = Axis(
		layout[1, 1];
		xticks = ([mid1, mid2], ["Yes", "No"]),
		xlabel = "Path exists",
		xaxisposition = :top,
	)
	hideydecorations!(ax_)
	linkxaxes!(ax, ax_)

	xlims!(ax, low = mn)
	xlims!(ax_, low = mn)
	if !isnothing(ax_r)
		xlims!(ax_r, low = mn)
	end

	lll = GridLayout(layout[1, 2])

	jstat = "j" ∈ names(rg)
	
	if !fpronly
		effectslegend!(
			lll[1,1], jstat, true, true;
			fpronly, tr = trp
		)
	end
	if length(unique(rg.kin431)) > 1
		# Create line elements for legend
		solid_line = LineElement(linestyle = :solid, color = :black, linewidth = 2)
		dotted_line = LineElement(linestyle = :dot, color = :black, linewidth = 2)

		# Create legend with custom entries
		leg = Legend(lll[2,1],
			[solid_line, dotted_line],
			["No", "Yes"],
			"Kin tie",
			framevisible = false, valign = :top)

		# Position legend in figure layout
		# lll[2, 1] = leg
	end


	return ax, ax_r
end

export distance_eff!
