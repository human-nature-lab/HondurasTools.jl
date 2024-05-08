# coefplot.jl

struct BiVector
    tpr::AbstractVector
    fpr::AbstractVector
end

export BiVector

struct BiCoefPlotData
    βs::BiVector
    ses::BiVector
    intr::BiVector
end

export BiCoefPlotData

function getindex(em::BiVector, s::Symbol)

    tpr = s != :tpr
    fpr = s != :fpr
    return if !(tpr | fpr)
        println("invalid index")
        nothing
    else
        getfield(em, s)
    end
end

export getindex

function bimodelcoefplot(bm)
    rates = [:tpr, :fpr];
    
    βs = BiVector([coef(bm[r]) for r in rates]...);
    ses = BiVector([stderror(bm[r]) for r in rates]...);
    intr = BiVector([ci.(βs[r], ses[r]) for r in rates]...);

    return BiCoefPlotData(βs, ses, intr)
end

export bimodelcoefplot

struct CoefPlotData
    names::Vector{String}
    βs::Vector{Real}
    ses::Vector{Real}
    intr::Vector{Tuple{Real, Real}}
end

function coefplotdata(m)
    names = coefnames(m)
    βs = coef(m);
    ses = stderror(m);
    intr = ci.(βs, ses)

    return CoefPlotData(names, βs, ses, intr)
end

export CoefPlotData, coefplotdata

coefdict = Dict(
    "kin431" => "kin",
    "relation: personal private" => "personal private",
    "dists p notinf & dists p" => "k-(i,j) dist.",
    "dists a notinf & dists a" => "i-j dist.",
    "dists p notinf" => "k-(i,j) path",
    "dists a notinf" => "i-j path",
);

function coefficientbiplot!(
    plo, bmcp;
    reversenames = true,
    cnames = nothing,
    yticklabelrotation = π/6,
    coefdict = coefdict
)
    lo = plo[1, 1] = GridLayout();

    if isnothing(cnames)
        cnames = bmcp[:tpr].names |> copy;
        addnames = setdiff(bmcp[:fpr].names, bmcp[:tpr].names);
        append!(cnames, addnames);
    end

    unique!(cnames)

    if reversenames
        cnames = reverse(cnames);
    end

    cnum = length(cnames);

    β_ = [fill(0.0, length(cnames)) for _ in 1:2];
    intr = [Vector{Tuple{Real, Real}}(undef, length(cnames)) for _ in 1:2];

    for (j, r) in enumerate(rates)
        for (i, e) in enumerate(cnames)
            idx = findfirst(bmcp[r].names .== e)
            β_[j][i] = if !isnothing(idx)
                bmcp[r].βs[idx]
            else
                NaN
            end
            intr[j][i] = if !isnothing(idx)
                bmcp[r].intr[idx]
            else
                (NaN, NaN)
            end
        end
    end

    cnames_clean = replace.(cnames, "_" => " ");

    # manually change coef names
    cnames_processed = if !isnothing(coefdict)
        [get(coefdict, e, e) for e in cnames_clean]
    else cnames_clean
    end

    ax = Axis(
        lo[1, 1];
        yticks = (1:cnum, cnames_processed),
        yticksvisible = false,
        yticklabelrotation,
    );

    colors = (rb = :black, tpr = oi[5], fpr = oi[6], );

    fpr_offset = 0.5
    rws = (1:cnum) .- fpr_offset # offset for model 2 values
    vlines!(ax, 0, color = :black, linestyle = :dot)
    hlines!(rws[2:end], color = (:black, 0.5), linewidth = 0.8)
    ylims!(ax, 0.5, length(rws) + 0.5)

    rangebars!(ax, rws .+ 0.3, intr[1]; color = colors.rb, direction = :x)
    scatter!(ax, β_[1], rws .+ 0.3; color = colors.tpr)
    
    rangebars!(rws .+ 0.7, intr[2]; color = colors.rb, direction = :x)
    scatter!(ax, β_[2], rws .+ 0.7; color = colors.fpr)
end

function yfunc(z, b, x)
    return (z/3 + b) * inv(x)
end

function yfunc(b, x)
    return (1/3 + b) * inv(x), (2/3 + b) * inv(x)
end

function yfuncs(x)
    return [yfunc(b, x) for b in 0:(x-1)]
end

function yfuncs(z, x)
    return [yfunc(z, b, x) for b in 0:(x-1)]
end

