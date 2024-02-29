# hhbarplot.jl

"""
        unitbarplot(
            dfin, thing;
            wave = nothing, prop = true, unit = :village_code, 
            clrs = colorschemes[:tol_light],
            colsize = Relative(2/3),
            dosort = true, rev = false
        )

## Description

By-unit stacked barplot for distribution of binary- and categorical-valued `thing`.

`dosort`: if `false`, units will be sorted according to their alphanumeric order, if `true` units will be sorted in order of decreasing category frequency (e.g., first by the most common value, second by the second most common value...) either count or proportion depending on the value of `prop`."
"""
function unitbarplot(
    dfin, thing;
    wave = nothing, prop = true, unit = :village_code, 
    clrs = colorschemes[:tol_light],
    colsize = Relative(2/3),
    dosort = true, rev = false,
    fg = Figure()
)

    lo = fg[1, 1:2] = GridLayout();
    l1 = lo[1, 1] = GridLayout(); # main plot
    ll = lo[1, 2] = GridLayout(); # legend

    df = deepcopy(dfin)

    df[!, unit] = levelcode.(df[!, unit]);

    code = :code
    if nonmissingtype(eltype(df[!, thing])) == Bool
        df[!, thing] = categorical(string.(df[!, thing]))
    end;
    replace!(df[!, thing], missing => "missing");
    
    if !isnothing(wave)
        @subset! df :wave .== wave
    end

    vr = if prop
        :prop
    else
        :n
    end

    df = @chain df begin
        groupby([unit, thing])
        combine(nrow => :n)
        groupby(unit)
        DataFramesMeta.transform(:n => sum)
        @transform(_, :prop = :n ./ :n_sum)
        dropmissing()
    end

    if dosort
        thingsort = @chain df begin
            groupby(thing)
            combine(vr => mean => vr)
            sort(vr; rev = true)
        end
        thingsort = string.(thingsort[!, thing])

        sorder = @chain df begin
            unstack(unit, thing, vr)
            sort(thingsort; rev = rev)
        end
        sorder.col = 1:nrow(sorder)
        select!(sorder, [unit, :col]);

        leftjoin!(df, sorder, on = unit);
        df.idx = df.col
    else
        df.idx = df[!, unit]
    end
    
    df.code = CategoricalArrays.levelcode.(df[!, thing])

    # :Set1_9

    ur = replace(string(unit), "_" => " ")

    ax1 = Axis(
        l1[1,1], xlabel = ur,
        ygridvisible = false, xgridvisible = false
    );

    barplot!(
        ax1, df[!, :idx], df[!, vr],
        stack = df[!, code],
        color = clrs[df[!, code].+1]# [wc[i+1] for i in relsum.relcode],
    )

    # Legend

    #sunique(df[!, code])

    labels = string.(levels(df[!, thing]))
    elements = [PolyElement(polycolor = clrs[i+1]) for i in 1:length(labels)]

    ttl = replace(string(thing), "_" => " ")
    Legend(
        ll[1, 1], elements, labels, ttl,
        tellheight = false, tellwidth = false
    )

    colgap!(lo, 0)
    colsize!(lo, 1, colsize)
    ylims!(ax1, 0, 1)
    xlims!(ax1, extrema(df[!, unit])...)
    hidedecorations!(ax1, ticks = false, ticklabels = false, label = false)
    hidexdecorations!(ax1, label = false)

    return fg
end

export unitbarplot

function unitbarplot!(
    lo,
    dfin, thing;
    wave = nothing, prop = true, unit = :village_code, 
    clrs = colorschemes[:tol_light],
    colsize = Relative(2/3),
    dosort = true, rev = false,
    groupsort = nothing
)

    # lo = fg[1, 1:2] = GridLayout();
    l1 = lo[1, 1] = GridLayout(); # main plot
    ll = lo[1, 2] = GridLayout(); # legend

    df = deepcopy(dfin)

    df[!, unit] = levelcode.(df[!, unit]);

    code = :code
    if nonmissingtype(eltype(df[!, thing])) == Bool
        df[!, thing] = categorical(string.(df[!, thing]))
    end;
    recode!(df[!, thing], missing => "Missing");
    
    if !isnothing(wave)
        @subset! df :wave .== wave
    end

    vr = if prop
        :prop
    else
        :n
    end

    df = @chain df begin
        if isnothing(groupsort)
            groupby(_, [unit, thing])
        else
            groupby(_, [groupsort, unit, thing])
        end
        combine(nrow => :n)
        groupby(unit)
        DataFramesMeta.transform(:n => sum)
        @transform(_, :prop = :n ./ :n_sum)
        dropmissing()
    end

    if dosort
        thingsort = @chain df begin
            groupby(thing)
            combine(vr => mean => vr)
            sort(vr; rev = true)
        end
        thingsort = string.(thingsort[!, thing])

        thingsort = if !isnothing(groupsort)
            [groupsort, thingsort...]
        else
            thingsort
        end

        sorder = @chain df begin
            if isnothing(groupsort)
                unstack(_, unit, thing, vr)
            else
                unstack(_, [groupsort, unit], thing, vr)
            end
            sort(thingsort; rev = rev)
        end
        sorder.col = 1:nrow(sorder)

        if !isnothing(groupsort)
            tst = levelcode.(categorical(sorder[!, groupsort]))
            brks = findall(diff(tst) .!= 0)
            brks = sorder.col[brks] # this line should be pointless

            brks = brks[1:(end-1)]
        end

        select!(sorder, [unit, :col]);

        leftjoin!(df, sorder, on = unit);
        df.idx = df.col
    else
        df.idx = df[!, unit]
    end
    
    df.code = CategoricalArrays.levelcode.(df[!, thing])

    # :Set1_9

    ur = replace(string(unit), "_" => " ")

    ax1 = Axis(
        l1[1,1], xlabel = ur,
        ygridvisible = false, xgridvisible = false,
    );    

    barplot!(
        ax1, df[!, :idx], df[!, vr],
        stack = df[!, code],
        color = clrs[df[!, code]]# [wc[i+1] for i in relsum.relcode],
    )

    if !isnothing(groupsort)
        vcs = [clrs[levelcode(x)] for x in df[!, groupsort]]
        vlines!(ax1, brks, color = :black, linestyle = :dash, linewidth = 0.8)
        scatter!(ax1, df.idx, fill(0, nrow(df)), markersize = 10, marker = :rect, color = vcs)
    end


    # Legend

    #sunique(df[!, code])

    labels = string.(levels(df[!, thing]))
    elements = [PolyElement(polycolor = clrs[i]) for i in 1:length(labels)]

    ttl = replace(string(thing), "_" => " ")
    Legend(
        ll[1, 1], elements, labels, ttl,
        tellheight = false, tellwidth = false
    )

    colgap!(lo, 0)
    colsize!(lo, 1, colsize)
    ylims!(ax1, -0.001, 1)
    xlims!(ax1, extrema(df[!, unit])...)
    hidedecorations!(ax1, ticks = false, ticklabels = false, label = false)
    hidexdecorations!(ax1, label = false)

end

export unitbarplot!
