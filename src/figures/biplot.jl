# biplot.jl

function biplot!(layout, bpd; dropkin = true, kin = kin)

	l1 = layout[1, 1] = GridLayout();
	l2 = layout[1, 2] = GridLayout();
	colsize!(l, 1, Relative(1/2))

	rocplot!(
		l1,
		bpd.rg, bpd.margvar, bpd.margvarname;
		ellipsecolor = (:grey, 0.3),
		markeropacity = nothing,
	)    

	effectsplot!(
		l2, bpd.rg, bpd.margvar, bpd.margvarname, bpd.tnr, bpd.jstat;
		dropkin, kin
	)
	resize_to_layout!(fg)
	resize!(fg, 900, 350)
	fg
end

export biplot
