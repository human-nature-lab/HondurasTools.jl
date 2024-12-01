# figure2.jl

function make_figure1(fprm)
    Random.seed!(2024)

    fg = Figure(figure_padding = 0);
    flo = fg[1:2, 1:3] = GridLayout();
    plo = flo[1:2, 1:2] = GridLayout();
    l_diagram = plo[2, 2] = GridLayout();
    l_leg = flo[1:2, 3] = GridLayout();
    
    los = backgroundplot!(plo, fprm; diagnostic = false)
    for i in 1:2; colsize!(flo, i, Aspect(1, 1.0)) end
    # for i in 1:2; rowsize!(flo, i, Aspect(1, 1.0)) end
    background_legend!(l_leg[1,1])


    labelpanels!([los..., l_diagram]; lbs = :lowercase)

    # rowgap!(plo, -50)
    # colgap!(plo, -80)
    return fg, flo, plo, l_leg
end

export make_figure1

function background_legend!(ly)
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

    # Legend(
    #     ly[1, 1],
    #     [group_color],
    #     [color_leg],
    #     ["Node type"];
    #     tellheight,
    #     tellwidth,
    #     orientation = :vertical,
    #     titleposition = :top,
    #     valign,
    #     nbanks = 1, framevisible = false
    # )

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

    # Legend(
    #     ly[2, 1],
    #     [space_color],
    #     [space_leg],
    #     ["Cognizer distance"];
    #     tellheight,
    #     tellwidth,
    #     orientation = :vertical,
    #     titleposition = :top,
    #     valign,
    #     nbanks = 3, framevisible = false
    # )

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
        ly[1, 1],
        [group_color, space_color, line_style, line_color],
        [color_leg, space_leg, line_leg, line_color_leg],
        ["Node type", "Cognizer distance", "Tie exists in network", "Response"];
        tellheight,
        tellwidth,
        orientation = :vertical,
        titleposition = :top,
        valign,
        nbanks = 1,
        framevisible = false
    )
end
