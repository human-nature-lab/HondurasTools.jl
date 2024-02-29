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

function getellipsepoints(μ, Σ, confidence=0.95)
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

function roc_plot!(
    lo, ll, m1_mrg, vbl, kin;
    ellipse = false, jdf = nothing, wc = nothing, lpx = [1, 2]
)

    vbltype = eltype(m1_mrg[!, vbl])
    cts = (vbltype <: AbstractFloat) | (vbltype <: Int)

    mus = unstack(m1_mrg, [vbl, kin], :verity, :response)

    mus.color = if !cts
        mus[!, vbl] = categorical(string.(mus[!, vbl])) # make string regardless
        [wc[levelcode(x)] for x in mus[!, vbl]]
    else
        rangescale = extrema(mus[!, vbl])
        get(colorschemes[:berlin], mus[!, vbl], rangescale);
    end

    mus.marker = ifelse.(mus[!, kin], :cross, :rect)
    
    ax = Axis(
        lo[1, 1];
        ygridvisible = false, xgridvisible = false,
        xlabel = "false positive rate", ylabel = "true positive rate",
        aspect = 1
    )

    # line of chance
    lines!(ax, 0:0.1:1, 0:0.1:1; linestyle = :dot, color = :grey)
    # line of improvement
    lines!(ax, (1:-0.1:0.5), 0:0.1:0.5; linestyle = :solid, color = wong[6])
    lines!(ax, (0.5:-0.1:0), 0.5:0.1:1; linestyle = :solid, color = wong[3])
    
    xlims!(0,1)
    ylims!(0,1)

    # optionally plot confidence ellipse
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
        mus[!, Symbol("false")], mus[!, Symbol("true")],
        color = [
            (x, 0.5) for x in mus.color];
            marker = mus.marker, markersize = 8
    )

    vbl_str = replace(string.(vbl), "_" => " ")

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
            ll[1, 1], elems, lvls, string(vbl), framevisible = false, tellheight = false, tellwidth = false, nbanks = 2
        )
    else
        
        rangescale = extrema(mus[!, vbl])
        Colorbar(ll[1, 1], limits = rangescale, colormap = :berlin,
            flipaxis = false, vertical = false,
            label = vbl_str
        )
    end
    
    # legend: kin/marker
    elems = [
            MarkerElement(
                marker = m, color = :black, strokecolor = :transparent
            ) for m in [:rect, :cross]
        ]

    Legend(
        ll[lpx...], elems, ["false", "true"], "kin", framevisible = false, tellheight = false, tellwidth = false, nbanks = 2
    )

    return ax
end

export roc_plot!

function effplot_cat!(
    lo, ll, fg, m1_mrg, vbl;
    jdf = nothing, wc = nothing,
    kin = :kin431, aspect = 1, xlabelrotation = 0.0, xticklabelrotation = 0.0
)
    m1_mrg_nk = @subset m1_mrg .!$kin
    m1_mrg_nk[!, vbl] = categorical(string.(m1_mrg_nk[!, vbl]))

    lvls = string.(levels(m1_mrg_nk[!, vbl]))
    lvls = replace.(lvls, "_" => " ")
    xticks = (1.5:2:(2*length(levels(m1_mrg_nk[!, vbl]))), lvls)

    ax = lo[1,1] = Axis(
        fg, xticks = xticks, aspect = aspect, xlabel = string(vbl), ylabel = "accuracy", xlabelrotation = xlabelrotation, xticklabelrotation = xticklabelrotation
    )

    sort!(m1_mrg_nk, [vbl, kin])
    m1_mrg_nk.color = ifelse.(m1_mrg_nk[!, :verity], wc[5], wc[6])

    vl = (2.5:2:(2*length(levels(m1_mrg_nk[!, vbl]))))[1:end]

    vlines!(ax, vl, color = :black, linestyle = :solid, linewidth = 0.5)

    scatter!(ax, 1:nrow(m1_mrg_nk), m1_mrg_nk.response, color = m1_mrg_nk.color)
    rangebars!(ax, 1:nrow(m1_mrg_nk), m1_mrg_nk.lower, m1_mrg_nk.upper, color = m1_mrg_nk.color)


    elems = [[LineElement(color = :black), MarkerElement(marker = :circle, color = c, strokecolor = :transparent)] for c in wc[5:6]]

    Legend(
        ll[1, 1], elems, ["true positive", "true negative"], "rate", framevisible = false, tellheight = false, tellwidth = false, nbanks = 2
    )

    return ax
end

export effplot_cat!

