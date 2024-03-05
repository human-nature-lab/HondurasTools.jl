# effectsplot.jl

function effplot_cat!(
    lo, ll, m1_mrg, vbl;
    jdf = nothing,
    xlabelrotation = 0.0, xticklabelrotation = 0.0
)
    m1_mrg_nk = @subset m1_mrg .!$kin
    m1_mrg_nk[!, vbl] = categorical(string.(m1_mrg_nk[!, vbl]))

    lvls = string.(levels(m1_mrg_nk[!, vbl]))
    lvls = replace.(lvls, "_" => " ")
    xticks = (1.5:2:(2*length(levels(m1_mrg_nk[!, vbl]))), lvls)

    ax = Axis(
        lo[1,1], xticks = xticks, xlabel = string(vbl), ylabel = "accuracy", xlabelrotation = xlabelrotation, xticklabelrotation = xticklabelrotation
    )

    sort!(m1_mrg_nk, [vbl, kin])
    m1_mrg_nk.color = ifelse.(m1_mrg_nk[!, :verity], wc[5], wc[6])

    vl = (2.5:2:(2*length(levels(m1_mrg_nk[!, vbl]))))[1:end]

    vlines!(ax, vl, color = :black, linestyle = :solid, linewidth = 0.5)

    scatter!(
        ax, 1:nrow(m1_mrg_nk), m1_mrg_nk.response;
         color = m1_mrg_nk.color
        )
    rangebars!(
        ax, 1:nrow(m1_mrg_nk), m1_mrg_nk.lower, m1_mrg_nk.upper;
        color = m1_mrg_nk.color
    )

    elems = [[LineElement(color = :black), MarkerElement(marker = :circle, color = c, strokecolor = :transparent)] for c in wc[5:6]]

    Legend(
        ll[1, 1], elems, ["true positive", "true negative"], "rate", framevisible = false, tellheight = false, tellwidth = false, nbanks = 2
    )

    return ax
end

export effplot_cat!

function effplot_cts!(
    lo, ll, m1_mrg, vbl;
    jdf = nothing,
    xlabelrotation = 0.0, xticklabelrotation = 0.0
)
    m1_mrg_nk = if !isnothing(kin)
        @subset m1_mrg .!$kin
    else
        m1_mrg
    end

    vbl_str = string(vbl)
    vbl_str = replace(vbl_str, "_" => " ")
    ax = Axis(
        lo[1, 1], xlabel = vbl_str, ylabel = "accuracy", xlabelrotation = xlabelrotation,
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

        ax2 = Axis(
            lo[1, 1], label = vbl_str, ylabel = "J statistic", xlabelrotation = xlabelrotation,
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

function effplot_cts_pr!(
    lo, ll, fg, m1_mrg, vbl; xlabelrotation = 0.0, xticklabelrotation = 0.0
)
    
    m1_mrg_nk = @subset m1_mrg .!$kin
    vbl_str = string(vbl)
    vbl_str = replace(vbl_str, "_" => " ")
    ax = lo[1,1] = Axis(
        fg, xlabel = vbl_str, ylabel = "accuracy", xlabelrotation = xlabelrotation,
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

function effectsplot!(
    l, ll, mrg, vbl;
    jdf, xlabelrotation, xticklabelrotation
)
    vbltype = eltype(mrg[!, vbl])
    cts = (vbltype <: AbstractFloat) | (vbltype <: Int)
    
    if cts
        effplot_cts!(l, ll, mrg, vbl; jdf, xlabelrotation, xticklabelrotation)
    else
        effplot_cat!(l, ll, mrg, vbl; jdf, xlabelrotation, xticklabelrotation)
    end
end

export effectsplot!
