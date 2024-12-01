# figure2.jl

function make_figure1(fprm)
    Random.seed!(2024)

    fg = Figure(figure_padding = 0);
    layout_all = fg[1:2, 1:2] = GridLayout();
    layout_main = layout_all[1, 1:3] = GridLayout();
    layout_legend = layout_all[2, 1:3] = GridLayout();
    
    los = backgroundplot!(layout_main, fprm; diagnostic = false)
    # for i in 1:2; colsize!(flo, i, Aspect(1, 1.0)) end
    # for i in 1:2; rowsize!(flo, i, Aspect(1, 1.0)) end
    background_legend!(layout_legend[1, 1])

    labelpanels!([los...]; lbs = :lowercase)

    return fg, layout_all, layout_main, layout_legend
end

export make_figure1

function background_legend!(layout_legend)
    tellwidth = false;
    tellheight = false;
    valign = :top

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
        layout_legend[1, 1],
        group_color,
        color_leg,
        "Node type";
        tellheight,
        tellwidth,
        orientation = :vertical,
        titleposition = :left,
        valign,
        nbanks = 1,
        framevisible = false
    )

    Legend(
        layout_legend[1, 2],
        space_color,
        space_leg,
        "Cognizer distance";
        tellheight,
        tellwidth,
        orientation = :vertical,
        titleposition = :left,
        valign,
        nbanks = 2,
        framevisible = false
    )

    Legend(
        layout_legend[1, 3],
        [line_style, line_color],
        [line_leg, line_color_leg],
        ["Tie exists in network", "Response"];
        tellheight,
        tellwidth,
        orientation = :vertical,
        titleposition = :left,
        valign,
        nbanks = 1,
        framevisible = false
    )

    # Legend(
    #     layout_legend[1, 1],
    #     [group_color, space_color, line_style, line_color],
    #     [color_leg, space_leg, line_leg, line_color_leg],
    #     ["Node type", "Cognizer distance", "Tie exists in network", "Response"];
    #     tellheight,
    #     tellwidth,
    #     orientation = :horizontal,
    #     titleposition = :top,
    #     valign,
    #     nbanks = 1,
    #     framevisible = false
    # )
end
