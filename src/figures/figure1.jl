# figure2.jl

@inline valproc(x) = string(round(x; digits = 1))

"""
        sloperad(pts)

## Description

Calculate the slope in radians given two points.

"""
function sloperad(pts)
    x1, y1 = pts[1]; x2, y2 = pts[2]
    return (y2 - y1) / (x2 - x1) |> atan
end

"""
        roc_panel!(fgloc)

## Description

Make the ROC space explainer panel.

- `fgloc`: _e.g._, `fg[1, 1]`, for a Figure or GridLayout object.
"""
function roc_panel!(fgloc)
    ax = Axis(
        fgloc,
        ylabel = "True positive rate", xlabel = "False positive rate",
        aspect = 1
    )
    xlims!(ax, 0, 1)
    ylims!(ax, 0, 1)

    ul = Point2f[(0, 0), (0, 1), (1, 1)]
    poly!(ax, ul, color = (oi[3], 0.5), strokewidth = 0)
    rl = Point2f[(0, 0), (1, 0), (1, 1)]
    poly!(ax, rl, color = (oi[end-1], 0.5), strokewidth = 0)

    lw = 2
    x1 = 0:0.1:1; y1 = 0:0.1:1; y2 = 1:-0.1:0;
    lines!(ax, x1, y1; color = :black, linewidth = lw)
    # lines!(ax, x1, y2; color = :black, linewidth = lw, linestyle = :dash)

    for xm in -0.8:0.2:0.8
        lines!(ax, x1 .- xm, y2; color = (:black, 1), linewidth = 0.2)
        lines!(ax, x1 .- xm, y1; color = (:black, 1), linewidth = 0.1, linestyle = :dot)
    end

    ε = 0.01
    text!(ax, 0.7-ε, 0.7+ε; rotation = π/4, text = "Chance accuracy")

    pts1 = [Point(0.25, 0.5), Point(0.5, 0.25)];

    let
        x, y = pts1[1]
        a = Point(x, y); b = Point(x, x)
        c = ifelse(x < y, :darkgreen, :darkred)
        lines!(ax, [a, b]; color = (c, 1), linestyle = :dash)

        x, y = pts1[2]
        a = Point(x, y); b = Point(x, x)
        c = ifelse(x < y, :darkgreen, :darkred)
        lines!(ax, [a, b]; color = (c, 1), linestyle = :dash)
    end

    lines!(ax, pts1, linewidth = lw*2, color = oi[end])
    scatter!(ax, pts1, markersize = 15, color = [:black, :red])
    text!(
        ax, 0.25+ε, 0.5+ε; rotation = sloperad(pts1),
        text = "Pure performance change"
    )

    pts1m = Point(0.25-ε*2, 0.5), Point(0.25-ε*2, 0.25);
    bracket!(
        ax, pts1m, text = "J > 0", orientation = :down, rotation = 0,
        textoffset = 20
    )
    pts1m_ = Point(0.5+ε*2, 0.5), Point(0.5+ε*2, 0.25);
    bracket!(
        ax, pts1m_, text = "J < 0", orientation = :up, rotation = 0,
        textoffset = 20
    )

    # 
    pts2 = [Point(0.3, 0.6), Point(0.55, 0.85)];
    lines!(ax, pts2, linewidth = lw*2, color = oi[end])
    scatter!(ax, pts2, markersize = 15, color = [:black, :red])
    text!(
        ax, 0.3-ε, 0.6+ε; rotation = sloperad(pts2),
        text = "Pure error tradeoff"
    )

    #
    pts3 = [Point(0.45, 0.6), Point(0.75, 0.475)];

    norm(pts3[1] - pts3[2])

    lines!(ax, pts3, linewidth = lw*2, color = oi[end])
    scatter!(ax, pts3, markersize = 15, color = [:black, :red])
    text!(
        ax, pts3[1][1]+ε, pts3[1][2]+ε; rotation = sloperad(pts3),
        text = "Impure change"
    )

    #
    elem_1 = [
        MarkerElement(
            color = :black, marker = :circle, markersize = 15, strokecolor = :black
        ),
        MarkerElement(
            color = :red, marker = :circle, markersize = 15, strokecolor = :black
        ),
    ];

    elem_2 = [
        MarkerElement(
            color = (oi[3], 0.5), marker = :rect, markersize = 30,
            stroke = :black, strokewidth = 1
        ),
        MarkerElement(
            color = (oi[end-1], 0.5), marker = :rect, markersize = 30,
            stroke = :black, strokewidth = 1
        ),
    ];

    Legend(fg[1, 2],
        [elem_1, elem_2],
        [["Level 1", "Level 2"], ["Above chance", "Below chance"]],
        ["Attribute", "Performance"], framevisible = false
    );