function effplot_cts!(
    lo, ll, fg, m1_mrg, vbl;
    jdf = nothing,
    wc = nothing, kin = :kin431, aspect = 1, xlabelrotation = 0.0, xticklabelrotation = 0.0
)
    m1_mrg_nk = if !isnothing(kin)
        @subset m1_mrg .!$kin
    else
        m1_mrg
    end

    vbl_str = string(vbl)
    vbl_str = replace(vbl_str, "_" => " ")
    ax = lo[1,1] = Axis(
        fg, aspect = aspect, xlabel = vbl_str, ylabel = "accuracy", xlabelrotation = xlabelrotation,
        xticklabelrotation = xticklabelrotation
    )

    sort!(m1_mrg_nk, vbl)
    m1_mrg_nk.color = ifelse.(m1_mrg_nk[!, :verity], wc[5], wc[6])

    for (ix, cx) in zip([m1_mrg_nk.verity, .!m1_mrg_nk.verity], [5,6])
        xs = m1_mrg_nk[ix, vbl]
        rs = m1_mrg_nk[ix, :response]
        lw = m1_mrg_nk[ix, :lower]
        hg = m1_mrg_nk[ix, :upper]
        band!(ax, xs, lw, hg, color = (wc[cx], 0.6))
        lines!(ax, xs, rs, color = wc[cx])
    end

    if isnothing(jdf)
        elems = [
            LineElement(
                color = c
            ) for c in wc[5:6]
        ]

        Legend(
            ll[1, 1], elems, ["true positive", "true negative"], "rate",
            framevisible = false,
            tellheight = false, tellwidth = false, nbanks = 2
        )
    else
        # if j statistic data is included, add line and band
        # make legend that includes J statistic with color wong color 7

        ax2 = lo[1,1] = Axis(
            fg, aspect = aspect, xlabel = vbl_str, ylabel = "J statistic", xlabelrotation = xlabelrotation,
            xticklabelrotation = xticklabelrotation,
            # yticklabelcolor = :red,
            yaxisposition = :right
        )

        hidespines!(ax2)
        hidexdecorations!(ax2)
        linkxaxes!(ax, ax2)

        hlines!(ax2, [0.0], color = :grey, linestyle = :dot)

        if !isnothing(kin)
            jdf = @subset jdf .!$kin
        end
        sort!(jdf, vbl)

        xs = jdf[!, vbl]
        rs = jdf[!, :peirce_mean]
        lw = jdf[!, :peirce_lwr]
        hg = jdf[!, :peirce_upr]
        band!(ax2, xs, lw, hg, color = (wc[3], 0.2))
        lines!(ax2, xs, rs, color = wc[3])

        elems = [
            LineElement(
                color = c
            ) for c in wc[[5,6,3]]
        ]

        Legend(
            ll[1, 1], elems, ["true positive", "true negative", "youden's J"], "rate",
            framevisible = false,
            tellheight = false, tellwidth = false, nbanks = 3
        )
    end

    xlims!(ax, extrema(m1_mrg_nk[!, vbl]))

    return ax
end

export effplot_cts!

function effplot_cts_pr!(lo, ll, fg, m1_mrg, vbl; wc = nothing, kin = :kin431, aspect = 1, xlabelrotation = 0.0, xticklabelrotation = 0.0)
    
    m1_mrg_nk = @subset m1_mrg .!$kin
    vbl_str = string(vbl)
    vbl_str = replace(vbl_str, "_" => " ")
    ax = lo[1,1] = Axis(
        fg, aspect = aspect, xlabel = vbl_str, ylabel = "accuracy", xlabelrotation = xlabelrotation,
        xticklabelrotation = xticklabelrotation
    )

    sort!(m1_mrg_nk, vbl)
    m1_mrg_nk.color = ifelse.(m1_mrg_nk[!, :verity], wc[5], wc[6])

    if sum(m1_mrg_nk.verity) > 0
        for ix in [m1_mrg_nk.verity]
            xs = m1_mrg_nk[ix, vbl]
            rs = m1_mrg_nk[ix, :response]
            lw = m1_mrg_nk[ix, :lower]
            hg = m1_mrg_nk[ix, :upper]
            band!(ax, xs, lw, hg, color = (wc[5], 0.6))
            lines!(ax, xs, rs, color = wc[5])
        end
    end

    if sum(.!m1_mrg_nk.verity) > 0
        for ix in [.!m1_mrg_nk.verity]
            xs = m1_mrg_nk[ix, vbl]
            rs = m1_mrg_nk[ix, :response]
            lw = m1_mrg_nk[ix, :lower]
            hg = m1_mrg_nk[ix, :upper]
            band!(ax, xs, lw, hg, color = (wc[6], 0.6))
            lines!(ax, xs, rs, color = wc[6])
        end
    end

    if !isnothing(ll)
        if sum(m1_mrg_nk.verity) > 0
            elems = [LineElement(color = wc[5])]
                
            Legend(
                ll[1, 1], elems, ["true positive"], "rate",
                framevisible = false,
                tellheight = false, tellwidth = false, nbanks = 2
            )
        end

        if sum(.!m1_mrg_nk.verity) > 0
            elems = [LineElement(color = wc[6])]
                
            Legend(
                ll[1, 1], elems, ["false positive"], "rate",
                framevisible = false,
                tellheight = false, tellwidth = false, nbanks = 2
            )
        end
    end

    xlims!(ax, extrema(m1_mrg_nk[!, vbl]))

    return ax
end

export effplot_cts_pr!
