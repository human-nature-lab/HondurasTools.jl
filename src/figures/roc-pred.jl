#| label: fig-roc-like
#| fig-scap: "Predicted values from response models"
#| fig-cap: "Predicted values from the models of the responses (a) at each distance (averaged across the perceivers) for the *free time* responses. Plots display the true vs. false positive rate, using the marginal effects from the estimated models for (a) average distance, (b) education, and (c) age. Each variable is stratified by kin status. We generally observe that kin responses cluster close to the line of chance (consistent with Youden's J statistics close to zero), and roughly linear relationships between the two rates over values of the three variables."

# this can be done more easily with marginal effects...

function process_eftables(efs, vbl1, vbl2; digits = 2, vbl = nothing)
    efs[1].socio .= true;
    efs[1].relationship .= "free time"
    
    efs[2].socio .= false;
    efs[2].relationship .= "free time"
   
    efs[3].socio .= true;
    efs[3].relationship .= "personal private"
    
    efs[4].socio .= false;
    efs[4].relationship .= "personal private"

    if !isnothing(vbl)
        for e in efs
            for (u, nm) in enumerate(names(e))
                if (nm == string(vbl1)) | (nm == string(vbl2))
                    rename!(e, names(e)[u] => vbl)
                end
            end
        end
    end

    cefs = reduce(vcat, efs)
    sort!(cefs, [:kin, :relationship, :socio])

    for e in [:err, :lower, :upper, :response]
        cefs[!, e] = round.(cefs[!, e]; digits = digits)
    end
    return cefs
end

export process_eftables

function rocpred_plot(efs_dist)
    # cefs_educated = process_eftables(
    #     m1_mrg, :educated, :educated
    # );

    ##

    fg = Figure(resolution = (800, 800));
    
    lc = fg[1:3, 1:3] = GridLayout()
    l1 = lc[1, 1] = GridLayout()
    l2 = lc[2, 1] = GridLayout()
    l3 = lc[3, 1] = GridLayout()
    ll = lc[1:3, 2] = GridLayout()

    ##

    vbl = :distmean
    rel = "free time"
    cefs_dist = process_eftables(
        efs_dist, :distmean, :distmean
    );
    cefs_dist2 = @subset(cefs_dist, $vbl .< 11);
    
    tprs, fprs, dists = rocvalues(cefs_dist2, vbl, rel)
    
    ##

    ax1 = Axis(
        l1[1, 1];
        ygridvisible = false, xgridvisible = false,
        xlabel = "False positive rate", ylabel = "True positive rate"
    )

    mn, mx = extrema(reduce(vcat, dists)) # shared scale
    _rocscatters!(
        ax1, tprs, fprs, dists, mn, mx;
        lb = ("free time kin", "free time non-kin"),
        markers = (:rect, :cross),
    )

    rel = "personal private"
    cefs_dist = process_eftables(
        efs_dist, :distmean, :distmean
    );
    cefs_dist2 = @subset(cefs_dist, $vbl .< 11);
    
    tprs2, fprs2, dists2 = rocvalues(cefs_dist2, vbl, rel)
    _rocscatters!(
        ax1, tprs2, fprs2, dists2, mn, mx;
        lb = ("personal private kin", "personal private non-kin"),
        markers = (:star4, :circle),
    )

    ##
    
    Colorbar(
        ll[1, 1], limits = (mn, mx), colormap = :twilight, vertical = true,
        label = "Mean distance"
    )

    Legend(ll[2, 1], ax1, framevisible = false)

    ##
    
    # colsize!(lc, 2, 0.2)
    # rowsize!(lc, 2, 0.5)

    ##

    vbl = :educated
    rel = "free time"
    cefs_educ = process_eftables(
        efs_educ, :educated, :educated
    );

    ax2 = Axis(
        l2[1, 1];
        ygridvisible = false, xgridvisible = false,
        xlabel = "False positive rate", ylabel = "True positive rate"
    )

    tprs1, fprs1, cats1 = rocvalues(cefs_educ, vbl, rel)
    _rocscatters!(
        ax2, tprs1, fprs1, cats1;
        lb = ("free time kin", "free time non-kin"),
        markers = (:rect, :cross),
    )

    rel = "personal private"
    
    tprs2, fprs2, cats2 = rocvalues(cefs_educ, vbl, rel)
    _rocscatters!(
        ax2, tprs2, fprs2, cats2;
        lb = ("personal private kin", "personal private non-kin"),
        markers = (:star4, :circle),
    )

    cts = sort(unique(reduce(vcat, cats1)))
    clrs_leg = wong[1:length(cts)]

    elems = [
        MarkerElement(
            marker = :circle, color = c, strokecolor = :transparent
        ) for c in clrs_leg
    ]

    Legend(
        ll[3, 1], elems, ["No", "Some", "Yes"], "Educated", framevisible = false
    )

    ##

    vbl = :age
    rel = "free time"
    cefs_age = process_eftables(efs_age, :age, :age);
    
    tprs, fprs, dists = rocvalues(cefs_age, vbl, rel)
    
    ##

    ax3 = Axis(
        l3[1, 1];
        ygridvisible = false, xgridvisible = false,
        xlabel = "False positive rate", ylabel = "True positive rate"
    )

    mn, mx = extrema(reduce(vcat, dists)) # shared scale
    _rocscatters!(
        ax3, tprs, fprs, dists, mn, mx;
        lb = ("free time kin", "free time non-kin"),
        markers = (:rect, :cross),
    )

    rel = "personal private"
    cefs_age = process_eftables(efs_age, :age, :age);
    
    tprs2, fprs2, dists2 = rocvalues(cefs_age, vbl, rel)
    _rocscatters!(
        ax3, tprs2, fprs2, dists2, mn, mx;
        lb = ("personal private kin", "personal private non-kin"),
        markers = (:star4, :circle),
    )

    ##
    
    Colorbar(
        ll[4, 1], limits = (mn, mx), colormap = :twilight, vertical = true,
        label = "Age"
    )

    ##

    for a in [ax1, ax2, ax3]
        lines!(a, 0:0.1:1, 0:0.1:1; linestyle = :dot, color = :grey)
    end

    for (label, layout) in zip(["a", "b", "c"], [l1, l2, l3])
        Label(layout[1, 1, TopLeft()], label,
            # fontsize = 26,
            font = :bold,
            padding = (0, 5, 5, 0),
            halign = :right
        )
    end

    return fg
end

export rocpred_plot
