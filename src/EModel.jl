# EModel.jl

struct ModelSet{T<:RegressionModel}
	tpr::T
	fpr::T
	j::T
end

function modelset(m1, m2, m3)
    return ModelSet(m1, m2, m3)
end

function getindex(em::ModelSet, s::Symbol)

    tpr = s != :tpr
    fpr = s != :fpr
    j = s != :j
    return if !(tpr | fpr | j)
        println("invalid index")
        nothing
    else
        getfield(em, s)
    end
end

mutable struct MMS{T<:RegressionModel}
	tpr::T
	fpr::T
	j::T
end

function mms(m1, m2, m3)
    return MMS(m1, m2, m3)
end

function getindex(em::MMS, s::Symbol)

    tpr = s != :tpr
    fpr = s != :fpr
    j = s != :j
    return if !(tpr | fpr | j)
        println("invalid index")
        nothing
    else
        getfield(em, s)
    end
end

export MMS
export mms

struct EModel{T<:RegressionModel}
    tpr::T
    fpr::T
end

function emodel(m1, m2)
    return EModel(m1, m2)
end

function emodel(ms)
    return EModel(ms[1], ms[2])
end

export EModel, emodel

function getindex(em::EModel, s::Symbol)

    tpr = s != :tpr
    fpr = s != :fpr
    return if !(tpr | fpr)
        println("invalid index")
        nothing
    else
        getfield(em, s)
    end
end

import MixedModels: bic, aic # from module

function bic(m::EModel)
    return (tpr = bic(m.tpr), fpr = bic(m.fpr),)
end

function aic(m::EModel)
    return (tpr = aic(m.tpr), fpr = aic(m.fpr),)
end

export bic, aic

import GLM:vif # from module

function vif(m::EModel)
    return (tpr = vif(m.tpr), fpr = vif(m.fpr),)
end

export vif

struct BiData
    tpr::DataFrame
    fpr::DataFrame
end

struct BiData_
    tpr::SubDataFrame
    fpr::SubDataFrame
end


function bidata(dft::DataFrame, dff::DataFrame)
    return BiData(dft, dff)
end

function bidata(dft::SubDataFrame, dff::SubDataFrame)
    return BiData_(dft, dff)
end

export BiData, BiData_, bidata

function getindex(bef::BiData, s::Symbol)

    tpr = s != :tpr
    fpr = s != :fpr
    return if !(tpr | fpr)
        println("invalid index")
        nothing
    else
        getfield(bef, s)
    end
end

export getindex

function bidatajoin(df; rates = rates)
    df = deepcopy(df)
    for r in rates
        rename!(
            df[r],
            :response => r,
            :err => Symbol("err_" * string(r)),
            :ci => Symbol("ci_" * string(r))
        )
        # select!(df[r], Not("ci"))
    end

    ndf = leftjoin(
        df[rates[1]], df[rates[2]],
        on = setdiff(
            intersect(names(df[rates[1]]), names(df[rates[2]])),
            []
        )
    )
    ndf.accuracy = tuple.(ndf.tpr, ndf.fpr)

    return ndf
end

export bidatajoin

function bidatacombine(df; rates = rates)

    x = df[rates[1]] |> deepcopy
    x.rate .= rates[1]
    x.dists_a .= missing
    
    y = df[rates[2]] |> deepcopy
    y.rate .= rates[2]

    z = vcat(x, y)
    z.verity = passmissing(ifelse).(z.rate .== :tpr, true, false)

    return z
end

export bidatacombine
