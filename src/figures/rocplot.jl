# rocplot.jl

function rocplot!(
    layout,
    rg, margvar, margvarname;
    axsz = 250,
    dropkin = false,
    ellipsecolor = (yale.grays[end-1], 0.3),
    markeropacity = nothing,
    roctitle = true,
    kinlegend = true,
    extramargin = false,
    dolegend = true,
    legargs = (framevisible = false, tellheight = false, tellwidth = false, orientation = :vertical, nbanks = 1)
)

    ellipse = ifelse("Σ" ∈ names(rg), true, false);

    rg = deepcopy(rg)
    
    if !dropkin
        kinmarker = true
    elseif (string(kin) ∈ names(rg))
        @subset! rg .!$kin
        kinmarker = false
    end

    rocplot_!(
        layout[1, 1], rg, margvar, margvarname;
        markeropacity,
        ellipse,
        ellipsecolor,
        roctitle,
        kinmarker = kinmarker,
        kin = kin,
        axsz,
        extramargin,
    )

    vbltype = eltype(rg[!, margvar])
    cts = (vbltype <: AbstractFloat) | (vbltype <: Int)
    if dolegend
        lx = layout[1, 2] = GridLayout()
        roclegend!(
            lx, rg[!, margvar], margvarname, ellipse, ellipsecolor, cts;
            kinlegend,
            legargs...
        )
        colsize!(layout, 1, Relative(4/5))
        colgap!(layout, 0)
    end
end

export rocplot!

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

# via https://discourse.julialang.org/t/plot-ellipse-in-makie/82814
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
    layout, vbl_vals, varname, ellipse, ellipsecolor,
    kinlegend; legargs...
)
    elems = if !ellipse
        [
            MarkerElement(
                marker = :circle, color = c, strokecolor = :transparent
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

    if kinlegend
        elems_kin = [
            MarkerElement(;
                marker = m, color = :black, strokecolor = :transparent
            ) for m in [:circle, :cross]
        ]

        lvls_kin = ["No", "Yes"];
        lvls = [lvls, lvls_kin]
        elems = [elems, elems_kin]
        nms = [varname, "Kin tie"]
    else
        elems = [elems]
        lvls = [lvls]
        nms = [varname]
    end

    Legend(
        layout[1, 2], elems, lvls, nms;
        legargs...,
    )
    
    # this may need adjustment for some plots
    #colgap!(layout, -80)
end

function roclegend!(
    layout, vbl_vals, varname, ellipse, ellipsecolor, cts;
    kinlegend = true,
    legargs...
)

    if !cts
        _cat_legend!(
            layout, vbl_vals, varname, ellipse, ellipsecolor,
            kinlegend; legargs...
        )
    else
        if kinlegend
            rowsize!(layout, 1, Relative(3.75/5))
        end
        rangescale = extrema(vbl_vals)

        Colorbar(
            layout[1, 1];
            limits = rangescale, colormap = :berlin,
            flipaxis = false, vertical = true,
            label = varname,
            tellheight = false
        )
        
        if kinlegend
            elems = [[
                MarkerElement(;
                    marker = m, color = :black, strokecolor = :transparent
                ) for m in [:circle, :cross]
            ]]
    
            lvls = [["No", "Yes"]];
            nms = ["Kin tie"]
            Legend(
                layout[2, 1], elems, lvls, nms;
                legargs...,
                orientation = :vertical,
                nbanks = 1
            )
        end    
    end
end

function rocplot_!(
    layout, rg, margvar, margvarname;
    markeropacity = nothing,
    ellipse = false,
    ellipsecolor = (:grey, 0.3),
    roctitle = true,
    kinmarker = true,
    kin = kin,
    axsz = 250,
    extramargin = false
)

    rg = deepcopy(rg);

    vbltype = eltype(rg[!, margvar])
    cts = (vbltype <: AbstractFloat) | (vbltype <: Int)

    if isnothing(markeropacity)
        markeropacity = ifelse(cts, 0.5, 1.0)
    end

    rg.color = if !cts
        rg[!, margvar] = categorical(string.(rg[!, margvar]))
        [oi[levelcode(x)] for x in rg[!, margvar]]
    else
        rangescale = extrema(rg[!, margvar])
        get(colorschemes[:berlin], rg[!, margvar], rangescale);
    end;

    if kinmarker & (string(kin) ∈ names(rg))
        rg.marker = ifelse.(rg[!, kin], :cross, :circle);
    else
        rg.marker .= :circle
    end
    
    ax = Axis(
        layout[1, 1];
        xlabel = "False positive rate", ylabel = "True positive rate",
        xticks = 0:0.25:1,
        yticks = 0:0.25:1,
        height = axsz,
        width = axsz,
        title = ifelse(roctitle, string(margvarname), "")
    )

    # line of chance
    chanceline!(ax);
    improvementline!(ax);
    
    if !extramargin
        xlims!(ax, 0, 1)
        ylims!(ax, 0, 1)
    else
        ylims!(ax, -0.02, 1.02)
        xlims!(ax, -0.02, 1.02)
        vlines!(ax, [0, 1], color = (:black, 0.3));
        hlines!(ax, [0, 1], color = (:black, 0.3));
    end
    
    # (optionally) plot confidence ellipse
    if ellipse
        for (fp, tp, Σ) in zip(rg.fpr, rg.tpr, rg.Σ)
            poly!(
                Point2f.(zip(getellipsepoints(Point(fp, tp), Σ)...,));
                color = ellipsecolor
            )
        end
    end

    # plot the data
    scatter!(
        ax,
        rg[!, :fpr], rg[!, :tpr];
        color = [(x, markeropacity) for x in rg.color],
        marker = rg.marker,
        markersize = 8
    )
    
    return ax
end

export rocplot_!

function roclegend_dist!(
    layout, vbl_vals, varname, ellipse, ellipsecolor, cts;
    kinlegend = true,
    legargs...
)

    rowsize!(layout, 1, Relative(3.75/5))
    rangescale = extrema(vbl_vals)

    Colorbar(
        layout[1, 1];
        limits = rangescale, colormap = :berlin,
        flipaxis = false, vertical = true,
        label = varname,
        tellheight = false
    )
    
    if kinlegend
        elems = [[
            MarkerElement(;
                marker = m, color = :black, strokecolor = :transparent
            ) for m in [:circle, :cross]
        ]]

        lvls = [["No", "Yes"]];
        nms = ["Kin tie"]
    else
        elems = [elems]
        lvls = [lvls]
        nms = [varname]
    end

    Legend(
        layout[2, 1], elems, lvls, nms;
        legargs...,
        orientation = :vertical,
        nbanks = 1
    )

    existcolor = columbia.secondary[2] # :managua10
    elems = [MarkerElement(; marker = :circle, color = existcolor)]
    Legend(
        extraelement, [elems], ["No path"], "";
        orientation = :vertical, nbanks = 1,
        framevisible = false, legargs...
    )
end
