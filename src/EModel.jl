# EModel.jl

import Base.getindex

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

import MixedModels:vif # from module

function vif(m::EModel)
    return (tpr = vif(m.tpr), fpr = vif(m.fpr),)
end

export vif

struct BiData
    tpr::DataFrame
    fpr::DataFrame
end

function bidata(dft, dff)
    return BiData(dft, dff)
end

export BiData, bidata

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
