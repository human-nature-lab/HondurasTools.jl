# distanceplot.jl

function distance_eff!(
	layout, rg, margvar, margvarname;
	dropkin = true,
	legend = true,
	tnr = true,
	trp = 0.4,
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

	# existence variable
	margvar2 = Symbol(string(margvar) * "_notinf")

	# distance range (has path)
	rg_fin = @subset(rg, $margvar2)

	# extrema for distance
	mn, mx = extrema(rg_fin[!, margvar])

	# set up xticks
	# digits_ = 2
	# xtv = round.(Makie.get_tickvalues(WilkinsonTicks(10), identity, mn, mx); digits = digits_)
	# xtvl = string.(xtv)

	ax, ax_r = effplot_cts!(
		layout[1, 1], rg_fin, margvar, margvarname, tnr;
		limitx = false,
		tr = trp,
		axiskwargs...
	)

	colsize!(layout, 1, Auto(3))

	rg_inf = @subset(rg, .!$margvar2);

	interval = mean(diff(rg_fin[!, margvar]))

	vlines!(ax, mx; color = :black, linestyle = :dot)

	# number of post of no path points, one for each rate mult. by the number
	# of rows (usually one, possibly two for kin)
	fpronly = any(["tpr", "ci_tpr"] .∉ Ref(names(rg)))
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

		scatter!(ax_current, x, est; color = ratecolor(r))
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

	jstat = "j" ∈ names(rg)
	effectslegend!(
		layout[1, 2], jstat, true, true;
		fpronly, tr = trp
	)

	return ax, ax_r
end

export distance_eff!
