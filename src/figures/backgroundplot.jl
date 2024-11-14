# backgroundplot.jl

function fullplot!(
    ax, pos, g, node_color, node_size;
    orbitcolor = oi[2],
    outerdist = 5.0,
    yale = yale,
    rts = [0.2, (2/3)*0.2, (2/3)^2*0.2, (2/3)^3*0.2]
)

    mgrey = yale.grays[3]

    # keeping this preserves the shape
    poly!(
        ax,
        Circle(Point2f(0, 0), outerdist);
        color = (:white, 0.0), ##
        strokecolor = (mgrey, 0.0),
        strokewidth = 12,
    )

    poly!(
        ax,
        Circle(Point2f(0, 0), 1),
        color = (orbitcolor, rts[1]),
        strokecolor = :black,
        strokewidth = 1
    )

    poly!(
        ax,
        Circle(Point2f(0, 0), 2),
        color = (orbitcolor, rts[2]),
        strokecolor = :black,
        strokewidth = 1
    )

    poly!(
        ax,
        Circle(Point2f(0, 0), 3),
        color = (orbitcolor, rts[3]),
        strokecolor = :black,
        strokewidth = 1
    )

    poly!(
        ax,
        Circle(Point2f(0, 0), 4),
        color = (orbitcolor, rts[4]),
        strokecolor = :black,
        strokewidth = 1
    )

    graphplot!(
        ax, g, layout = (x) -> pos,
        node_color = node_color,
        node_size = node_size
    );
end

export fullplot!

function sampleableplot!(
    ax, pos, g23, v;
    orbitcolor = oi[2], outerdist = 5.0,
    yale = yale,
    rts = [0.2, (2/3)*0.2, (2/3)^2*0.2, (2/3)^3*0.2]
)

    mgrey = yale.grays[3]

    g2 = g23[1];
    g3 = g23[2];

    node_color, node_size = node_properties(g2, v)

    for e in edges(g3)
        set_prop!(g3, e, :real, true)
    end

    for i in 1:nv(g3), j in 1:nv(g3)
        if (i < j) & (i != v) & (j != v)
            if !has_edge(g3, i, j)
                add_edge!(g3, i, j)
                set_prop!(g3, i, j, :real, false)
            end
        end
    end

    g3_ndf4 = DataFrame(g3; type = :edge);
    g3_ndf4.linestyle = ifelse.(g3_ndf4.real, :solid, :dot);
    g3_ndf4.color = [
        ifelse(x, (:black, 1.0), (:black, 0.05)) for x in g3_ndf4.real
    ];

    # keeping this preserves the shape
    poly!(
        ax,
        Circle(Point2f(0, 0), outerdist);
        color = (:white, 0.0), ##
        strokecolor = (mgrey, 0.0),
        strokewidth = 12,
    )


    poly!(
        ax,
        Circle(Point2f(0, 0), 1),
        color = (orbitcolor, rts[1]),
        strokecolor = :black,
        strokewidth = 1
    )

    poly!(
        ax,
        Circle(Point2f(0, 0), 2),
        color = (orbitcolor, rts[2]),
        strokecolor = :black,
        strokewidth = 1
    )

    poly!(
        ax,
        Circle(Point2f(0, 0), 3),
        color = (orbitcolor, rts[3]),
        strokecolor = :black,
        strokewidth = 1
    )

    poly!(
        ax,
        Circle(Point2f(0, 0), 4),
        color = (orbitcolor, rts[4]),
        strokecolor = :black,
        strokewidth = 1
    )

    graphplot!(
        ax, g3;
        layout = (x) -> pos,
        node_color = node_color,
        node_size = node_size,
        edge_attr = (; linestyle = g3_ndf4.linestyle),
        edge_color = g3_ndf4.color,
        edge_plottype = :beziersegments
    );
end

export sampleableplot!

