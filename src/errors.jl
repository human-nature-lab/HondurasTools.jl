# errors.jl

"""
errors(
    css; truth = :socio4, grouping = [:kin_all, :relation, :perceiver]
)

Calculate the `type1` and `type2` error rates for the CSS data, based on
ground truth `truth`, by `grouping` variables.
"""
function errors(
    css; truth = :socio4, grouping = [:kin_all, :relation, :perceiver]
)

    edf = @chain css begin
        select([:village_code, :response, truth, grouping...])
        @transform(
            :tp = (:response .& $truth), # TP
            :fp = (:response .& .!($truth)), # FP
            :fn = (.!:response .& $truth), # FN
            :tn = (.!:response .& .!($truth)), # TN
        )
        groupby(grouping)
        @combine(
            :tp = sum(:tp),
            :fp = sum(:fp),
            :fn = sum(:fn),
            :tn = sum(:tn),
            :socio = sum($truth),
            :response = sum(:response),
            :count = length(:response)
            )
            @transform(
                :tpr = :tp ./ (:tp + :fn), # 1 - type 2
                :fpr = :fp ./ (:fp + :tn) # type 1 
            )
            sort(grouping)
    end;

    edf[!, :tnr] = 1 .- edf.fpr

    # fpr / type1 er
    edf[!, :type1] = edf.fpr;
    select!(edf, Not(:fpr))
    # fnr / type2 er
    edf[!, :type2] = 1 .- edf.tpr;


    return edf
end

export errors