end

function make_figure1(css, cr, ndf4)

    Random.seed!(2024)

    tiemean = @chain cr begin
        dropmissing([:relation, :response, socio])
        groupby([:perceiver, :relation])
        combine(nrow => :count)
        # groupby([:relation])
        combine([:count => valproc∘x => string(x) for x in [mean, median, mode]]...)
    end
    tiemean = NamedTuple(tiemean[1, :]);

    fg = Figure(figure_padding = 0);
    lo = fg[1:2,1] = GridLayout();
    plo = lo[1:2, 1:3] = GridLayout();
    l2 = fg[1,3] = GridLayout();
    
    rowsize!(lo, 1, Relative(4.5/5))

    los, ps = backgroundplot!(plo, css, ndf4; diagnostic = false)
    
    for i in 1:3; colsize!(plo, i, Aspect(1, 1)) end

    background_legend!(plo)

    roc_panel!(l2[1,1])

    colsize!(lo, 1, Aspect(1, 3))
    rowsize!(plo, 2, Relative(1.2/5))
    rowgap!(plo, -50)
    colgap!(plo, -80)

    return fg
end

export make_figure1

function background_legend!(plo)
    tellwidth = false; tellheight = false;
    valign = :center

    # legend 1
    group_color = [
        MarkerElement(;
            color,
            markersize,
            strokecolor = :transparent,
            marker = :circle,
        ) for (markersize, color) in zip([10, 30], [:black, yale.blues[1]])
    ]

    color_leg = [
        "Community member (\"Alter\")",
        "Survey respondent (\"Cognizer\")"
    ];

    Legend(
        plo[2, 1],
        [group_color],
        [color_leg],
        ["Node type"];
        tellheight,
        tellwidth,
        orientation = :horizontal,
        titleposition = :left,
        valign,
        nbanks = 2, framevisible = false
    )

    # legend 2
    rts = [0.2*4, (2/3)*0.2*3, (2/3)^2*0.2*2, (2/3)^3*0.2, 0];

    space_color = [
        MarkerElement(;
            color = (oi[2], r),
            strokecolor = :black,
            strokewidth = s,
            markersize = 28,
            marker = :circle,
        ) for (r, s) in zip(rts, vcat(fill(1,4), 0))
    ]

    space_leg = vcat(string.(1:4), ">4");

    Legend(
        plo[2, 2],
        [space_color],
        [space_leg],
        ["Cognizer distance"];
        tellheight,
        tellwidth,
        orientation = :horizontal,
        titleposition = :left,
        valign,
        nbanks = 3, framevisible = false
    )

    # legend 3
    line_style = [
        LineElement(;
            color = :black,
            linestyle
        ) for linestyle in [:dot, :solid]
    ]

    line_leg = ["No", "Yes"]
    
    line_color = [
        LineElement(;
            color,
            linestyle = x
        ) for (color, x) in zip([oi[1], oi[6], yale.grays[3]], [:dashdot, :dashdot, :solid])
    ]

    line_color_leg = ["Correct", "Incorrect", "(Not elicited)"]

    Legend(
        plo[2, 3],
        [line_style, line_color],
        [line_leg, line_color_leg],
        ["Tie exists in network", "Response"];
        tellheight,
        tellwidth,
        orientation = :vertical,
        titleposition = :left,
        valign,
        nbanks = 1, framevisible = false
    )
end

# %%

