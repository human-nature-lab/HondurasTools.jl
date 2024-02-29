# pairdist_plot.jl

function pairdist!(lo, crj)
    l1 = lo[1, 1:3] = GridLayout()
    l2 = lo[2, 1:3] = GridLayout()
    l3 = lo[3, 1:3] = GridLayout()
    los = []

    crjt = @chain crj begin
        groupby([:man, :socio4])
        combine(nrow => :n)
        transform(:man => ByRow(levelcode) => :man_code)
        dropmissing()
    end

    let lx = l1, df = crjt;
        lo = lx[1,1] = GridLayout();
        dodge = df[!, :socio4]*1 .+1
        xtick2 = levels(df[!, :man])
        xtick1 = eachindex(xtick2)
        color = ifelse.(df[!, :socio4], wc[5], wc[6])
        ax1 = Axis(lo[1,1], xticks = (xtick1, xtick2), xticklabelrotation = 0.0)
        barplot!(ax1, df[!, :man_code], df[!, :n]; dodge, color)
        push!(los, lo)
    end

    v = :isindigenous
    crjt = @chain crj begin
        groupby([v, :socio4])
        combine(nrow => :n)
        transform(v => ByRow(levelcode))
        dropmissing()
    end

    let lx = l1, df = crjt, v = v;
        vc = Symbol(string(v) * "_levelcode")
        lo = lx[1,2] = GridLayout();
        dodge = df[!, :socio4]*1 .+1
        xtick2 = levels(df[!, v])
        xtick1 = eachindex(xtick2)
        color = ifelse.(df[!, :socio4], wc[5], wc[6])
        ax1 = Axis(
            lo[1,1], xticks = (xtick1, xtick2), xticklabelrotation = 0.0)
        barplot!(ax1, df[!, vc], df[!, :n]; dodge, color)
        push!(los, lo)
    end

    v = :religion;
    crjt = @chain crj begin
        groupby([v, :socio4])
        combine(nrow => :n)
        @subset :religion .∈ Ref([ "Catholic"
        # "Catholic, No Religion"
        # "No Religion"
        "Protestant"
        "Protestant, Catholic"
        # "Protestant, No Religion"
        ])
    end
    droplevels!(crjt[!, v])
    recode!(crjt[!, v])
    crjt = @chain crjt begin
        transform(v => ByRow(levelcode))
        dropmissing()
    end
    levels(crjt[!, v])
    levelcode.(crjt[!, v])
    recode!(crjt.religion, "Protestant, Catholic" => "Mixed")
    let lx = l1, df = crjt, v = :religion;
        vc = Symbol(string(v) * "_levelcode")
        lo = lx[1,3] = GridLayout();
        dodge = df[!, :socio4]*1 .+1
        xtick2 = levels(df[!, v])
        xtick1 = eachindex(xtick2)
        color = ifelse.(df[!, :socio4], wc[5], wc[6])
        ax1 = Axis(
            lo[1,1], xticks = (xtick1, xtick2), xticklabelrotation = 0.0)
        barplot!(ax1, df[!, vc], df[!, :n]; dodge, color)
        push!(los, lo)
    end

    # for (l, r) in zip(los, [.7,.7,1.2])
    #     colsize!(l, 1, Aspect(1, r))
    # end

    let lx = l2, df = crj, v = :degree_centrality_diff;
        df2 = dropmissing(df, [v, :socio4])
        lo = lx[1,1] = GridLayout();
        ax1 = Axis(
            lo[1,1], xlabel = string(v))
            hist!(ax1, df2[.!df2[!, :socio4], v], color = (wc[6], 1.0), nbins = 30)
            hist!(ax1, df2[df2[!, :socio4], v], color = (wc[5], 1.0), nbins = 30)
        push!(los, lo)
    end

    let lx = l2, df = crj, v = :betweenness_centrality_diff;
        df2 = dropmissing(df, [v, :socio4])
        lo = lx[1,2] = GridLayout();
        ax1 = Axis(
            lo[1,1], xlabel = string(v))
        hist!(ax1, df2[.!df2[!, :socio4], v], color = (wc[6], 1.0), nbins = 30)
        hist!(ax1, df2[df2[!, :socio4], v], color = (wc[5], 1.0), nbins = 30)
        push!(los, lo)
    end

    let lx = l2, df = crj, v = :age_diff;
        df2 = dropmissing(df, [v, :socio4])
        lo = lx[1,3] = GridLayout();
        ax1 = Axis(
            lo[1,1], xlabel = string(v))
        hist!(ax1, df2[.!df2[!, :socio4], v], color = (wc[6], 1.0), nbins = 30)
        hist!(ax1, df2[df2[!, :socio4], v], color = (wc[5], 1.0), nbins = 30)
        push!(los, lo)
    end

    let lx = l3, df = crj, v = :degree_centrality_mean;
        df2 = dropmissing(df, [v, :socio4])
        lo = lx[1,1] = GridLayout();
        ax1 = Axis(
            lo[1,1], xlabel = string(v))
            hist!(ax1, df2[.!df2[!, :socio4], v], color = (wc[6], 1.0), nbins = 30)
            hist!(ax1, df2[df2[!, :socio4], v], color = (wc[5], 1.0), nbins = 30)
        push!(los, lo)
    end

    let lx = l3, df = crj, v = :betweenness_centrality_mean;
        df2 = dropmissing(df, [v, :socio4])
        lo = lx[1,2] = GridLayout();
        ax1 = Axis(
            lo[1,1], xlabel = string(v))
        hist!(ax1, df2[.!df2[!, :socio4], v], color = (wc[6], 1.0), nbins = 30)
        hist!(ax1, df2[df2[!, :socio4], v], color = (wc[5], 1.0), nbins = 30)
        push!(los, lo)
    end

    let lx = l3, df = crj, v = :age_mean;
        df2 = dropmissing(df, [v, :socio4])
        lo = lx[1,3] = GridLayout();
        ax1 = Axis(
            lo[1,1], xlabel = string(v))
        hist!(ax1, df2[.!df2[!, :socio4], v], color = (wc[6], 1.0), nbins = 30)
        hist!(ax1, df2[df2[!, :socio4], v], color = (wc[5], 1.0), nbins = 30)
        push!(los, lo)
    end
end

export pairdist!
