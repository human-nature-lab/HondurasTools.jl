# rocplot.jl

function getellipsepoints(cx, cy, rx, ry, θ)
	t = range(0, 2*pi, length=100)
	ellipse_x_r = @. rx * cos(t)
	ellipse_y_r = @. ry * sin(t)
	R = [cos(θ) sin(θ); -sin(θ) cos(θ)]
	r_ellipse = [ellipse_x_r ellipse_y_r] * R
	x = @. cx + r_ellipse[:,1]
	y = @. cy + r_ellipse[:,2]
	(x,y)
end

function getellipsepoints(μ, Σ; confidence = 0.95)
	quant = quantile(Chisq(2), confidence) |> sqrt
	cx = μ[1]
	cy =  μ[2]
	
	egvs = eigvals(Σ)
	if egvs[1] > egvs[2]
		idxmax = 1
		largestegv = egvs[1]
		smallesttegv = egvs[2]
	else
		idxmax = 2
		largestegv = egvs[2]
		smallesttegv = egvs[1]
	end

	rx = quant*sqrt(largestegv)
	ry = quant*sqrt(smallesttegv)
	
	eigvecmax = eigvecs(Σ)[:,idxmax]
	θ = atan(eigvecmax[2]/eigvecmax[1])
 	if θ < 0
		θ += 2*π
	end

	getellipsepoints(cx, cy, rx, ry, θ)
end

function rocplot!(
    l, ll, mus, vbl;
    markeropacity = nothing,
    ellipse = false, jdf = nothing, legtitle = nothing
)

    legargs = (framevisible = false, tellheight = false, tellwidth = false,)

    vbltype = eltype(mus[!, vbl])
    cts = (vbltype <: AbstractFloat) | (vbltype <: Int)

    if isnothing(markeropacity)
        markeropacity = ifelse(cts, 0.5, 1.0)
    end

    mus.color = if !cts
        mus[!, vbl] = categorical(string.(mus[!, vbl])) # make string regardless
        [oi[levelcode(x)] for x in mus[!, vbl]]
    else
        rangescale = extrema(mus[!, vbl])
        get(colorschemes[:berlin], mus[!, vbl], rangescale);
    end;

    mus.marker = ifelse.(mus[!, kin], :cross, :rect);
    
    ax = Axis(
        l[1, 1]; xlabel = "False positive rate", ylabel = "True positive rate"
    )

    # line of chance
    chanceline!(ax);
    improvementline!(ax);
    
    xlims!(0, 1)
    ylims!(0, 1)

    # (optionally) plot confidence ellipse
    if !isnothing(jdf) & ellipse
        jdf = select(jdf, [kin, vbl, :cov])
        mus2 = leftjoin(mus, jdf, on = [vbl, kin])

        for (p1, p2, Σ) in zip(
            mus2[!, Symbol("false")], mus2[!, Symbol("true")], mus2[!, :cov]
        )
            # lines!(getellipsepoints(Point(p1, p2), Σ)..., label = "95% confidence interval", color = (:grey, 0.1), )
            poly!(
                Point2f.(zip(getellipsepoints(Point(p1, p2), Σ)...,));
                color =(:grey, 0.1)
            )
        end
    end

    # plot the data
    scatter!(
        ax,
        mus[!, :fpr], mus[!, :tpr],
        color = [
            (x, markeropacity) for x in mus.color];
            marker = mus.marker, markersize = 8
    )

    vbl_str = if isnothing(legtitle)
        replace(string.(vbl), "_" => " ")
    else
        legtitle
    end

    # legend: variable/color
    if !cts
        elems = [
            MarkerElement(
                marker = :rect, color = c, strokecolor = :transparent
            ) for c in wc[1:length(levels(mus[!, vbl]))]
        ]

        lvls = string.(levels(mus[!, vbl]))
        lvls = replace.(lvls, "_" => " ")

        Legend(
            l[1, 2], elems, lvls, vbl_str;
            legargs..., orientation = :vertical, nbanks = 1
        )

        colgap!(l, -10)
    else
        rangescale = extrema(mus[!, vbl])
        Colorbar(
            l[1, 2];
            limits = rangescale, colormap = :berlin,
            flipaxis = false, vertical = true,
            label = vbl_str,
            tellheight = false
        )
    end
    
    # legend: kin/marker
    elems = [
        MarkerElement(;
            marker = m, color = :black, strokecolor = :transparent
        ) for m in [:rect, :cross]
    ]

    Legend(
        ll[1, 2], elems, ["False", "True"], "Kin";
        legargs..., orientation = :horizontal, nbanks = 1
    )

    return ax
end

export rocplot!
