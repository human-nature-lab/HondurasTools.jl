# ratetradeoff.jl

@inline rotation(θ) =  [cos(θ) -sin(θ); sin(θ) cos(θ)]

"""
        ratetradeoff(jvals, fprvals)

## Description

Calculate the tradeoff (x) vs. strictchange (y) measure for a variable, using the maximum and minimum j points.

N.B., when rotation is -π/4, transform is (x,y) -> (x+y)/sqrt(2), (x-y)/sqrt(2)

"""
function ratetradeoff(fprvals, tprvals; θ = -π/4)
    pts = Point2f.(fprvals, tprvals)
    ptst = [rotation(θ) * pt for pt in pts]
    xt = [pt[1] for pt in ptst]
    yt = [pt[2] for pt in ptst]

    xtmn, xtmx = extrema(xt)
    ytmn, ytmx = extrema(yt)

    return Point2f(xtmx - xtmn, ytmx - ytmn)
end

"""
        ratetradeoffs(rdf, variables)

## Description

Calculate the tradeoff (x) vs. strictchange (y) measures for each. Where x is the transformed (by 45 degrees, to a basis formed by y=x, and y=1-x) maximum fpr difference, and y is the transformed (by 45 degrees, to a basis formed by y=x, and y=1-x) maximum J.

`rdf`: The marginal effects DataFrame, including each variable with column `variable`.

"""
function ratetradeoffs(rdf::AbstractDataFrame, variables)
    tradeoffs = Dict{Symbol, Point2f}();
    for e in variables
        if Symbol(e) ∈ rdf.variable
            idx = rdf[!, :variable] .== e
            
            jvals = rdf[idx, :j]
            fprvals = rdf[idx, :fpr]
            
            tradeoffs[e] = ratetradeoff(jvals, fprvals)
        else @warn string(e) * " not in rdf"
        end
    end
    return tradeoffs
end

"""
        ratetradeoffs(md, variables)

## Description

Calculate the tradeoff (x) vs. strictchange (y) measures for each. Where x is the transformed (by 45 degrees, to a basis formed by y=x, and y=1-x) maximum fpr difference, and y is the transformed (by 45 degrees, to a basis formed by y=x, and y=1-x) maximum J.

`md`: Is a dictionary of marginal effects DataFrames, including each variable with column `variable`.

"""
function ratetradeoffs(md::T, variables) where T<:Dict
    tradeoffs = Dict{Symbol, Point2f}();
    for e in variables
        m = get(md, e, nothing)
        if !isnothing(md)
            rg = m.rg
            rg = @subset rg .!$kin

            # jvals = rg[!, :j]
            fprvals = rg[!, :fpr]
            tprvals = rg[!, :tpr]
            
            tradeoffs[e] = ratetradeoff(fprvals, tprvals; θ = -π/4)
        else @warn string(e) * " not in md"
        end
    end
    return tradeoffs
end

export ratetradeoff, ratetradeoffs

@inline polarback(r, θ) = r*cos(θ), r*sin(θ)

function tradeoffdata(md)

    # remove these, since not sig
    rms = [:religion_c, :man, :isindigenous_a];
    rms_ = ["Within-tie distance", "Indigeneity"];


    # remove no path entries, since we only want to include the real range
    @subset!(md[:dists_p].rg, :dists_p_notinf);
    @subset!(md[:dists_a].rg, :dists_a_notinf);

    prds = [
        :relation,
        :age,
        :man,
        :educated,
        :degree,
        :dists_p,
        # :dists_a,
        :man_a,
        :age_mean_a,
        :age_diff_a,
        :religion_c,
        :religion_c_a,
        :isindigenous_a,
        :degree_mean_a,
        :degree_diff_a,
        :wealth_d1_4, 
        :wealth_d1_4_mean_a,
        :wealth_d1_4_diff_a,
        :educated_a,
        :coffee_cultivation
    ];

    trades = ratetradeoffs(md, prds)

    nm = String[]
    for (κ, ω) in md
        push!(nm, split(ω.name, " (")[1])
    end

    nm = setdiff(nm, rms_)
    unique!(nm)

    cscheme = colorschemes[:seaborn_colorblind];
    cdict = Dict(nm .=> cscheme[1:length(nm)]);
    cdict["Coffee cultivation"] = cscheme[end]

    for x in rms_; delete!(cdict, x) end

    tdf = DataFrame(
        :variable => Symbol[], :name => String[], :type => String[],
        :x => AbstractFloat[], :y => AbstractFloat[], :rto => AbstractFloat[]
    )

    for (k, v) in trades
        vnm = md[k].name
        vnm2 = split(vnm, " (")[1]
        sk = string(k)
        t_ = if occursin("(difference)", vnm)
            "Difference"
        elseif occursin("(mean)", vnm)
            "Mean"
        elseif occursin("_a", sk)
            "Combination"
        else "Cognizer"
        end
        push!(tdf, [k, vnm2, t_, v[1], v[2], v[2]*inv(v[1])])
    end

    tdf[findfirst(tdf.variable .== Symbol("relation")), :type] = "Combination"
    tdf[findfirst(tdf.variable .== Symbol("dists_p")), :type] = "Mean"

    sort!(tdf, :rto)

    # remove non-significant effects
    vs = setdiff(tdf.variable, rms)
    @subset!(tdf, :variable .∈ Ref(vs))
    return tdf