function sampledplot!(
    ax, pos, g2, v;
    orbitcolor = oi[2],
    outerdist = 5.0, yale = yale,
    rts = [0.2, (2/3)*0.2, (2/3)^2*0.2, (2/3)^3*0.2]
)

    mgrey = yale.grays[3]
    truecolor = (oi[1], 1.0)
    falsecolor = (oi[end-1])

    linestyle1 = Symbol[]
    edge_color1 = Any[]

    for e in edges(g2)
        push!(linestyle1, get_prop(g2, e, :socio) == true ? :solid : :dash)
        push!(
            edge_color1,
            get_prop(g2, e, :css) == true ? (oi[2], 1.0) : (mgrey, 0.1)
        )
    end

    ##

    node_color, node_size = node_properties(g2, v)

    linestyle = Symbol[]
    edge_color = Any[]

    truetiecolor = (mgrey, 0.3)

    for e in edges(g2)
        push!(linestyle, get_prop(g2, e, :socio) == true ? :solid : :dash)
        ec = if (get_prop(g2, e, :css) == true)
                if get_prop(g2, e, :correct)
                    truecolor
                elseif !get_prop(g2, e, :correct)
                    falsecolor
                else 
                    truetiecolor
                end
            else
                truetiecolor
            end
        push!(edge_color, ec)
    end

    # keeping this preserves the shape
    poly!(
        ax,
        Circle(Point2f(0, 0), outerdist);
        color = (:white, 0.0), ##
        strokecolor = (mgrey, 0.0),
        strokewidth = 12,
    )

    poly!(
        ax,
        Circle(Point2f(0, 0), 1),
        color = (orbitcolor, rts[1]),
        strokecolor = :black,
        strokewidth = 1
    )

    poly!(
        ax,
        Circle(Point2f(0, 0), 2),
        color = (orbitcolor, rts[2]),
        strokecolor = :black,
        strokewidth = 1
    )

    poly!(
        ax,
        Circle(Point2f(0, 0), 3),
        color = (orbitcolor, rts[3]),
        strokecolor = :black,
        strokewidth = 1
    )

    poly!(
        ax,
        Circle(Point2f(0, 0), 4),
        color = (orbitcolor, rts[4]),
        strokecolor = :black,
        strokewidth = 1
    )

    graphplot!(
        ax, g2;
        layout = (x) -> pos,
        node_color = node_color,
        node_size = node_size,
        edge_attr = (; linestyle = linestyle),
        edge_color = edge_color,
        edge_plottype = :beziersegments
    )
end

export sampledplot!

@inline crmp(x) = log(x+1)

function figure1data(css, cr, ndf4)
    graphs = fill(MetaGraph(), 3);
    poses = Vector{Vector{Tuple{Float64, Float64}}}(undef, 3);
    gdses = Vector{Vector{Float64}}(undef, 3);

    prm = (
        gt = socio, # ground truth variable
        maxdist = 4, # max number of rings out
        # to help shape the rings in the image, distance for outer ring
        outerdist = 5.0,
        ville = 17 # pick a reasonable village for example
    );

    v, cssvu, = data_handling!(graphs, css, ndf4, prm)

    tiemean = @chain cr begin
        dropmissing([:relation, :response, socio])
        groupby([:perceiver, :relation])
        combine(nrow => :count)
        # groupby([:relation])
        combine([:count => valproc∘x => string(x) for x in [mean, median, mode]]...)
    end
    tiemean = NamedTuple(tiemean[1, :]);

    prm = (
        gt = socio, # ground truth variable
        maxdist = 4, # max number of rings out
        # to help shape the rings in the image, distance for outer ring
        outerdist = 5.0,
        ville = 17, # pick a reasonable village for example,
        v = v,
        cssvu = cssvu,
        graphs = graphs, poses = poses, gdses = gdses,
        tiemean = tiemean
    );

    return prm
end

export figure1data

