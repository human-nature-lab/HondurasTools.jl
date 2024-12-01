# roc_space.jl

"""
        roc_panel!(fgloc)

## Description

Make the ROC space explainer panel.

- `fgloc`: _e.g._, `fg[1, 1]`, for a Figure or GridLayout object.
"""
function roc_panel!(figure_loc, legend_loc)
    ax = Axis(
        figure_loc,
        ylabel = "True positive rate", xlabel = "False positive rate",
        aspect = 1,
        # height = 100
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

    Legend(
        legend_loc,
        [elem_1, elem_2],
        [["Level 1", "Level 2"], ["Above chance", "Below chance"]],
        ["Attribute", "Performance"], framevisible = false
    );
end

export roc_panel!