function coefficientbiplot!(
    plo, bmcps::AbstractVector;
    reversenames = true, rates = rates,
    markers = [:rect, :cross, :star6, :rect, :utriangle],
    cnames = nothing,
    yticklabelrotation = π/6,
    coefdict = coefdict
)
    lo = plo[1, 1] = GridLayout();

    #=
    coeff order:
    - order of model 1 tpr, then add other tpr variables.
    - repeat for fpr.
    =#

    if isnothing(cnames)
        cnames = String[];
        for r in rates
            for bmcp in bmcps
                append!(cnames, bmcp[r].names)
            end
        end
    end

    unique!(cnames)

    if reversenames
        cnames = reverse(cnames);
    end
    cnum = length(cnames);
    cnames_clean = replace.(cnames, "_" => " ");

    # manually change coef names
    cnames_processed = if !isnothing(coefdict)
        [get(coefdict, e, e) for e in cnames_clean]
    else cnames_clean
    end

    ylabel_pos = (1:cnum) .- 1/2;

    # plot
    ax = Axis(
        lo[1, 1];
        yticks = (ylabel_pos, cnames_processed),
        yticksvisible = false,
        yticklabelrotation,
        # ylabel = "Coefficient",
        xlabel = "Estimate"
    );

    colors = (rb = :black, tpr = oi[5], fpr = oi[6], );

    yindices = (
        tpr = [fill(0.0, length(cnames)) for _ in eachindex(bmcps)],
        fpr = [fill(0.0, length(cnames)) for _ in eachindex(bmcps)],
    )

    ypos = (
        tpr = [yfuncs(1, length(bmcps)) .+ (i-1) for i in eachindex(cnames)],
        fpr = [yfuncs(2, length(bmcps)) .+ (i-1) for i in eachindex(cnames)],
    )

    for r in rates
        for j in eachindex(bmcps)
            yindices[r][j] .= [ypos[r][i][j] for i in eachindex(cnames)]
        end
    end

    vlines!(ax, 0, color = :black, linestyle = :dot)
    hlines!(1:(cnum-1), color = (:black, 0.5), linewidth = 0.8)
    ylims!(ax, 0, cnum)

    for (l, (bmcp, marker)) in (enumerate∘zip)(bmcps, markers)
        β_ = [fill(0.0, length(cnames)) for _ in 1:2];
        intr = [Vector{Tuple{Real, Real}}(undef, length(cnames)) for _ in 1:2];

        for (j, r) in enumerate(rates)
            for (i, e) in enumerate(cnames)
                idx = findfirst(bmcp[r].names .== e)
                β_[j][i] = if !isnothing(idx)
                    bmcp[r].βs[idx]
                else
                    NaN
                end
                intr[j][i] = if !isnothing(idx)
                    bmcp[r].intr[idx]
                else
                    (NaN, NaN)
                end
            end
        end

        rangebars!(
            ax, yindices.tpr[l], intr[1];
            color = colors.rb, direction = :x
        )
        scatter!(
            ax, β_[1], yindices.tpr[l];
            color = colors.tpr, marker
        )
        
        rangebars!(
            yindices.fpr[l], intr[2];
            color = colors.rb, direction = :x
        )
        scatter!(ax, β_[2], yindices.fpr[l]; color = colors.fpr, marker)
    end

    # Legend
    group_color = [
        MarkerElement(;
            color, strokecolor = :transparent, marker = :circle
        ) for color in oi[[5,6]]
    ]

    group_marker = [
        MarkerElement(;
            color = :black, strokecolor = :transparent, marker
        ) for marker in markers[eachindex(bmcps)]
    ]

    color_leg = ["TPR", "FPR"];
    marker_leg = ["1", "2", "3"];
    leg_titles = ["Rate", "Model"];

    Legend(
        lo[2, 1],
        [group_color, group_marker],
        [color_leg, marker_leg],
        leg_titles,
        tellheight = false, tellwidth = false,
        orientation = :horizontal,
        nbanks = 1, framevisible = false
    )

    rowsize!(lo, 1, Relative(19/20))

    return lo
end

export coefficientbiplot!

