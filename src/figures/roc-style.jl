# roc-style.jl

#| label: fig-roc-1
#| fig-scap: "True positive rate vs. false positive rate"
#| fig-cap: "True positive rate vs. false positive rate for (a) *free time* and (b) *personal private*. Observations are respondent-level means, where each individual perceiver may be thought of as a binary classifier. The dotted line  ($y = x$) indicates that a classifier that performs at the level of random chance. Points along the line $y = 1 - x$ perform more (above, green line) or less accurately (below, red line). Darker (less transparent) colors indicate a greater density of points at a coordinate."

function roclikedot!(lo, edf)

    edf.fpr = edf.type1;

    lo1 = lo[1, 1] = GridLayout()
    lop = lo1[1, 1] = GridLayout()
    lop2 = lop[1:2, 1:2] = GridLayout()
    ll = lo1[1,2] = GridLayout()
    
    los = []; axs = [];

    # for t in [:tpr, :fpr]; edf[!, t] = round.(edf[!, t]; digits = 3) end

    edfg = @chain edf begin
        groupby([:kin431, :relation, :tpr, :fpr])
        combine(nrow => :count)
        @subset .!(isnan.(:tpr) .| isnan.(:fpr))
        groupby([:relation, :kin431])
        combine(
            [x => Ref => x for x in [:tpr, :fpr, :count]]...
        )
    end;

    sort!(edfg, [:kin431, :relation])

    pdict = Dict(
        ("free_time", false) => (1,1),
        ("free_time", true) => (2,1),
        ("personal_private", false) => (1,2),
        ("personal_private", true) => (2,2)
    );

    los = []; axs = [];
    for i in 1:nrow(edfg)

        ps = pdict[(edfg.relation[i], edfg[i, kin])]
        li = GridLayout(lop2[ps...])

        ax = Axis(
            li[1, 1];
            ylabel = "True positive rate (sensitivity)",
            xlabel = "False positive rate (specificity)",
            xgridvisible = false, ygridvisible = false,
            title = replace(unwrap(edfg.relation[i]), "_" => " ")
        )
        push!(los, li)
        push!(axs, ax)
    end

    dts = []

    for (i, r) in (enumerate∘eachrow)(edfg)
        lines!(axs[i], 0:0.1:1, 0:0.1:1; linestyle = :dot, color = :grey)
        
        vlines!(axs[i], [0, 1], color = (:black, 0.3))
        hlines!(axs[i], [0, 1], color = (:black, 0.3))

        dt = scatter!(axs[i], r[:fpr], r[:tpr], color = (wc[1], 0.3))

        push!(dts, dt)

        # line of chance
        lines!(axs[i], (1:-0.1:0.5), 0:0.1:0.5; linestyle = :solid, color = wong[6])
        # line of improvement
        lines!(axs[i], (0.5:-0.1:0), 0.5:0.1:1; linestyle = :solid, color = wong[3])
        ylims!(axs[i], -0.02,1.02)
        xlims!(axs[i], -0.02,1.02)
    end

    labelpanels!(los[[1,3]])

    return los, lo1
end

export roclikedot!