end

export tradeoffdata

function scatter_ratio!(lp, tdf)
    yticks_ = (eachindex(tdf[!, :name]), tdf[!, :Name]);
    ax = Axis(
        lp,
        xlabel = "Performance-tradeoff ratio (ΔJ/ΔPPB)",
        yticks = yticks_,
        xticks = 0:0.5:2.5
    );
        
    vlines!(ax, 1; color = :black, linestyle = :dash)
    mxr = maximum(tdf.rto)
    for u in 2:nrow(tdf)
        hlines!(ax, u-0.5, mxr;
        color = (yale.grays[2], 0.1), linestyle = :solid)
    end

    scatter!(
        ax, tdf[!, :rto], eachindex(tdf.variable);
        color = :black, markersize = 15
        #  marker = tdf.shape
    )

    xlims!(ax, high = 2.5)

    return ax
end

export scatter_ratio!

function scatter_values!(lp, tdf; rescale = true)
    # tdf = sort(tdf, :y)

    yticks_ = (eachindex(tdf[!, :name]), tdf[!, :Name]);
    yticks_ = ([],[])
    ax = Axis(
        lp;
        xlabel = "Absolute maximum change",
        yticks = yticks_,
        xticks = 0:0.1:0.7
    );
    
    # vlines!(ax, 0; color = :black, linestyle = :dash)

    mxr = maximum(tdf.rto)
    for u in 2:nrow(tdf)
        hlines!(ax, u-0.5, mxr;
        color = (yale.grays[2], 0.1), linestyle = :solid)
    end

    rs = ifelse(rescale, sqrt(2), 1)
    scatter!(
        ax, tdf[!, :y] * rs, eachindex(tdf.variable);
        color = (columbia.blues[1], 0.8), markersize = 15
    )
    scatter!(
        ax, tdf[!, :x] * rs, eachindex(tdf.variable);
        color = (yale.accent[2], 0.8), markersize = 15
    )

    xlims!(ax, high = 0.7)
    return ax
end

export scatter_values!

function ratediagramdata(md, e)
    rg, _ = md[e]
    # bpd = (
    #     rg = rg, margvar = e, margvarname = margvarname,
    #     tnr = true, jstat = true
    # );
    rg = @subset md[e].rg .!:kin431
    return Point2f.(rg.fpr, rg.tpr)
end

export ratediagramdata

