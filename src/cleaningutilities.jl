# cleaning_utilities.jl

"""
        regularizecols!(resp)

Make it possible to combine the dataframes from different waves, which may have different columns. This function creates a common set of columns for merging.
"""
_colinfo(df) = DataFrame(variable = Symbol.(names(df)), eltype = eltype.(eachcol(df)))

# Cheap replacement for describe() when only :variable and :nmissing are needed
_fast_desc(df) = DataFrame(
    variable = Symbol.(names(df)),
    nmissing = Int[Missing <: eltype(df[!, c]) ? count(ismissing, df[!, c]) : 0 for c in names(df)]
)

function regularizecols!(resp)

    drs = unique(reduce(vcat, [_colinfo(df) for df in resp]))

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
        rename!(resp, Symbol(e) => Symbol(chopsuffix(e, wavestring)))
    end
end

"""
    strip_and_combine_waves!(dfs, waves)

For each wave DataFrame: drop columns from earlier waves, strip the current
wave suffix, and add a `:wave` column. Then regularize column sets and vcat.

Returns the combined DataFrame.
"""
function strip_and_combine_waves!(dfs::Vector{DataFrame}, waves)
    _validate_waves(dfs, waves, "wave combination")
    for w in waves
        widx = findfirst(waves .== w)
        df = dfs[widx]
        suffix = "_w$(w)"

        # drop columns from earlier waves
        for earlier in 1:(w-1)
            esuffix = "_w$(earlier)"
            earlier_cols = filter(n -> endswith(n, esuffix), names(df))
            if !isempty(earlier_cols)
                select!(df, Not(earlier_cols))
            end
        end

        # strip current wave suffix
        wave_cols = filter(n -> endswith(n, suffix), names(df))
        strip_wave!(df, wave_cols, suffix)

        df[!, :wave] .= w
    end

    regularizecols!(dfs)
    return reduce(vcat, dfs)
end

function addtypes!(drs)
    for (i, e) in enumerate(drs.eltypes)
        nullable_idx = findfirst(ε -> Missing ∈ Base.uniontypes(ε), e)
        drs.type[i] = if !isnothing(nullable_idx)
            e[nullable_idx]
        else
            Union{e[1], Missing}
        end
    end
end

function convertspend(x)
    return if !ismissing(x)
        if (x == "Dont_Know") || (x == "Refused")
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

function _require_columns(df, required, context)
    absent = setdiff(Symbol.(required), Symbol.(names(df)))
    isempty(absent) || throw(ArgumentError("$context requires columns: $(join(absent, ", "))"))
    return nothing
end

function _validate_waves(dfs, waves, context; required=Symbol[])
    !isempty(dfs) && length(dfs) == length(waves) ||
        throw(ArgumentError("$context requires nonempty tables and one wave per table"))
    allunique(waves) || throw(ArgumentError("$context requires distinct waves"))
    all(w -> w isa Integer && w in 1:4, waves) ||
        throw(ArgumentError("$context supports integer RCT waves 1–4"))
    for (df, w) in zip(dfs, waves)
        normalized = Symbol.(chopsuffix.(names(df), "_w$w"))
        absent = setdiff(required, normalized)
        isempty(absent) || throw(ArgumentError("$context wave $w requires columns: $(join(absent, ", "))"))
    end
end
