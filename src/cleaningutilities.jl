# cleaning_utilities.jl

"""
        regularizecols!(resp)

Make it possible to combine the dataframes from different waves, which may have different columns. This function creates a common set of columns for merging.
"""
function regularizecols!(resp)

    dr1 = describe(resp[1])[!, [:variable, :eltype]]

    if length(resp) > 1
        dr2 = describe(resp[2])[!, [:variable, :eltype]]
    end
    
    if length(resp) > 2
        dr3 = describe(resp[3])[!, [:variable, :eltype]]
    end

    if length(resp) > 3
        dr4 = describe(resp[4])[!, [:variable, :eltype]]
    end

    drs = if length(resp) > 3
        unique(vcat(dr1, dr2, dr3, dr4))
    elseif length(resp) > 2
        unique(vcat(dr1, dr2, dr3))
    elseif length(resp) > 1
        unique(vcat(dr1, dr2))
    else
        unique(vcat(dr1))
    end

    drs = combine(groupby(drs, :variable), :eltype => Ref∘unique => :eltypes);

    drs[!, :type] = Vector{Type}(undef, nrow(drs))
    addtypes!(drs)
    vardict = Dict(drs.variable .=> drs.type);

    for rp in resp
        misvars = setdiff(drs.variable, Symbol.(names(rp)))
        for misvar in misvars
            rp[!, misvar] = Vector{vardict[misvar]}(missing, nrow(rp))
        end
    end
end

"""
        strip_wave!(resp, wnme, wavestring)

Remove wave information, since we will only keep this as a separate variable, indexing the wave for a particular variable value.
"""
function strip_wave!(resp, wnme, wavestring)
    for e in wnme
        rename!(resp, Symbol(e) => Symbol(split(e, wavestring)[1]))
    end
end

"""
    strip_and_combine_waves!(dfs, waves)

For each wave DataFrame: drop columns from earlier waves, strip the current
wave suffix, and add a `:wave` column. Then regularize column sets and vcat.

Returns the combined DataFrame.
"""
function strip_and_combine_waves!(dfs::Vector{DataFrame}, waves)
    for w in waves
        widx = findfirst(waves .== w)
        df = dfs[widx]
        suffix = "_w$(w)"

        # drop columns from earlier waves
        for earlier in 1:(w-1)
            esuffix = "_w$(earlier)"
            earlier_cols = filter(n -> occursin(esuffix, n), names(df))
            if !isempty(earlier_cols)
                select!(df, Not(earlier_cols))
            end
        end

        # strip current wave suffix
        wave_cols = filter(n -> occursin(suffix, n), names(df))
        strip_wave!(df, wave_cols, suffix)

        df[!, :wave] .= w
    end

    regularizecols!(dfs)
    return reduce(vcat, dfs)
end

function addtypes!(drs)
    for (i, e) in enumerate(drs.eltypes)
        if length(e) > 1
            for ε in e
                if Missing ∈ Base.uniontypes(ε)
                    drs.type[i] = ε
                    break
                end
                drs.type[i] = Union{e[1], Missing}
            end
        elseif length(e) == 1
            drs.type[i] = Union{e[1], Missing}
        end
    end
end

function convertspend(x)
    return if !ismissing(x)
        if (x == "Dont_Know") || (x == "Refused") || (isnothing(x))
            missing
        else
            parse(Int, x)
        end
    else
        missing
    end
end

function trydate(y)
    return try Date(y)
    catch
        missing
    end
end

trystring(x) = ismissing(x) ? missing : string(x)

todate_split(x) = ismissing(x) ? missing : trydate(split(x)[1])

"""
        age(endyear, startyear)

## Description

Calculate age based on date of birth and survey date. `endyear` and `startyear` must be formatted as `Date`.
"""
function age(endyear, startyear)
    return if ismissing(endyear) || ismissing(startyear)
        missing
    else
        year(endyear) - year(startyear)
    end
end