"""
plot marginal means
"""
function margmeanplot!(lo, effs, effs_youd, modelnames, model_legend)
    ax = Axis(
        lo[1, 1];
        xlabel = "Model",
        ylabel = "Accuracy rate",
        xticks = (
            1:(length(modelnames)*2),
            model_legend
        )
    );

    ax_ = Axis(
        lo[1, 1]; xaxisposition = :top,
        xticks = ([2, 5], ["Free time", "Personal private"]),
        xticksvisible = false
    );
    hideydecorations!(ax_)

    ax_y = Axis(lo[1, 1], yaxisposition = :right, ylabel = "Youden's J");
    hidexdecorations!(ax_y)

    linkaxes!(ax, ax_)
    linkxaxes!(ax, ax_, ax_y)

    effsg = groupby(effs, :relation);
    effs_youdg = groupby(effs_youd, :relation);

    for (e, a) in zip(effsg, [0, length(modelnames)])
        for i in eachindex(modelnames)
            sub = @subset e :model .== modelnames[i];
            y = sub[!, :prob_correct];
            cnft = sub[!, :prob_correct_ci];
            color = color = sub.color; marker = sub.marker
            rangebars!(ax, fill(a + i, nrow(sub)) .- 0.25, cnft; color = :black, marker)
            scatter!(ax, fill(a + i, nrow(sub)) .- 0.25, y; color, marker)
        end
    end

    for (e, a) in zip(effs_youdg, [0, length(modelnames)])
        for i in eachindex(modelnames)
            sub = @subset e :model .== modelnames[i];
            y = sub[!, :j]
            marker = sub.marker
            scatter!(ax_y, fill(a + i, nrow(sub)) .+ 0.25, y; color = oi[2], marker)
        end
    end

    vlines!(ax, length(modelnames) + 0.5, color = :black);
    ints = (1:length(modelnames)*2) .+ 0.5
    vlines!(ax, ints; color = :grey, linewidth = 0.5);

    xlims!(ax_y, 0.5, length(modelnames)*2+0.5)
    ylims!(ax_, 0, 1)
    ylims!(ax_y, -1, 1)

    group_color = [
        MarkerElement(;
            color,
            strokecolor = :transparent,
            marker = :circle
        ) for color in oi[[5,6,2]]
    ]

    group_marker = [
        MarkerElement(;
            color = :black,
            strokecolor = :transparent,
            marker
        ) for marker in [:rect, :cross]
    ]

    color_leg = ["TPR", "FPR", "J"];
    marker_leg = ["Kin", "Non-kin"];
    leg_titles = ["Rate", "Tie"];

    Legend(
        lo[1, 2],
        [group_color, group_marker],
        [color_leg, marker_leg],
        leg_titles,
        tellheight = false, tellwidth = false,
        orientation = :vertical,
        nbanks = 1, framevisible = false
    )
end

export margmeanplot!

function coefficientplot!(
    plo, cpds::AbstractVector;
    reversenames = true,
    markers = [:cross, :rect, :star6, :rect, :utriangle],
    cnames = nothing,
    yticklabelrotation = π/6,
    coefdict = coefdict,
    marker_leg = nothing
)
    lo = plo[1, 1] = GridLayout();

    #=
    coeff order:
    - order of model 1 tpr, then add other tpr variables.
    - repeat for fpr.
    =#

    if isnothing(cnames)
        cnames = String[];
        for cpd in cpds
            append!(cnames, cpd.names)
        end
    end

    unique!(cnames)

    if reversenames
        cnames = reverse(cnames);
    end
    cnum = length(cnames);
    cnames_clean = replace.(cnames, "_" => " ");

    # manually change coef names
    cnames_processed = if !isnothing(coefdict)
        [get(coefdict, e, e) for e in cnames_clean]
    else cnames_clean
    end

    ylabel_pos = (1:cnum) .- 1/2;

    # plot
    ax = Axis(
        lo[1, 1];
        yticks = (ylabel_pos, cnames_processed),
        yticksvisible = false,
        yticklabelrotation,
        # ylabel = "Coefficient",
        xlabel = "Estimate"
    );

    colors = (rb = :black, tpr = oi[5], fpr = oi[6], );

    yindices = [fill(0.0, length(cnames)) for _ in eachindex(cpds)]
    ypos = [yfuncs(1, length(cpds)) .+ (i-1) for i in eachindex(cnames)]

    for j in eachindex(cpds)
        yindices[j] .= [ypos[i][j] for i in eachindex(cnames)]
    end

    vlines!(ax, 0, color = :black, linestyle = :dot)
    hlines!(1:(cnum-1), color = (:black, 0.5), linewidth = 0.8)
    ylims!(ax, 0, cnum)

    (l, (cpd, marker)) = (collect∘enumerate∘zip)(cpds, markers)[1]

    for (l, (cpd, marker)) in (enumerate∘zip)(cpds, markers)
        β_ = fill(0.0, length(cnames));
        intr = Vector{Tuple{Real, Real}}(undef, length(cnames));

        for (i, e) in enumerate(cnames)
            idx = findfirst(cpd.names .== e)
            β_[i] = if !isnothing(idx)
                cpd.βs[idx]
            else
                NaN
            end
            intr[i] = if !isnothing(idx)
                cpd.intr[idx]
            else
                (NaN, NaN)
            end
        end

        rangebars!(
            ax, yindices[l], intr;
            color = colors.rb, direction = :x
        )
        scatter!(
            ax, β_, yindices[l];
            color = colors.rb, marker
        )
    end

    # Legend

    group_marker = [
        MarkerElement(;
            color = :black, strokecolor = :transparent, marker
        ) for marker in markers[eachindex(cpds)]
    ]

    if isnothing(marker_leg)
        marker_leg = ["1", "2", "3"];
    end
    
    leg_titles = ["Model"];
    
    if marker_leg != :none
        Legend(
            lo[2, 1],
            [group_marker],
            [marker_leg],
            leg_titles,
            tellheight = false, tellwidth = false,
            orientation = :horizontal,
            nbanks = 1, framevisible = false
        )
        rowsize!(lo, 1, Relative(18/20))
    end


    return lo
end

export coefficientplot!
