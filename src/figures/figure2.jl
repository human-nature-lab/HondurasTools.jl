# figure2.jl

@inline valproc(x) = string(round(x; digits = 1))

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
    lo = fg[1:2,1] = GridLayout()
    plo = lo[1:2, 1:3] = GridLayout();
    rowsize!(lo, 1, Relative(4.5/5))

    los, ps = backgroundplot!(plo, css, ndf4; diagnostic = false)
    
    for i in 1:3; colsize!(plo, i, Aspect(1, 1)) end

    tellwidth = false; tellheight = false;
    valign = :center

    # legend 1
    group_color = [
        MarkerElement(;
            color,
            markersize,
            strokecolor = :transparent,
            marker = :circle,
        ) for (markersize, color) in zip([10, 30], [:black, yale.blue])
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
        ) for (color, x) in zip([oi[1], oi[6], yale.mgrey], [:dashdot, :dashdot, :solid])
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

    # Box(plo[2,1], color = (:red, 0.))
    # Box(plo[2,2], color = (:green, 0.))
    # Box(plo[2,3], color = (:blue, 0.))

    colsize!(lo, 1, Aspect(1, 3))
    rowsize!(plo, 2, Relative(1.2/5))
    rowgap!(plo, -50)
    colgap!(plo, -80)

    return fg
end

export make_figure1

function make_figure2(m0a, m0b, m0c, m1, crs, cr)
    invlink = logistic;

    # calculate marginal effects
    prds = [
        :response,
        :kin431, :relation,
        :age, :man,
        :educated,
        :degree_centrality,
        :dists_p_notinf, :dists_p
    ];

    regvars = [
        :age, :man, :educated,
        # exclude repeated-within-subject variables
        # :degree_centrality,
        # :kin431, # => set kin431 to false
        # :relation,
        # :dists_p_notinf, :dists_p_i, 
        # only for convenience
        :perceiver, :village_code
    ];

    dats = let
        crt2 = dropmissing(crs.tpr, prds);
        crf2 = dropmissing(crs.tpr, prds);

        sort!(crt2, [:perceiver, :order]);
        sort!(crf2, [:perceiver, :order]);
        bidata(crt2, crf2)
    end;

    # dictionary of variable values / ranges for the reference grid
    effectsdicts = let df = cr
        df = dropmissing(cr, [:relation, kin, :dists_p, :dists_a])

        d1 = Dict(
            :relation => sunique(df[!, :relation]),
            kin => sunique(df[!, kin]),
            :dists_p => df[df[!, :dists_p] .!= 0, :dists_p] |> mean,
            :age => (mean∘skipmissing)(df[!, :age])
        )

        df = @subset(df, .!($socio)); # only false ties -> range is correct
        d2 = deepcopy(d1)
        d2[:dists_a] = df[df[!, :dists_a] .!= 0, :dists_a] |> mean

        (tpr = d1, fpr = d2, )
    end

    # marginal effects

    modelnames = ["m0a", "m0b", "m1i"];
    model_legend = reduce(
        vcat,
        fill(["1", "2", "3"], 2)
    );

    function make_bf(dats, effectsdicts)
        bef = referencegrid(dats, effectsdicts);
        bf = deepcopy(bef[:fpr])
        for r in [:tpr, :fpr, :j]
            bf[!, r] .= NaN
            bf[!, Symbol(string(r) * "_err")] .= NaN
        end
        return bf
    end

    mdf = let
        mn = [:m1, :ma, :mb, :mc];
        # construct reference grids    
        bfs = [make_bf(dats, effectsdicts) for e in mn]

        for (i, (m, m_)) in (enumerate∘zip)([m1, m0a, m0b, m0c], mn)
            bieffects!(bfs[i], m, invlink; rates)
            bfs[i].model .= m_
        end

        mdf = reduce(vcat, bfs)
        sort!(mdf, :model)

        # marginal effects across models
        for q in rates
            mdf[!, Symbol(string(q) * "_ci")] = ci.(
                mdf[!, q], mdf[!, Symbol(string(q)*"_err")]
            )
        end

        mdf.tnr = 1 .- mdf.fpr
        mdf.tnr_ci = tuple_addinv.(mdf[!, :fpr_ci])
        mdf
    end

    # relation-truth-subject-level TPR and FPR (model free)
    # adjusted estimates from "model 1"
    sbar = let
        sbar = errors(
            cr;
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

        mdf_model = @subset(mdf, :model .== (Symbol("m1")));
        inames = intersect(names(mdf_model), names(sbar));
        for x in string.(rates)
            rename!(mdf_model, x => x*"_adj")
        end

        leftjoin!(sbar, mdf_model; on = [kin, :relation])

        sbar
    end

    # bmcp0 = (tpr = coefplotdata(m0a.tpr), fpr = coefplotdata(m0a.fpr));
    # bmcp = (tpr = coefplotdata(m1.tpr), fpr = coefplotdata(m1.fpr));
    # bmcp1i = (tpr = coefplotdata(m1i.tpr), fpr = coefplotdata(m1i.fpr));

    # models = [bmcp0, bmcp];


    figure2 = let sbar = sbar
        fg = Figure();
        l_ = fg[1, 1] = GridLayout();

        # plot bivariate distribution
        perceivercontour!(
            l_, sbar; kin = :kin431, nlevels = 10, colormap = :berlin,
        )

        # l_coef = coefficientbiplot!(
        #     gb, models;
        #     cnames = union(models[2].tpr.names, models[2].fpr.names)
        # )

        caption = "Coefficient plot. Coefficients for TPR (blue) and FPR (red) models. Coefficients are reported if they show up as significant in at least one of the two models. All numeric covariates are standardized to the unit range. Coefficients are unadjusted from logistic model. Observe that alter-alter distances only appear in FPR model."

        fg
    end;

    resize!(figure2, 800, 800)
    resize_to_layout!(figure2)
    return figure2
end

export make_figure2
