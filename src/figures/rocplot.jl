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

function _cat_legend!(
    layout, vbl_vals, varname, ellipse, ellipsecolor; legargs...
)
    elems = if !ellipse
        [
            MarkerElement(
                marker = :rect, color = c, strokecolor = :transparent
            ) for c in wc[1:length(levels(vbl_vals))]
        ]
    else
        [
            [
                MarkerElement(
                    marker = :circle, color = ellipsecolor,
                    strokecolor = :transparent, markersize = 30
                ),
                MarkerElement(
                    marker = :circle, color = c, strokecolor = :transparent
                )
            ] for c in wc[1:length(levels(vbl_vals))]
        ]
    end

    lvls = string.(levels(vbl_vals))
    lvls = replace.(lvls, "_" => " ")

    elems_kin = [
        MarkerElement(;
            marker = m, color = :black, strokecolor = :transparent
        ) for m in [:rect, :cross]
    ]

    lvls_kin = ["No", "Yes"];

    Legend(
        layout[1, 2], [elems, elems_kin], [lvls, lvls_kin], [varname, "Kin tie"];
        legargs..., orientation = :vertical, nbanks = 1
    )
end

function roc_legend!(
    layout, vbl_vals, varname, ellipse, ellipsecolor, cts;
    extraelement = false,
    px = [1,2],
    legargs...
)
    if !cts
        _cat_legend!(
            layout, vbl_vals, varname, ellipse, ellipsecolor; legargs...
        )
    else
        lx = layout[px...] = GridLayout()
        rowsize!(lx, 1, Relative(4.5/5))
        rangescale = extrema(vbl_vals)
        Colorbar(
            lx[1, 1];
            limits = rangescale, colormap = :berlin,
            flipaxis = false, vertical = true,
            label = varname,
            tellheight = false
        )
        if extraelement
            existcolor = colorschemes[:Anemone][1] # :managua10
            elems = [MarkerElement(; marker = :circle, color = existcolor)]
            Legend(
                lx[2, 1], [elems], ["No path"], "";
                orientation = :vertical, nbanks = 1,
                framevisible = false, legargs...
            )
        end
    end
end

function rocplot!(
    layout, margins, vbl, varname;
    markeropacity = nothing,
    ellipse = false,
    ellipsecolor = (:grey, 0.3),
    legend = true,
    roctitle = true
)

    legargs = (framevisible = false, tellheight = false, tellwidth = false,)

    vbltype = eltype(margins[!, vbl])
    cts = (vbltype <: AbstractFloat) | (vbltype <: Int)

    if isnothing(markeropacity)
        markeropacity = ifelse(cts, 0.5, 1.0)
    end

    margins.color = if !cts
        margins[!, vbl] = categorical(string.(margins[!, vbl])) # make string regardless
        [oi[levelcode(x)] for x in margins[!, vbl]]
    else
        rangescale = extrema(margins[!, vbl])
        get(colorschemes[:berlin], margins[!, vbl], rangescale);
    end;

    margins.marker = ifelse.(margins[!, kin], :cross, :rect);
    
    ax = Axis(
        layout[1, 1];
        xlabel = "False positive rate", ylabel = "True positive rate",
        # aspect = 1
        height = 250, width = 250,
        title = ifelse(roctitle, string(varname), "")
    )

    # line of chance
    chanceline!(ax);
    improvementline!(ax);
    
    xlims!(ax, 0, 1)
    ylims!(ax, 0, 1)
    
    # (optionally) plot confidence ellipse
    if ellipse
        jdf = margins[!, [:tpr, :fpr, :Σ]]

        for (fp, tp, Σ) in zip(jdf.fpr, jdf.tpr, jdf.Σ)
            poly!(
                Point2f.(zip(getellipsepoints(Point(fp, tp), Σ)...,));
                color = ellipsecolor
            )
        end
    end

    # plot the data
    scatter!(
        ax,
        margins[!, :fpr], margins[!, :tpr],
        color = [
            (x, markeropacity) for x in margins.color];
            marker = margins.marker, markersize = 8
    )

    if legend
        # legend: variable/color
        roc_legend!(
            layout, margins[!, vbl], varname, ellipse, ellipsecolor, cts;
            legargs...
        )
    end
    
    return ax
end

export rocplot!
