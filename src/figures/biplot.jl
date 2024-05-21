# biplot.jl

function biplot!(
	layout, bpd;
	ellipsecolor = (yale.grays[end-1], 0.4),
	dropkin_eff = true,
	tnr = true
)

	l1 = layout[1, 1] = GridLayout();
	l2 = layout[1, 2] = GridLayout();

	if bpd.margvar ∉ [:dists_p, :dists_a, :are_related_dists_a]
		colsize!(layout, 1, Relative(1/2))

		rocplot!(
			l1,
			bpd.rg, bpd.margvar, bpd.margvarname;
			ellipsecolor,
			markeropacity = nothing,
		)    

		effectsplot!(
			l2, bpd.rg, bpd.margvar, bpd.margvarname, tnr;
			dropkin = dropkin_eff,
		)
	else
		colsize!(layout, 1, Relative(1/2))
		colgap!(layout, -40)

		distance_roc!(
			l1,
			bpd.rg, bpd.margvar, bpd.margvarname;
		)

		distance_eff!(
			l2, bpd.rg, bpd.margvar, bpd.margvarname;
			dropkin = dropkin_eff
		)
	end
	
	return l1, l2
end

export biplot!

"""
		distancebiplot!(lo, e, md)

## Description

Plot ROC-space plot and marginal effects plot, customized for network distances.
"""
function distancebiplot!(lo, e, md)
    m = md[e]
    lo1 = GridLayout(lo[1,1])
    lo2 = GridLayout(lo[1,2])
	colsize!(layout, 1, Relative(1/2))
    
    distance_roc!(
        lo1,
        m.rg, e, m.name;
    )

    distance_eff!(
        lo2, m.rg, e, m.name;
        dropkin = true
    )
end

export distancebiplot!
