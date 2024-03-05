# effectsplot.jl

function EffectLegend!(ll, elems)
    Legend(
        ll[1, 1], elems, ["True positive", "True negative"], "Rate", framevisible = false,
        orientation = :horizontal,
        tellheight = false, tellwidth = false, nbanks = 1
    )
end

function effectsplot!(
    l, ll, bpd;
    jdf, axiskwargs...
)

    mrg = bpd[:marginslong]
    vbl = bpd[:margvar]

    vbltype = eltype(mrg[!, vbl])
    cts = (vbltype <: AbstractFloat) | (vbltype <: Int)

    if cts
        effplot_cts!(l, ll, mrg, vbl, jdf, axiskwargs...)
    else
        effplot_cat!(l, ll, mrg, vbl, jdf, axiskwargs...)
    end
end

export effectsplot!

function effplot_cat!(lo, ll, m1_mrg, vbl, jdf, axiskwargs...)

    mrg_nk = @subset m1_mrg .!$kin
    mrg_nk[!, vbl] = categorical(string.(mrg_nk[!, vbl]))

    lvls = string.(levels(mrg_nk[!, vbl]))
    lvls = replace.(lvls, "_" => " ")
    xticks = (1.5:2:(2*length(levels(mrg_nk[!, vbl]))), lvls)

    ax = Axis(lo[1, 1]; xticks, ylabel = "Accuracy", axiskwargs...)

    sort!(mrg_nk, [vbl, kin])
    mrg_nk.color = ifelse.(mrg_nk[!, :verity], oi[5], oi[6])

    vl = (2.5:2:(2*length(levels(mrg_nk[!, vbl]))))[1:end]

    vlines!(ax, vl, color = :black, linestyle = :solid, linewidth = 0.5)

    scatter!(
        ax, 1:nrow(mrg_nk), mrg_nk.response;
         color = mrg_nk.color
    )
    lwr = [x[1] for x in mrg_nk[!, :ci]]
    upr = [x[2] for x in mrg_nk[!, :ci]]
    rangebars!(
        ax, 1:nrow(mrg_nk), lwr, upr;
        color = mrg_nk.color
    )

    elems = [
        [
            LineElement(; color = c),
            MarkerElement(;
                marker = :circle, color = c, strokecolor = :transparent
            )
        ] for c in oi[5:6]
    ]

    EffectLegend!(ll, elems)

    return ax
end

export effplot_cat!

function effplot_cts!(lo, ll, mrg_l, vbl, jdf, axiskwargs...)

    mrg_nk = if !isnothing(kin)
        @subset mrg_l .!$kin
    else
        mrg_l
    end

    vbl_str = string(vbl)
    vbl_str = replace(vbl_str, "_" => " ")
    ax = Axis(
        lo[1, 1];
        ylabel = "Accuracy",
        axiskwargs...
    )

    sort!(mrg_nk, vbl)
    mrg_nk.color = ifelse.(mrg_nk[!, :verity], oi[5], oi[6])

    for (ix, cx) in zip([mrg_nk.verity, .!mrg_nk.verity], [5,6])
        xs = mrg_nk[ix, vbl]
        rs = mrg_nk[ix, :response]
        lwr = [x[1] for x in mrg_nk[ix, :ci]]
        upr = [x[2] for x in mrg_nk[ix, :ci]]
        band!(ax, xs, lwr, upr; color = (oi[cx], 0.6)) # no method for tuples
        lines!(ax, xs, rs, color = oi[cx])
    end

    if isnothing(jdf)
        elems = [
            LineElement(
                color = c
            ) for c in oi[5:6]
        ]

        EffectLegend!(ll, elems)
    else
        # if j statistic data is included, add line and band
        # make legend that includes J statistic with color wong color 7

        ax2 = Axis(
            lo[1, 1];
            label = vbl_str, ylabel = "J statistic",
            xlabelrotation, xticklabelrotation,
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
        band!(ax2, xs, lw, hg, color = (oi[3], 0.2))
        lines!(ax2, xs, rs, color = oi[3])

        elems = [
            LineElement(
                color = c
            ) for c in oi[[5,6,3]]
        ]

        Legend(
            ll[1, 1], elems, ["true positive", "true negative", "youden's J"], "Rate",
            framevisible = false,
            tellheight = false, tellwidth = false, nbanks = 3
        )
    end

    xlims!(ax, extrema(mrg_nk[!, vbl]))

    return ax
end

export effplot_cts!

function effplot_cts_pr!(lo, ll, mrg, vbl, axiskwargs...)
    
    mrg_nk = @subset mrg .!$kin
    vbl_str = string(vbl)
    vbl_str = replace(vbl_str, "_" => " ")
    ax = Axis(
        lo[1, 1];
        xlabel = vbl_str, ylabel = "Accuracy",
        axiskwargs...
    )

    sort!(mrg_nk, vbl)
    mrg_nk.color = ifelse.(mrg_nk[!, :verity], oi[5], oi[6])

    if sum(mrg_nk.verity) > 0
        for ix in [mrg_nk.verity]
            xs = mrg_nk[ix, vbl]
            rs = mrg_nk[ix, :response]
            lw = mrg_nk[ix, :lower]
            hg = mrg_nk[ix, :upper]
            band!(ax, xs, lw, hg, color = (oi[5], 0.6))
            lines!(ax, xs, rs, color = oi[5])
        end
    end

    if sum(.!mrg_nk.verity) > 0
        for ix in [.!m1_mrg_nk.verity]
            xs = mrg_nk[ix, vbl]
            rs = mrg_nk[ix, :response]
            lw = mrg_nk[ix, :lower]
            hg = mrg_nk[ix, :upper]
            band!(ax, xs, lw, hg, color = (oi[6], 0.6))
            lines!(ax, xs, rs, color = oi[6])
        end
    end

    if !isnothing(ll)
        if sum(mrg_nk.verity) > 0
            elems = [LineElement(color = oi[5])]
                
            EffectLegend!(ll, elems)
        end

        if sum(.!mrg_nk.verity) > 0
            elems = [LineElement(color = oi[6])]
                
            EffectLegend!(ll, elems)
        end
    end

    xlims!(ax, extrema(mrg_nk[!, vbl]))

    return ax
end

export effplot_cts_pr!
