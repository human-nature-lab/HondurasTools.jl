# backgroundplot.jl

function sampledplot!(ax, pos, g2, linestyle, edge_color, node_color, node_size;
    orbitcolor = yale.lblue, outerdist = 5.0, yale = yale, rts = [0.2, (2/3)*0.2, (2/3)^2*0.2, (2/3)^3*0.2])
    # keeping this preserves the shape
    poly!(
        ax,
        Circle(Point2f(0, 0), outerdist);
        color = (:white, 0.0), ##
        strokecolor = (yale.mgrey, 0.0),
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

function fullplot!(ax, pos, g, node_color, node_size; orbitcolor = yale.lblue, outerdist = 5.0, yale = yale, rts = [0.2, (2/3)*0.2, (2/3)^2*0.2, (2/3)^3*0.2])
    # keeping this preserves the shape
    poly!(
        ax,
        Circle(Point2f(0, 0), outerdist);
        color = (:white, 0.0), ##
        strokecolor = (yale.mgrey, 0.0),
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
    ax, pos, g3, node_color, node_size, g3_ndf4;
    orbitcolor = yale.lblue, outerdist = 5.0, yale = yale,
    rts = [0.2, (2/3)*0.2, (2/3)^2*0.2, (2/3)^3*0.2]
)

    # keeping this preserves the shape
    poly!(
        ax,
        Circle(Point2f(0, 0), outerdist);
        color = (:white, 0.0), ##
        strokecolor = (yale.mgrey, 0.0),
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
