"""
        load_mbvillages(dataset)

Load the set of microbiome villages.

Example
====

data("ds1_Krackhardt")

"""
function load_mbvillages()
    dd = joinpath(dirname(@__FILE__), "..", "codebook")
    return read(dd * "/microbiome_villages.csv", DataFrame)
end
