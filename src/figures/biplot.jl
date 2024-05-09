# biplot.jl

function margplotdata_setup(
	dats, margvar;
	additions = nothing,
	margresolution = 0.01,
	stratifykin = true,
	kin = kin
)
	vbltype = eltype(dats.tpr[!, margvar])
	cts = (vbltype <: AbstractFloat) | (vbltype <: Int)

	vls = (sunique∘skipmissing∘vcat)(dats[:tpr][!, margvar], dats[:fpr][!, margvar]);

	if isnothing(additions)
		additions = if cts
			mn, mx = extrema(vls)
			[margvar => collect(mn:margresolution:mx)]
		elseif !cts
			[margvar => sunique(vls)]
		end
	end

	ed = usualeffects(dats, additions; stratifykin)
	rg = referencegrid(dats, ed)
	return rg
end

export margplotdata_setup

function margplotdata_calculate(
	bimodel, pbs, rg, invlink, margvar, margvarname, tnr, iters, confrange; kin,
	simpleout = false
)

	apply_referencegrids!(bimodel, rg; invlink)
	ci!(rg)
	vx = intersect(names(rg.tpr), names(rg.fpr), [string(margvar), string(kin)])
	for r in rg; sort!(r, vx) end;

	# if pbs run jboot, o.w. just combine the referencegrids
	rg = processrefgrid(
		rg, bimodel, margvar, iters, invlink;
		pbs, confrange
	);
	
	return if !simpleout
		(
			rg = rg, margvar = margvar, margvarname = margvarname,
			tnr = tnr, jstat = ifelse(isnothing(pbs), false, true),
		);
	else
		rg
	end
end

export margplotdata_calculate

"""
		margplotdata(
			bimodel, dats, margvar, margvarname, invlink;
			pbs = nothing,
			margresolution = 0.01
			stratifykin = true,
			iters = 1_000,
			tnr = true,
			confrange = [0.025, 0.975]
		)

## Description

Make a tuple that contains the data and options for roc and effects plots.

If the marginal variable `margvar` is continuous, it will be plotted at `margresolution`. If it is categorical (or binary) the full set of unique variable values will be used.

Optionally, include the J statistic and bivariate ellipse data via the bootstrap data `pbs`.

Stratify by the kinship status of the tie, or not, with `stratifykin`.

Specify `additions` to construct a more customized dictionary (e.g., include ranges of multiple variable).
"""
function margplotdata(
	bimodel, dats, margvar, margvarname, invlink;
	pbs = nothing,
	additions = nothing,
	margresolution = 0.01,
	stratifykin = true,
	iters = 1_000,
	tnr = true,
	confrange = [0.025, 0.975],
	kin = kin
)

	rg = margplotdata_setup(
		dats, margvar;
		additions,
		margresolution,
		stratifykin,
		kin
	)

	return margplotdata_calculate(
		bimodel, pbs, rg, invlink,
		margvar, margvarname, tnr, iters, confrange; kin
	)
end

export margplotdata

function biplot!(layout, bpd; dropkin_eff = true, kin = kin)

	l1 = layout[1, 1] = GridLayout();
	l2 = layout[1, 2] = GridLayout();
	colsize!(layout, 1, Relative(1/2))

	rocplot!(
		l1,
		bpd.rg, bpd.margvar, bpd.margvarname;
		ellipsecolor = (:grey, 0.3),
		markeropacity = nothing,
	)    

	effectsplot!(
		l2, bpd.rg, bpd.margvar, bpd.margvarname, bpd.tnr, bpd.jstat;
		dropkin = dropkin_eff, kin
	)
	
	return l1, l2
end

export biplot!