function data_handling!(graphs, css, ndf4, prm)
    css_c = @chain css begin
        @subset :village_code .== prm.ville
        groupby([:perceiver, (prm.gt), :response])
        combine(nrow => :n)
        sort(:n; rev = true)
        groupby(cg.p)
        combine(:n => Ref => :n)
    end

    # select nice examples
    good = @rsubset css_c (minimum(:n) .> 3) & (length(:n) == 4)

    # check focal node responses
    # to see if it is a reasonable choice

    # pull the graph from ndf
    idx = findfirst(
        (ndf4.relation .== rl.u) .& (ndf4.village_code .== prm.ville)
    );
    graphs[1] = ndf4.graph[idx];

    focusname = good.perceiver[2]
    v = graphs[1][focusname, :name];

    cssvu = @subset(css, :perceiver .== focusname);
    cssvu[!, :correct] .= cssvu.response .== cssvu[!, prm.gt];

    return v, cssvu
end

function backgroundplot!(plo, fprm; diagnostic = false)

    inner_plotting!(fprm, diagnostic)

    # define Axis objects
    los = [];
    axs = [];

    for i in [[1,1], [1,2], [2,1]]
        lo = plo[i...] = GridLayout()
        ax = Axis(lo[1, 1]; backgroundcolor = :transparent, aspect = 1)
        hidedecorations!(ax)
        hidespines!(ax)
        push!(axs, ax)
        push!(los, lo)
    end

    node_color, node_size = node_properties(fprm.graphs[1], fprm.v)
    
    fullplot!(axs[1], fprm.poses[1], fprm.graphs[1], node_color, node_size)
    sampleableplot!(axs[2], fprm.poses[2], fprm.graphs[2:3], fprm.v)
    sampledplot!(axs[3], fprm.poses[2], fprm.graphs[2], fprm.v)
    return los
end

export backgroundplot!

function inner_plotting!(fprm, diagnostic)

    g = deepcopy(fprm.graphs[1])

    # diagnostics
    if diagnostic
        cl = fill(:grey, nv(g));
        cl[v] = :red;

        # diagnostic plot
        # just observe village network to confirm that it is a good village
        graphplot(g, node_color = cl)
    end
       
    # define the graphs
    fprm.graphs[1], fprm.poses[1], fprm.gdses[1] = focuslayout(
        fprm.graphs[1], fprm.v;
        iter = 500, tol = 0.0001, maxdist = fprm.maxdist, compress = crmp
    )

    fprm.graphs[2], fprm.poses[2], fprm.gdses[2] = focuslayout(
        g, fprm.v; # use original graph
        iter = 500, tol = 0.0001, fprm.maxdist
    );

    fprm.graphs[3] = deepcopy(fprm.graphs[2]);

    fprm.poses[3] = deepcopy(fprm.poses[1])
    fprm.gdses[3] = deepcopy(fprm.gdses[1]);

    # additionally, ignore nodes that are beyond the desired distance

    vtx2 = names(fprm.graphs[2]);

    for edge in edges(fprm.graphs[2])
        set_prop!(fprm.graphs[2], edge, :socio, true)
        set_prop!(fprm.graphs[2], edge, :css, false)
    end

    # some in network but not surveyed -> real and not css
    for r in eachrow(fprm.cssvu)
        a1 = findfirst(r.alter1 .== vtx2)
        a2 = findfirst(r.alter2 .== vtx2)
        if !isnothing(a1) & !isnothing(a2)
            a1, a2 = sort([a1, a2])

            if !has_edge(fprm.graphs[2], a1, a2)
                add_edge!(fprm.graphs[2], a1, a2)
            end

            set_prop!(fprm.graphs[2], a1, a2, :socio, r[fprm.gt])
            set_prop!(fprm.graphs[2], a1, a2, :css, true)
            set_prop!(fprm.graphs[2], a1, a2, :correct, r.correct)
        else
            @show a1, a2
        end
    end;
end