using Test, HondurasTools, LinearAlgebra

# Frozen output of real FactoMineR runs: normal tests do not need R installed.
# Sign alignment uses fitting rows only, never supplementary observations.
@testset "FactoMineR reference agreement" begin
    fixture_dir = joinpath(@__DIR__, "fixtures", "wealth_factominer")
    for case in ("complete", "missing", "constant", "rare")
        @testset "$case" begin
            df = CSV.read(joinpath(fixture_dir, case * "_input.csv"), DataFrame;
                          missingstring="__MISSING__")
            expected = CSV.read(joinpath(fixture_dir, case * "_scores.csv"), DataFrame;
                                missingstring="__MISSING__")
            eigenvalues = CSV.read(joinpath(fixture_dir, case * "_eigenvalues.csv"), DataFrame)
            indicators = [:tv, :floor, :water, :roof]
            case == "constant" && push!(indicators, :fixed)
            result = wealth_indices(df; indicators,
                anchor=(column=:tv, low="no", high="yes"),
                missing_policy=case == "missing" ? :category : :error)
            @test result.scores.building_id == expected.building_id
            @test result.scores.wave == expected.wave
            max_error = 0.0
            for wave in (1, 3)
                rows = findall(==(wave), df.wave)
                eigen = eigenvalues[eigenvalues.wave .== wave, :]
                model = result.wave_models[wave]
                @test model.eigenvalues ≈ eigen.eigenvalue atol=1e-12 rtol=1e-10
                @test model.total_inertia ≈ first(eigen.total_inertia) atol=1e-12 rtol=1e-10
                for d in 1:2
                    actual = Float64.(result.scores[rows, Symbol("wealth_within_d", d)])
                    reference = expected[rows, Symbol("within_d", d)]
                    direction = sign(dot(actual, reference))
                    @test actual ≈ direction .* reference atol=1e-10 rtol=1e-10
                    max_error = max(max_error, maximum(abs.(actual - direction .* reference)))
                end
            end
            fitting_rows = findall(==(1), df.wave)
            for source in ("common", "predict"), d in 1:2
                actual = Float64.(result.scores[!, Symbol("wealth_common_d", d)])
                reference = expected[!, Symbol(source, "_d", d)]
                # FactoMineR 2.18 predict.MCA propagates raw NA in newdata;
                # MCA(ind.sup=...) instead treats NA as a category. Julia's
                # explicit :category policy agrees with the latter on ALL rows.
                expected_missing = source == "predict" && case == "missing" ?
                    [df.wave[i] == 3 && any(ismissing, df[i, indicators]) for i in 1:nrow(df)] :
                    falses(nrow(df))
                @test ismissing.(reference) == expected_missing
                valid = .!expected_missing
                direction = sign(dot(actual[fitting_rows], Float64.(reference[fitting_rows])))
                numeric_reference = Float64.(reference[valid])
                @test actual[valid] ≈ direction .* numeric_reference atol=1e-10 rtol=1e-10
                max_error = max(max_error, maximum(abs.(actual[valid] - direction .* numeric_reference)))
            end
            println("FactoMineR $case: maximum absolute coordinate error = $max_error")
        end
    end
end
