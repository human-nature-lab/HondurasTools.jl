# plotting.jl

"""
        improvementline!(ax)

## Description

Add line of equal-ratio (TPR:FPR) increase (decrease) in accuracy.
"""
function improvementline!(ax)
    above = (oi[6], 0.3)
    below = (oi[3], 0.3)

    lines!(ax, (1:-0.1:0.5), 0:0.1:0.5; linestyle = :solid, color = above)
    lines!(ax, (0.5:-0.1:0), 0.5:0.1:1; linestyle = :solid, color = below)
end

export improvementline!

function lineband!(ax, x, y, yl, yu; linecolor = color, label = "")
    band!(ax, x, yl, yu; color = (linecolor, 0.4))
    lines!(ax, x, y; color = (linecolor, 0.8), label = label)
end

export lineband!

function dotbar!(ax, x, y, yl, yu; dotcolor = color, label = "")
    scatter!(ax, x, y; color = (dotcolor, 0.8), label = label)
    errorbars!(ax, x, yl, yu; color = (dotcolor, 0.4))
end

export dotbar!

function node_properties(g, v; c = "#00356b", focalsize = 30)
    node_color = fill(RGBA(0,0,0), nv(g))
    node_color[v] = parse(Colorant, c)
    node_size = fill(12, nv(g))
    node_size[v] = focalsize
    return node_color, node_size
end

export node_properties
