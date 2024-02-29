# biplot.jl

function bi_plot(
    m1_mrg, vbl, cap1, cap2;
    fg = Figure(backgroundcolor = :transparent),
    jdf = nothing, ellipse = false,
    kin = :kin431, wc = nothing, prj = nothing, xlabelrotation = Makie.automatic, xticklabelrotation = 0.0,
    title = nothing
)

    # create copy of effects df with fpr instead of tnr
    m1_mrg_fpr = deepcopy(m1_mrg)
    for x in [:response, :lower, :upper]
        m1_mrg_fpr[!, x] = ifelse.(.!m1_mrg[!, :verity], 1 .- m1_mrg[!, x], m1_mrg[!, x])
    end

    
    la = fg[1:2, 1:2] = GridLayout()
    lx = la[1, 1:2] = GridLayout()
    l1 = lx[1, 1] = GridLayout()
    l2 = lx[1, 2] = GridLayout()
    
    ll = la[2, 1:2]
    ll1 = ll[1,1] = GridLayout();
    ll2 = ll[1,2] = GridLayout();
    
    roc_plot!(l1, ll1, m1_mrg_fpr, vbl, kin; ellipse, jdf, wc)
    
    vbltype = eltype(m1_mrg[!, vbl])

    cts = (vbltype <: AbstractFloat) | (vbltype <: Int)
    if cts
        effplot_cts!(l2, ll2, fg, m1_mrg, vbl; jdf, wc, kin, aspect = 1, xlabelrotation, xticklabelrotation)
    else
        effplot_cat!(l2, ll2, fg, m1_mrg, vbl; jdf, wc, kin, aspect = 1, xlabelrotation, xticklabelrotation)
    end
    
    labelpanels!([l1,l2])
    
    colsize!(lx, 1, Relative(.5))
    rowsize!(la, 1, Relative(4/5))
    
    # rowgap!(la, 1, -10)

    colsize!(fg.layout, 1, Aspect(1, 4))
    resize_to_layout!(fg)

    cap3 = cap1 * " " * cap2
    if !isnothing(prj)
        title = if isnothing(title)
            string(vbl)
        else
            title
        end
        savemdfigure(prj.pp, prj.css, title * "-eff", cap3, fg)
    end
    return fg
end

export bi_plot