function setup_figure2(bimodel, df; invlink = logistic, socio = socio)

    # calculate marginal effects
    prds = [
        :response,
        :kin431, :relation,
        :age, :man,
        :educated,
        :degree_centrality,
        :dists_p_notinf, :dists_p,
        :dists_a_notinf, :dists_a
    ];

    df = dropmissing(df, prds)

    ed = Dict(
        :relation => sunique(df[!, :relation]),
        kin => sunique(df[!, kin]),
        :dists_p => df[df[!, :dists_p] .!= 0, :dists_p] |> mean,
        :dists_a => df[df[!, :dists_a] .!= 0, :dists_a] |> mean,
        :age => mean(df[!, :age])
    )

    rg = referencegrid(df, ed)
    estimaterates!(rg, bimodel; invlink, iters = 20_000)
    ci_rates!(rg)

    rg.tnr = 1 .- rg.fpr;
    rg.ci_tnr = tuple_addinv.(rg[!, :ci_fpr]);

    # relation-truth-subject-level TPR and FPR (model free)
    # adjusted estimates from "model 1"
    sbar = errors(
        df;
        truth = socio, grouping = [kin, :relation, :perceiver]
    );

    sort!(sbar, [kin, :relation])

    # subject-level averages
    sbar = @chain sbar begin
        dropmissing!()
        @subset! :socio .> 3 ((:count .- :socio) .> 3)
        dropmissing([:tpr, :type1])
        groupby([kin, :relation, :tpr, :type1])
        combine(nrow => :count)
        @subset .!(isnan.(:tpr) .| isnan.(:type1))
        groupby([:relation, kin])
        combine(
            [x => Ref => x for x in [:tpr, :type1, :count]]...
        )
        sort!([:relation, kin])
    end;
    
    sbar.fpr_tpr_bar = [
        tuple(mean(x), mean(y)) for (x, y) in zip(sbar.type1, sbar.tpr)
    ];
    rename!(sbar, :type1 => :fpr)

    inames = intersect(names(rg), names(sbar));
    for x in string.(rates)
        rename!(rg, x => x*"_adj")
    end

    leftjoin!(sbar, rg; on = [kin, :relation])

    # bivariate density kernels
    sbar.dens = Vector{BivariateKDE}(undef, nrow(sbar));
    for i in 1:nrow(sbar)
        sbar.dens[i] = kde((sbar.fpr[i], sbar.tpr[i]))
    end

    return sbar
end

export setup_figure2

function make_figure2(
    sbar, bpd; nlevels = 10, colormap = berlin
)
    
    fg = Figure();
    l = fg[1, 1] = GridLayout();
    l1_ = l[1, :] = GridLayout();
    l2_ = l[2, :] = GridLayout();
    
    perceivercontour!(
        l1_, sbar; kin, nlevels, colormap,
    );

    ellipsecolor = (yale.grays[end-1], 0.3)
    dropkin_eff = true
    tnr = true
    kinlegend = false

    l1 = l2_[1, 1] = GridLayout();
    ll = l2_[1, 2] = GridLayout();
	l2 = l2_[1, 3] = GridLayout();

    rocplot!(
        l1,
        bpd.rg, bpd.margvar, bpd.margvarname;
        ellipsecolor,
        markeropacity = 0.8,
        kinlegend,
        dolegend = false
    )

    ll1 = ll[1, 1] = GridLayout()
    ll2 = ll[2, 1] = GridLayout()
    rowsize!(ll, 1, Relative(2.2/3))

    roclegend!(
        ll1, bpd.rg[!, bpd.margvar], bpd.margvarname, true, ellipsecolor, true;
        kinlegend = false,
    )

    effectsplot!(
        l2, bpd.rg, bpd.margvar, bpd.margvarname, tnr;
        dropkin = dropkin_eff,
        dolegend = false
    )

    effectslegend!(ll2[1, 1], true, true, false; tr = 0.6)
    #     colsize!(l, 2, Auto(0.2))
    #     colgap!(l, 20)

    labelpanels!([l1_, l2_])
    
    rowsize!(l, 1, Relative(2/3))
    #colsize!(l2_, 1, Relative(2/3))
    
    return fg
end

export make_figure2
