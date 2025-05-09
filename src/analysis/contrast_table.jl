# contrast_table.jl

"""
        contrast_table(e, additions, iters, dats, m, pbs)


## Description

Generate table of contrasts of marginal effect levels.
"""
function contrast_table(e, additions, dats, m, pbs, iters, invlink)
    ed = usualeffects(dats, additions; stratifykin = false)
    rg = referencegrid(dats, ed)
    apply_referencegrids!(m, rg; invlink)

    ems = [empairs(rg[r]; eff_col = :response) for r in rates];
    for (r, e) in zip(rates, ems); e.rate .= r end;
    ems[1].dists_a .= NaN;
    ems = vcat(ems...)
    ci!(ems);

    @time rgb = jboot(
        e, m, rg, pbs, iters;
        invlink,
        type = :normal
    )
    
    # create DataFrame for j info
    cx = DataFrame(
        e => eltype(ems[!, e])[],
        :response => eltype(ems.response)[],
        :err => eltype(ems.response)[],
        :ci => eltype(ems.ci)[]
    );
        
    en = enumerate(ed.tpr[e])
    diff_j = Vector{Float64}(undef, iters); # preallocate and overwrite
    _contrast_table!(cx, diff_j, e, en, rgb, iters)
    
    # create template for j info, and add to existing ems contrast DataFrame
    emsj = @chain ems begin
        @subset :rate .== Symbol("tpr")
        select(Not(:rate, :response, :ci))
    end
    emsj.rate .= :j;
    leftjoin!(emsj, cx, on = e)
    append!(ems, emsj)

    return ems
end

"""

J: manually bootstrap and calculate the contrast (difference) for TPR - FPR.
"""
function _contrast_table!(cx, diff_j, e, en, rgb, iters)
    for (i, e1) in en
        for (j, e2) in en
            if i < j
                cmb = string(e1) * " > " * string(e2)
                ix1 = findfirst(rgb[!, e] .== e1)
                ix2 = findfirst(rgb[!, e] .== e2)
                ctr = rgb[ix1, :j] - rgb[ix2, :j]

                diff_j .= NaN
                for q in 1:iters
                    diff_j[q] = rand(rgb.bs_j[ix1]) - rand(rgb.bs_j[ix2])
                end

                st = std(diff_j)
                ci_ = ci(ctr, st)
                push!(cx, [cmb, ctr, st, ci_])
            end
        end
    end
end

export contrast_table
