# parametricbootstrap2

import MixedModels:fixef!, SVector, getθ!

function parametricbootstrap2(
    rng::AbstractRNG,
    n::Integer,
    morig::MixedModel{T},
    ftype::Type{<:AbstractFloat}=T;
    β::AbstractVector=coef(morig),
    σ=morig.σ,
    θ::AbstractVector=morig.θ,
    use_threads::Bool=false,
    progress::Bool=true,
    hide_progress::Union{Bool,Nothing}=nothing,
    optsum_overrides=(;),
) where {T}
    if !isnothing(hide_progress)
        Base.depwarn(
            "`hide_progress` is deprecated, please use `progress` instead." *
            "NB: `progress` is a positive action, i.e. `progress=true` means show the progress bar.",
            :parametricbootstrap; force=true)
        progress = !hide_progress
    end
    if σ !== missing
        σ = T(σ)
    end
    β, θ = convert(Vector{T}, β), convert(Vector{T}, θ)
    βsc, θsc = similar(ftype.(β)), similar(ftype.(θ))
    p, k = length(β), length(θ)
    m = deepcopy(morig)
    for (key, val) in pairs(optsum_overrides)
        setfield!(m.optsum, key, val)
    end
    # this seemed to slow things down?!
    # _copy_away_from_lowerbd!(m.optsum.initial, morig.optsum.final, m.lowerbd; incr=0.05)

    β_names = Tuple(Symbol.(fixefnames(morig)))

    use_threads && Base.depwarn(
        "use_threads is deprecated and will be removed in a future release",
        :parametricbootstrap,
    )
    samp = replicate(n; progress) do
        try
            simulate!(rng, m; β, σ, θ)
            refit!(m; progress=false)
            # @info "" m.optsum.feval
            (
                objective=ftype.(m.objective),
                σ = ismissing(m.σ) ? missing : ftype(m.σ),
                β = NamedTuple{β_names}(fixef!(βsc, m)),
                se = SVector{p,ftype}(stderror!(βsc, m)),
                θ = SVector{k,ftype}(getθ!(θsc, m)),
            )
        catch # see if trying one more time when it breaks is enough to do the trick...
            simulate!(rng, m; β, σ, θ)
            refit!(m; progress=false)
            # @info "" m.optsum.feval
            (
                objective=ftype.(m.objective),
                σ = ismissing(m.σ) ? missing : ftype(m.σ),
                β = NamedTuple{β_names}(fixef!(βsc, m)),
                se = SVector{p,ftype}(stderror!(βsc, m)),
                θ = SVector{k,ftype}(getθ!(θsc, m)),
            )
        end
    end
    return MixedModelBootstrap{ftype}(
        samp,
        map(vv -> ftype.(vv), morig.λ), # also does a deepcopy if no type conversion is necessary
        getfield.(morig.reterms, :inds),
        ftype.(morig.optsum.lowerbd[1:length(first(samp).θ)]),
        NamedTuple{Symbol.(fnames(morig))}(map(t -> Tuple(t.cnames), morig.reterms)),
    )
end
