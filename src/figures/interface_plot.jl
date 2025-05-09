# interface_plot.jl

"""
        interfaceplot(fg = Figure(); saveplot = true, pth = "/WORKAREA/work/HONDURAS_GATES/E_FELTHAM/honduras-css/figures/personal-private-question.jpg")

## Description

Display the survey interface
"""
function interfaceplot(fg = Figure(); saveplot = true, pth = "/WORKAREA/work/HONDURAS_GATES/E_FELTHAM/honduras-css/figures/personal-private-question.jpg")

    lo = fg[1, 1] = GridLayout()
    ax = lo[1,1] = Axis(fg, aspect = DataAspect())

    hidedecorations!(ax);
    hidespines!(ax)

    img = load(assetpath(pth));
    image!(ax, rotr90(img), overdraw = true)

    cap = "Survey interface. Respondents are queried about the relationships between pairs of people. Subjects are asked whether two individuals (1) know each other, (2) spend free time together, (3) discuss personal and private matters, and (4) are direct kin. "

    if saveplot
        savemdfigure(prj.pp, prj.css, "interface", cap, fg)
    end
    fg
end

