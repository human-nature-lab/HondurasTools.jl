# plotting.jl

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
