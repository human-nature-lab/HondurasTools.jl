# biplot.jl

function biplotdata(
    bimodel, effectsdicts, dats, vbl; invlink = invlink
)
    # add focal variable to a copy of effectsdicts
    ed = deepcopy(effectsdicts)
    for r in rates
        ed[r][vbl] = (unique∘skipmissing∘vcat)(dats[:tpr][!, vbl], dats[:fpr][!, vbl])
    end
    rgs = referencegrid(dats, ed)
    apply_referencegrids!(bimodel, rgs; rates, invlink)
    ci!(rgs)

    mrg = bidatajoin(rgs);
    truenegative!(rgs)
    mrg_l = bidatacombine(rgs)
    
    dropmissing!(mrg, [vbl, kin])
    dropmissing!(mrg_l, [vbl, kin])

    return (margins = mrg, marginslong = mrg_l, dict = ed, margvar = vbl,)
end

export biplotdata

function biplot!(
    plo,
    bpd;
    jdf = nothing,
    ellipse = false,
    markeropacity = 0.5,
    marginaxiskwargs...
)

    ##
    
    lroc = plo[1, 1] = GridLayout();
    colsize!(lroc, 1, Aspect(1, 1))
    lef = plo[1, 2] = GridLayout();
    colsize!(lef, 1, Aspect(1, 1))

    colgap!(plo, -50)

    rocplot!(
        lroc, lroc[2, 1], bpd[:margins], bpd[:margvar];
        ellipse, jdf, legtitle = marginaxiskwargs[:xlabel],
        markeropacity
    )
    
    effectsplot!(
        lef, lef[2, 1],
        bpd;
        jdf, marginaxiskwargs...
    )

    rowsize!(lroc, 1, Relative(4/5))
    rowsize!(lef, 1, Relative(4/5))

    return plo
end

export biplot!

function biplot(
    vbl, dats, effectsdicts, bimodel, lo, xlabel;
    invlink = identity, markeropacity = 0.5
)
    
    bpdata = biplotdata(
        bimodel, effectsdicts, dats, vbl; invlink
    );

    biplot!(lo, bpdata; xlabel, markeropacity)
    #for i in 1:2; colsize!(lo, i, Aspect(1, 1)) end
    # rowsize!(lo, 1, Aspect(1, 2))
end

export biplot
