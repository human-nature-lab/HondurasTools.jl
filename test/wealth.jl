using Test, HondurasTools, LinearAlgebra, Statistics

include("wealth_reference.jl")
include("wealth_pipeline.jl")

@testset "Wealth MCA" begin
    anchor = (column=:tv, low=false, high=true)
    # One binary variable has analytically known MCA coordinates and inertia.
    binary = DataFrame(tv=[false, false, false, true])
    model = fit_wealth(binary; indicators=[:tv], anchor, ndims=1)
    @test model.eigenvalues ≈ [1.0]
    @test model.total_inertia ≈ 1.0
    @test Float64.(score_wealth(model, binary)[:, 1]) ≈ [-1/sqrt(3), -1/sqrt(3), -1/sqrt(3), sqrt(3)]
    @test Float64.(score_wealth(model, DataFrame(tv=[true, false]))[:, 1]) ≈ [sqrt(3), -1/sqrt(3)]

    df = DataFrame(tv=[false,false,true,true,true,false],
                   floor=["a","b","b","c","c","a"])
    model = fit_wealth(df; indicators=[:tv,:floor], anchor, ndims=3)
    coords = Float64.(score_wealth(model, df))
    # Independent CA identity: full coordinate distances equal chi-square
    # distances between the indicator row profiles; covariance gives inertia.
    z = Float64[0 1 1 0 0; 0 1 0 1 0; 1 0 0 1 0;
                1 0 0 0 1; 1 0 0 0 1; 0 1 1 0 0]
    profiles = z / 2
    masses = vec(mean(profiles; dims=1))
    for i in 1:6, j in 1:6
        @test sum(abs2, coords[i,:] - coords[j,:]) ≈ sum((profiles[i,:] - profiles[j,:]).^2 ./ masses) atol=1e-12
    end
    @test vec(mean(coords; dims=1)) ≈ zeros(3) atol=1e-12
    @test coords' * coords / 6 ≈ Diagonal(model.eigenvalues) atol=1e-12
    @test model.total_inertia ≈ 1.5
    perm = [6,2,4,1,5,3]
    reordered = fit_wealth(df[perm,:]; indicators=[:tv,:floor], anchor, ndims=3)
    @test Float64.(score_wealth(reordered, df)) ≈ coords atol=1e-12
    catdf = copy(df)
    catdf.floor = categorical(catdf.floor)
    @test Float64.(score_wealth(model, catdf)) ≈ coords
    constant = copy(df)
    constant.fixed = fill("same", nrow(df))
    fixedmodel = fit_wealth(constant; indicators=[:tv,:floor,:fixed], anchor, ndims=3)
    @test Float64.(score_wealth(fixedmodel, constant)) ≈ coords * sqrt(2/3) atol=1e-12

    w1 = hcat(DataFrame(building_id=1:6, wave=fill(1,6)), df)
    w3 = w1[[1,2,3,4,4,5],:]
    w3.building_id = 1:6
    w3.wave .= 3
    combined = vcat(w1,w3)[[12,1,7,2,8,3,9,4,10,5,11,6],:]
    original = deepcopy(combined)
    result = wealth_indices(combined; indicators=[:tv,:floor], anchor)
    @test combined == original
    @test result.scores.building_id == combined.building_id
    @test result.scores.wave == combined.wave
    @test Matrix(result.scores[:, [:wealth_common_d1,:wealth_common_d2]]) ≈ score_wealth(result.reference_model, combined)
    for i in 1:nrow(combined), j in 1:nrow(combined)
        if combined.tv[i] == combined.tv[j] && combined.floor[i] == combined.floor[j]
            @test result.scores.wealth_common_d1[i] ≈ result.scores.wealth_common_d1[j]
        end
    end
    @test any(abs.(result.scores.wealth_within_d1 - result.scores.wealth_common_d1) .> 0.01)
    @test_throws ArgumentError wealth_indices(vcat(w1,w1); indicators=[:tv,:floor], anchor)
    @test_throws ArgumentError wealth_indices(w1; indicators=[:tv,:floor], anchor, reference_wave=9)
    @test_throws ArgumentError fit_wealth(df; indicators=[:tv,:floor], anchor, ndims=4)
    @test_throws ArgumentError fit_wealth(df; indicators=[:tv,:tv], anchor)
    @test_throws ArgumentError fit_wealth(df; indicators=[:tv], anchor=(column=:tv,low=false,high="absent"), ndims=1)

    new = DataFrame(tv=[false,true],floor=["unseen","b"])
    @test_throws ArgumentError score_wealth(model, new)
    partial = score_wealth(model, new; unknown=:missing)
    @test all(ismissing, partial[1,:])
    @test all(!ismissing, partial[2,:])
    incomplete = DataFrame(tv=[false,false,true,true,true,false],floor=[missing,"b","b","c","c","a"])
    @test_throws ArgumentError fit_wealth(incomplete; indicators=[:tv,:floor], anchor)
    missmodel = fit_wealth(incomplete; indicators=[:tv,:floor], anchor, missing_policy=:category)
    @test all(!ismissing, score_wealth(missmodel, incomplete))
    @test_throws ArgumentError score_wealth(model, incomplete; unknown=:missing)
    @test_throws ArgumentError fit_wealth(DataFrame(tv=fill(true,4)); indicators=[:tv], anchor, ndims=1)
end
