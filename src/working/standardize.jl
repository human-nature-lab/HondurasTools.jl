# standardize.jl

"""
Using the ZScore convenience fn. to do UnitRange transformation

for use with StandardizedPredictors.jl
"""
function transformunitvalues(x)
    return (
        minimum(skipmissing(x)),
        maximum(skipmissing(x)) - minimum(skipmissing(x)),
    )
end

"""
        applytransform!(transforms, vbl; tr = UnitRangeTransform)

Skip `missing` and `NaN`.
"""
function applytransform!(transforms, vbl, df; tr = UnitRangeTransform)
    cl = collect(sa(df[!, vbl])) * 1.0
    transforms[vbl] = fit(tr, cl, dims=1)
end

# use css perceiver values extrema to standardize
function standards(df)
    transforms = Dict{Symbol, AbstractDataTransform}();

    # respondent
    vbls = [
        :age, :age_ln, :age2,
        :sleepingrooms, :children_under12,
        :total_churches, :catholic_church, :protestant_church,
        :total_athletic_areas, :total_schools,
        :elevation,
        # network distances
        :dists_p, :dists_a, :union_dists_p, :union_dists_a,
        :dists_p_i
    ];
    
    for vbl in vbls
        if string(vbl) ∈ names(df)
            applytransform!(transforms, vbl, df; tr = UnitRangeTransform)
        end
    end

    # network
    for (k, _) in node_fund
        if string(k) ∈ names(df)
            applytransform!(transforms, k, df; tr = UnitRangeTransform)
        end
    end
    
    for vbl in[:modularity_religion]
        if string(vbl) ∈ names(df)
            applytransform!(transforms, vbl, df; tr = UnitRangeTransform)
        end
    end

    # microbiome
    vbls = [:spend, :risk_score, :cognitive_score];
    for vbl in vbls
        if string(vbl) ∈ names(df)
            applytransform!(transforms, vbl, df; tr = UnitRangeTransform)
        end
    end

    return transforms
end

function applystandards!(df, transforms)
    for (v, dt) in transforms
        df[!, v] = df[!, v] * 1.0;
        idx = .!ismissing.(df[!, v])
        vnm = df[idx, v]
        vnm = disallowmissing(vnm)
        df[idx, v] = StatsBase.transform(dt, vnm) 
    end;
end

function reversestandards!(df, transforms)
    for (v, dt) in transforms
        idx = .!ismissing.(df[!, v])
        vnm = df[idx, v]
        vnm = disallowmissing(vnm)
        df[idx, v] = StatsBase.reconstruct(dt, vnm)
    end;
end

export standards, applystandards!, reversestandards!

# use css perceiver values extrema to standardize
function standardize_vars(df)
    contrasts = Dict{Symbol, ZScore}();

    # demographics

    # respondent
    vbls = [
        :age, :age_ln,
        :sleepingrooms, :children_under12,
        :total_churches, :catholic_church, :protestant_church,
        :total_athletic_areas, :total_schools,
        :elevation,
        # network distances
        :dists_p, :dists_a, :union_dists_p, :union_dists_a,
        :dists_p_i,
    ]
    for vbl in vbls
        contrasts[vbl] = ZScore(transformunitvalues(df[!, vbl])...);
    end

    # network
    for (k, _) in node_fund
        contrasts[k] = ZScore(transformunitvalues(df[!, k])...);
    end
    for vb in[:modularity_religion]
        contrasts[vb] = ZScore(transformunitvalues(df[!, vb])...);
    end

    # microbiome
    # vbls = [:spend, :risk_score, :cognitive_score]
    # for vbl in vbls
    #     contrasts[vbl] = ZScore(transformunitvalues(mb[!, vbl])...);
    # end

    # distances
    
    #contrasts[:nodedistance] = ZScore(transformunitvalues(nd.distance[.!isnan.(nd.distance)])...);

    # for e in distmetrics
    #     contrasts[e] = ZScore(transformunitvalues(css[!, e])...)
    # end

    # for e in [:degree_centrality,  :betweenness_centrality,  :closeness_centrality, :local_clustering_coefficient, :triangles]
    #     contrasts[e] = ZScore(transformunitvalues(ndf[ndf.relationship .∈ Ref(["free_time", "personal_private", "kin"]), e])...);
    # end 

    # for e in vcat(centralities_ft, centralities_pp)
    #     contrasts[e] = ZScore(transformunitvalues(css[!, e])...)
    # end
    return contrasts
end

export standardize_vars

# contrasts for tie properties
# contrasts[:age_a] = contrasts[:age];
# contrasts[:risk_score_a] = contrasts[:risk_score];
# contrasts[:spend_a] = contrasts[:spend];

# # these should probably be set based on resp values if possible
# let
#     # contrasts for within-tie differences
#     vbl = :age
#     mn, mx = extrema(skipmissing(resp[!, vbl]))
#     contrasts[:age_ad] = ZScore(0, mx - mn)

#     vbl = :spend
#     mn, mx = extrema(skipmissing(css[!, vbl]))
#     contrasts[:spend_ad] = ZScore(0, mx - mn)

#     vbl = :risk_score
#     mn, mx = extrema(skipmissing(css[!, vbl]))
#     contrasts[:risk_score_ad] = ZScore(0, mx - mn)
# end