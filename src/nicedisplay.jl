# nicedisplay.jl

function niceout(file,
    v::Vector; crop = :none, rows = nothing,
    colnum = 6, tf = nothing
)
    # reasonable width for default
    ln = length(v);
    rows = if isnothing(rows)
        (Int∘ceil)(ln/colnum)
    else
        rows
    end

    cls = (Int∘ceil)(ln/rows)
    shw = similar(v, rows, cls);
    shw[1:ln] .= v

    x = if !isnothing(tf)
        true
    else
        false
    end

    return pretty_table(file, 
        shw;
        max_num_of_rows = rows, compact_printing = true,
        limit_printing = false, show_header = x,
        show_row_number = true, vlines = :all,
        renderer = :print,
        crop = crop, tf = tf
    )
end

"""
        nicedisplay(
            v::Vector; crop = :none, rows = nothing;
            colnum = 7, tf = nothing
        )

Display a vector in a multicolumn format.
"""

function nicedisplay(
    v::Vector; crop = :none, rows = nothing,
    colnum = 6, tf = nothing
)
    # reasonable width for default
    ln = length(v);
    rows = if isnothing(rows)
        (Int∘ceil)(ln/colnum)
    else
        rows
    end

    cls = (Int∘ceil)(ln/rows)
    shw = similar(v, rows, cls);
    shw[1:ln] .= v

    x = if !isnothing(tf)
        true
    else
        false
    end

    return pretty_table(
        shw;
        max_num_of_rows = rows, compact_printing = true,
        limit_printing = false, show_header = x,
        show_row_number = true, vlines = :all,
        renderer = :print,
        crop = crop, tf = tf
    )
end

function nicedisplay(df::DataFrame; crop = :none, rows = nothing, colnum = 6, tf = nothing)
    return nicedisplay(names(df), crop = crop, rows = rows, colnum = colnum, tf = tf)
end