function ratediagram!(l, pts)
    dheight = 225
    
    l_ = GridLayout(l[1:2, 1:2])

    # arrow
    axb = Axis(
        l_[1, 1:2];
        backgroundcolor = :transparent
    )
    hidedecorations!(axb)
    hidespines!(axb)
    ylims!(axb, -1.0, 1.0)
    xl = [-1.5, 1.5]
    xlims!(axb, xl...)

    pa = π*(3/4)*0.875
    # pa, π - pa;
    arc!(
        axb,
        Point2f(0, 0.1), 0.85, pa, π - pa;
        linestyle = :dash,
        linewidth = 4,
        color = (columbia.secondary[5], 0.75)
    )

    text!(axb, mean(xl) - 0.08, 0.75; text = L"45^{\circ}", fontsize = 24)
    text!(
        axb, mean(xl) - 0.08 + 0.6, 0.85,
        text = L"\text{Rescale by } \sqrt{2}",
        fontsize = 20
    )

    ptx = Point2f[
        polarback(0.95, 0.05 + π - pa - π/24),
        polarback(1., 0.05 + π - pa),
        polarback(0.9, 0.05 + π - pa)
    ]
    poly!(
        axb, ptx,
        color = :black, strokecolor = columbia.secondary[5],
        strokewidth = 1
    )

    ##
    l1 = GridLayout(l[1:2, 1]);
    l2 = GridLayout(l[1:2, 2]);
    # l3 = GridLayout(l[1, 3]);

    ax1 = Axis(
        l1[1, 1];
        aspect = 1,
        ylabel = "True positive rate", xlabel = "False positive rate",
        height = dheight,
        title = L"(x, y)",
        titlesize = 20
    )

    ul = Point2f[(0, 0), (0, 1), (1, 1)]
    poly!(ax1, ul, color = (oi[3], 0.5), strokewidth = 0)
    rl = Point2f[(0, 0), (1, 0), (1, 1)]
    poly!(ax1, rl, color = (oi[end-1], 0.5), strokewidth = 0)

    lw = 2
    x1 = 0:0.1:1; y1 = 0:0.1:1
    lines!(ax1, x1, y1; color = :black, linewidth = lw)

    endpts = [first(pts), last(pts)]
    lines!(ax1, pts, linewidth = 4, color = oi[end])
    scatter!(ax1, endpts, color = [:red, :black], markersize = 10)

    ylims!(ax1, 0, 1)
    xlims!(ax1, 0, 1)

    ##
    θ = -π/4;
    ptst = Point2f.([HondurasCSS.rotation(θ) * pt * sqrt(2) for pt in pts])

    dgt = 1
    yext = [0*sqrt(2), round(0.5*sqrt(2); digits = dgt)]
    xext = [round(0.4*sqrt(2); digits = dgt), round(0.9*sqrt(2); digits = dgt)]
    
    # transformed space
    ax2 = Axis(
        l2[1, 1];
        aspect = 1,
        ylabel = "Performance (J)",
        xlabel = "Positive predictive bias (TPR–TNR+1)",
        height = dheight,
        title = L"(x + y, y - x)",
        titlesize = 20
    )

    ylims!(ax2, yext...)
    xlims!(ax2, xext...)

    # transformed regions
    c1 = (oi[3]+oi[end-1], 0.25)
    vspan!(
        ax2,
        xext[1], 1; ymin = 0, ymax = 1, color = c1
    )
    c2 = oi[end-1]-oi[3]
    c2 = (RGBA(c2.r, c2.g, c2.b), 0.25)
    vspan!(
        ax2,
        1, xext[2]; ymin = 0, ymax = 1, color = c2
    )

    # line of no bias
    vlines!(ax2, 1; color = :black, linestyle = :dash, linewidth = 2)

    ##
    endpts2 = [first(ptst), last(ptst)]
    lines!(ax2, endpts2, linewidth = 2*lw, color = oi[end])

    xt = [pt[1] for pt in ptst]
    yt = [pt[2] for pt in ptst]
    
    xtmn, xtmx = extrema(xt)
    ytmn, ytmx = extrema(yt)
    
    ys = ytmn:0.0001:ytmx
    lines!(
        ax2, fill(xtmx, length(ys)), ys;
        color = columbia.blues[1],
        linewidth = lw*2,
        linecap = :round
    )
        
    xs = xtmn:0.0001:xtmx
    lines!(
        ax2, xs, fill(ytmn, length(xs));
        color = yale.accent[2],
        linewidth = lw*2,
        linecap = :round
    )

    scatter!(ax2, endpts2, color = [:red, :black], markersize = 10)
    # scatter!(ax2, Point2f(xtmx, ytmn), color = (yale.accent[2], 0.5), markersize = 7, marker = :rect)
    # scatter!(ax2, Point2f(xtmx, ytmn), color = (columbia.blues[1], 0.5), markersize = 7, marker = :rect)

end

export ratediagram!

function typeshape(x)
    return if x == "Cognizer"
        :circle
    elseif x .∈ Ref(["Mean", "Combination"])
        :rect
    elseif x == "Difference"
        :utriangle
    end
end

export typeshape
