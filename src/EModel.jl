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

export Emodel, emodel