function roclikedot_contour!(
    lo, edf; saveplot = true, ttl = "roc-vill",  nlevels = 10
)

    edf.fpr = edf.type1;

    lo1 = lo[1, 1] = GridLayout()
    lop = lo1[1, 1] = GridLayout()
    lop2 = lop[1:2, 1:2] = GridLayout()
    ll = lo1[1,2] = GridLayout()
    
    los = []; axs = [];

    # for t in [:tpr, :fpr]; edf[!, t] = round.(edf[!, t]; digits = 3) end

    edfg = @chain edf begin
        groupby([:kin431, :relation, :tpr, :type1])
        combine(nrow => :count)
        @subset .!(isnan.(:tpr) .| isnan.(:type1))
        groupby([:relation, :kin431])
        combine(
            [x => Ref => x for x in [:tpr, :type1, :count]]...
        )
    end;

    edfg.dens = Vector{BivariateKDE}(undef, nrow(edfg));

    for i in 1:nrow(edfg)
        edfg.dens[i] = kde((edfg.type1[i], edfg.tpr[i]))
    end

    lv = range(
        extrema(reduce(vcat, [x.density for x in edfg.dens]))...;
        length = nlevels
    )

    sort!(edfg, [:kin431, :relation])

    pdict = Dict(
        ("free_time", false) => (1,1),
        ("free_time", true) => (2,1),
        ("personal_private", false) => (1,2),
        ("personal_private", true) => (2,2)
    )

    los = []; axs = [];
    for i in 1:nrow(edfg)

        ps = pdict[(edfg.relation[i], edfg[i, kin])]
        li = GridLayout(lop2[ps...])

        ax = Axis(
            li[1, 1];
            ylabel = "True positive rate (sensitivity)",
            xlabel = "False positive rate (specificity)",
            xgridvisible = false, ygridvisible = false,
            title = replace(unwrap(edfg.relation[i]), "_" => " ")
        )
        push!(los, li)
        push!(axs, ax)
    end

    dts = []

    for (i, r) in (enumerate∘eachrow)(edfg)
        # line of chance
        lines!(axs[i], 0:0.1:1, 0:0.1:1; linestyle = :dot, color = :grey)
        
        vlines!(axs[i], [0, 1], color = (:black, 0.3))
        hlines!(axs[i], [0, 1], color = (:black, 0.3))

        co = contour!(
            axs[i], r.dens,
            levels = lv,
            colormap = :berlin,
        )
        dt = scatter!(axs[i], r[:type1], r[:tpr], color = (wc[1], 0.3))

        push!(dts, dt)
        
        # line of improvement
        lines!(axs[i], (1:-0.1:0.5), 0:0.1:0.5; linestyle = :solid, color = wong[6])
        lines!(axs[i], (0.5:-0.1:0), 0.5:0.1:1; linestyle = :solid, color = wong[3])
        ylims!(axs[i], -0.02,1.02)
        xlims!(axs[i], -0.02,1.02)
    end

    labelpanels!(los[[1,3]])

    caption = "Bivariate distribution of village accuracies, represented as the true positive vs. false positive rate. Observations are respondent-level means, where each individual perceiver may be thought of as a binary classifier. The dotted line  (\$y = x\$) indicates that a classifier that performs at the level of random chance. Points along the line \$y = 1 - x\$ perform more (green segment) or less accurately (red segment). Responses are separated for ties that are between (A) non-kin or (B) kin. N = 82 villages."

    if saveplot
        savemdfigure(prj.pp, prj.css, ttl, caption, fg)
    end
    return los, lo1
end

function roc_village(cr; ttl = "roc-vill", saveplot = true)
    edf = errors(
        cr;
        truth = :socio4, grouping = [kin, :relation, ids.vc]
    )

    dropmissing!(edf, [:tpr, :type1])
    
    fg = Figure(backgroundcolor = :transparent)
    l_ = fg[1,1] = GridLayout();
    # lo1_ = l_[1,1] = GridLayout();
    # lo2_ = l_[1,2] = GridLayout();

    los, lo1 = roclikedot!(l_, edf)

    edf_ = @chain edf begin
        groupby([:relation, :kin431])
        combine([x => Ref => x for x in [:tpr, :tnr]])
        @subset .!:kin431
    end

    # ax2 = lo2_[1,1] = Axis(fg);
    # ax3 = lo2_[2,1] = Axis(fg);

    # hist!(ax2, edf_[2, :tpr], bins = 30);
    # hist!(ax3, edf_[2, :tnr], bins = 30);
    # fg

    for lx in los
        colsize!(lx, 1, Aspect(1, 1.0))
    end
    colsize!(lo1, 1, Aspect(1, 1.0))

    # colsize!(fg.layout, 1, Relative(2.5/3))
    # colsize!(l_, 2, Aspect(1, .5))
    # colsize!(fg.layout, 1, Aspect(1, 1.5))
    
    resize_to_layout!(fg)
    
    caption = "Bivariate distribution of village accuracies, represented as the true positive vs. false positive rate. Observations are respondent-level means, where each individual perceiver may be thought of as a binary classifier. The dotted line  (\$y = x\$) indicates that a classifier that performs at the level of random chance. Points along the line \$y = 1 - x\$ perform more (green segment) or less accurately (red segment). Responses are separated for ties that are between (A) non-kin or (B) kin. N = 82 villages."

    if saveplot
        savemdfigure(prj.pp, prj.css, ttl, caption, fg)
    end

    return fg
end

export roc_village

