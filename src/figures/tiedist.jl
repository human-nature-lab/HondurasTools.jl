# tiedist.jl

function tiedist_plot(
    css;
    fg = Figure(resolution = (1000, 800)),
    socio = :socio4, kin = :kin431, cg = cg, prj = prj,
    saveplot = true
)
    x = @chain css begin
        groupby([cg.p, cg.r, socio, kin])
        combine(nrow => :n)
        groupby([cg.r, socio, kin])
        combine(:n => Ref => :n)
    end

    x2 = @chain css begin
        @subset :relation .== rl.ft
        groupby([cg.p, cg.r, :union4, kin])
        combine(nrow => :n)
        groupby([cg.r, :union4, kin])
        combine(:n => Ref => :n)
        sort([:union4, kin])
    end
    replace!(x2.relation, "free_time" => "union")
    rename!(x2, :union4 => :socio4)

    x = vcat(x, x2)
    x.relation = replace.(unwrap.(x.relation), "_" => " ")

    rloc = Dict("free time" => 1, "personal private" => 2, "union" => 3)
    tloc = Dict(false => 1, true => 2)

    # axis positions
    x.l_ = fill(0, nrow(x));
    x.p_ = [(0,0) for _ in  1:nrow(x)];

    for (i_, r) in (enumerate∘eachrow)(x)
        x.l_[i_] = tloc[r[socio]]
        x.p_[i_] = (rloc[r[:relation]], tloc[r[kin]])
    end
    
    los = []; axs = []

    for x in [1:3, 4:6]
        lo = fg[x, 1:2] = GridLayout()
        push!(los, lo)
    end
           
    for r in eachrow(x)
        lx = los[r[:l_]]
        
        ttl = if (r[:p_] == (1,1)) | (r[:p_] == (1,2))
            "kin: " * string(r[kin])
        else ""
        end
        
        if r[:p_][2] == 1
            a = rloc[r[:relation]]
            Label(lx[a, 0], r[:relation], rotation = pi/2,
            tellheight = false)
        else ""
        end

        ax = Axis(
            lx[r[:p_]...],
            ygridvisible = false, xgridvisible = false, title = ttl
        )
        clr = ifelse(r[socio], wc[1], wc[6]) # match sampled plot
        hist!(ax, r.n, bins = 10, color = clr)
        vlines!(ax, mean(r.n), color = :black)
        push!(axs, ax)
    end

    labelpanels!(los)

    yd = @chain css begin
        groupby([:union4, :relation, :perceiver])
        combine(nrow => :n)
        groupby([:union4, :relation])
        combine(:n => mean => :mean)
        sort([:union4, :relation])
    end
    ftf = stround(yd.mean[1])
    ftt = stround(yd.mean[3])

    cap = "Distributions of sampled ties. Distribution of number of pairs displayed to each respondent for ties that (A) do not and (B) do exist, stratified by each relationship and kin status. The *union* relation represents the union of the *free time*, *personal private* and *kin* networks, and was the basis for sampling. In the union network, we sampled " * ftf * " false ties and " * ftt * " true ties."

    if saveplot
        savemdfigure(prj.pp, prj.css, "tie-counts", cap, fg)
    end

    fg
end

export tiedist_plot
