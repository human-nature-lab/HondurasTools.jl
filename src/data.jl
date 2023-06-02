# data.jl

"""
        transformunitvalues(x)

Using the ZScore convenience fn. to do UnitRange transformation. For use with StandardizedPredictors.

"""
function transformunitvalues(x)
    return (
        minimum(skipmissing(x)),
        maximum(skipmissing(x)) - minimum(skipmissing(x)),
    )
end
