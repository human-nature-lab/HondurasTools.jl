# biplot.jl

function biplotdata(
	bimodel, dats, vbl;
    pbs = nothing,
	varname = nothing,
	invlink = invlink, type = :normal, iters = 1000,
	transforms = nothing, returnpbs = false,
)

	effdict = usualeffects(dats, vbl)
	refgrids = referencegrid(dats, effdict)
	apply_referencegrids!(bimodel, refgrids; invlink)
	ci!(refgrids)
	for r in refgrids
		sort!(r, [kin, vbl])
	end
	rgs = deepcopy(refgrids)

	mrg = bidatajoin(rgs)
	truenegative!(rgs)
	mrg_l = bidatacombine(rgs)

	dropmissing!(mrg, [vbl, kin])
	dropmissing!(mrg_l, [vbl, kin])

	# add bootstrap info only to the wide `mrg`
	if !isnothing(pbs)
		bs = jboot(
			vbl, bimodel, rgs, pbs, iters; invlink, type,
			confrange = [0.025, 0.975], respvar = :response,
		)
		disallowmissing!(bs)

		# add bootstrap info
		@assert mrg[!, [:dists_p, :dists_a, kin, vbl]] == bs[!, [:dists_p, :dists_a, kin, vbl]]

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
	marginaxiskwargs...,
)

	lroc = plo[1, 1] = GridLayout()
	colsize!(lroc, 1, Relative(4 / 5))
	lef = plo[1, 2] = GridLayout()
	colsize!(lef, 1, Relative(4 / 5))

	rocplot!(
		lroc,
		bpd[:margins], bpd[:margvar], bpd[:varname];
		ellipse,
        ellipsecolor,
		markeropacity
	)

	effectsplot!(
		lef,
		bpd, jstat;
		marginaxiskwargs...,
	)

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
