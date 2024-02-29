# bivariate_perceiver.jl

"""
        perceivercontour!(
            lo, sbar; kin = :kin431, nlevels = 10, colormap = :berlin
        )

## Description

`sbar`: unadjusted subject-level means. should also contain marginal means
estimates from some selected `EModel`.
"""
function perceivercontour!(
    lo, sbar; kin = :kin431, nlevels = 10, colormap = :berlin
)

    # bivariate density kernels
    sbar.dens = Vector{BivariateKDE}(undef, nrow(sbar));
    for i in 1:nrow(sbar)
        sbar.dens[i] = kde((sbar.type1[i], sbar.tpr[i]))
    end

    # one color range for all four plots (extrema over all densities)
    lv = range(
        extrema(reduce(vcat, [x.density for x in sbar.dens]))...;
        length = nlevels
    );
    
    lo1 = lo[1, 1:2] = GridLayout()
    lop = lo1[1, 1] = GridLayout()
    lop2 = lop[1:2, 1:2] = GridLayout()
    ll = lo1[1,2] = GridLayout()
    
    los = []; axs = []; axs_ = [];

    # positions for each type
    pdict = Dict(
        ("free_time", false) => (1, 1),
        ("free_time", true) => (2, 1),
        ("personal_private", false) => (1, 2),
        ("personal_private", true) => (2, 2)
    )

    psx = Any[];
    for i in 1:nrow(sbar)
        ps = pdict[(sbar.relation[i], sbar[i, kin])]
        li = GridLayout(lop2[ps...])
        ax = Axis(
            li[1, 1];
            ylabel = "True positive rate",
            xlabel = "False positive rate",
            xgridvisible = false, ygridvisible = false,
            title = replace(unwrap(sbar.relation[i]), "_" => " ")
        )
        ax_ = Axis(
            li[1, 1];
            yaxisposition = :right,
            ylabelrotation = -π/2
        )
        hidexdecorations!(ax_)
        hideydecorations!(ax_; label = false)
        push!(los, li)
        push!(axs, ax)
        push!(axs_, ax_)
        push!(psx, ps)
    end

    axs[3].ylabel = ""
    axs[4].ylabel = ""
    axs[1].xlabel = ""
    axs[3].xlabel = ""
    axs[2].title = ""
    axs[4].title = ""
    axs_[1].ylabel = ""
    axs_[2].ylabel = ""
    axs_[3].ylabel = "Kin"
    axs_[4].ylabel = "Non-kin"
  
    cos = []

    (r, ax) = collect(zip(eachrow(sbar), axs))[1];

    for (r, ax) in zip(eachrow(sbar), axs)
        lines!(ax, 0:0.1:1, 0:0.1:1; linestyle = :dot, color = :grey);
        
        vlines!(ax, [0, 1], color = (:black, 0.3));
        hlines!(ax, [0, 1], color = (:black, 0.3));

        chanceline!(ax);
        improvementline!(ax);

        # distribution
        co = contour!(ax, r.dens; levels = lv, colormap)
        push!(cos, co)

        # marginal means
        marker = ifelse(!r[kin], :rect, :cross)
        scatter!(ax, r.accuracy; color = oi[end-1], marker)
        scatter!(ax, r.accuracy_unadj; color = :black, marker)
        
        ylims!(ax, -0.02, 1.02)
        xlims!(ax, -0.02, 1.02)
    end

    Colorbar(
        ll[1, 1];
        limits = extrema(lv), colormap,
        flipaxis = false, vertical = true, label = "Density"
    )

    # set equal axes
    for lx in los
        colsize!(lx, 1, Aspect(1, 1.0))
    end
    colsize!(lo1, 1, Aspect(1, 1.0))

    return los, cos, lo1, lop, lop2, ll
end

export perceivercontour!

"""

## Description

- `plo`: parent layout
"""
function bivariate_perceiver!(
    plo, mm, sbar; kin = :kin431, nlevels = 12, colormap = :berlin
)

    lxx = plo[1, 1:2] = GridLayout();
    lo = lxx[1, 1] = GridLayout();

    # Panel A, B
    
    los, cos, lo1, lop, lop2, ll = perceivercontour!(
        lo, sbar; kin, nlevels, colormap
    )

    # panel B
    # marginal effects plot
    
    # end legend
    
    labelpanels!([los[[1, 2]]..., l2])
end

export bivariate_perceiver
