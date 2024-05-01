# tie_properties.jl

function amean!(cssalters, vbl)
    ab = Symbol(string(vbl) * "_a")
    a1 = Symbol(string(vbl) * "_a1")
    a2 = Symbol(string(vbl) * "_a2")

    cssalters[!, ab] = (cssalters[!, a1] + cssalters[!, a2]) * inv(2);
end

export amean!

function adiff!(cssalters, vbl)
    ab = Symbol(string(vbl) * "_ad")
    a1 = Symbol(string(vbl) * "_a1")
    a2 = Symbol(string(vbl) * "_a2")

    cssalters[!, ab] = abs.(cssalters[!, a1] - cssalters[!, a2]);
end

export adiff!

function binarycat!(
    cssalters, vbl, va::x, vb::x; mixed = "Mixed"
) where x <: Tuple
    ab = Symbol(string(vbl) * "_a")
    a1 = Symbol(string(vbl) * "_a1")
    a2 = Symbol(string(vbl) * "_a2")
    cssalters[!, ab] = similar(cssalters[!, a1]);
    for (i, (v1, v2)) in enumerate(
        zip(cssalters[!, a1], cssalters[!, a2])
    )
        if !ismissing(v1) & !ismissing(v2)

            cssalters[i, ab] = if v1 == v2 == va[1]
                va[2]
            elseif v1 == v2 == vb[1]
                vb[2]
            else
                mixed
            end
        end
    end
end

export binarycat!
