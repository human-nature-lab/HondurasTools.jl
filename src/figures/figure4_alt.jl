# figure4 (alt).jl

function figure4_alt!(los, vars, md; ellipsecolor = (yale.grays[end-2], 0.75), ellipsehulls = nothing)
	for (i, e) in enumerate(vars)
		rg, margvarname = md[e]
		tp = (
			rg = rg, margvar = e, margvarname = margvarname,
			tnr = true, jstat = true
		);
		hull = get(ellipsehulls,e,nothing)
		biplot!(los[i], tp; ellipsecolor, ellipsehull = hull)
	end

	labelpanels!(los)
end

function make_figure4_alt!(fg, md, transforms, vars; ellipsecolor = (yale.grays[end-2], 0.75), ellipsehulls = nothing)

	# back-transform relevant cts. variables
	for e in [
		:age_mean_a, :age_diff_a,
		:degree_mean_a, :degree_diff_a,
		:dists_p, :dists_a
	]
		md[e].rg[!, e] = reversestandard(md[e].rg, e, transforms)
	end

	let e = :relation
		md[e].rg[!, e] = replace(
			md[e].rg[!, e],
			"free_time" => "Free time", "personal_private" => "Personal private"
		) |> categorical
	end

	# plot at the mean TPR prediction over the dist_p range
	let
		tprbar = mean(md[:dists_p].rg[md[:dists_p].rg.dists_p_notinf .== true, :tpr])
		md[:dists_a].rg.tpr .= tprbar
	end

	lo = GridLayout(fg[1:4, 1:2], width = 950*2)
	los = GridLayout[];
	cnt = 0
	for i in 1:4
		for j in 1:2
			cnt+=1
			if cnt <= length(vars)
				l = lo[i, j] = GridLayout()
				push!(los, l)
			end
		end
	end
	figure4_alt!(los, vars, md; ellipsecolor, ellipsehulls)
end

export make_figure4_alt!
