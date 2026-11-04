using Test, HondurasTools

@testset "Julia wealth CSV pipeline" begin
    mktempdir() do dir
        input = CSV.read(joinpath(@__DIR__, "fixtures", "wealth_factominer", "complete_input.csv"), DataFrame)
        input.building_id = lpad.(string.(input.building_id), 3, '0')
        input_path = joinpath(dir, "df_mca.csv")
        CSV.write(input_path, input)
        indicators = [:tv, :floor, :water, :roof]
        anchor = (column=:tv, low="no", high="yes")
        outdir = joinpath(dir, "output")
        result = write_wealth_indices(input_path; indicators, anchor, output_dir=outdir,
                                     imputed_path=input_path)
        combined = CSV.read(joinpath(outdir, "wealth_indices.csv"), DataFrame;
                            types=Dict(:building_id=>String))
        within = CSV.read(joinpath(outdir, "wealth_index.csv"), DataFrame;
                          types=Dict(:building_id=>String))
        common = CSV.read(joinpath(outdir, "wealth_index_reference.csv"), DataFrame;
                          types=Dict(:building_id=>String))
        @test names(within) == names(common) == ["building_id", "wave", "wealth_d1", "wealth_d2", "imputed"]
        @test within.building_id == repeat(input.building_id, 2)
        @test combined.imputed == vcat(falses(nrow(input)), trues(nrow(input)))
        @test within.wealth_d1 ≈ combined.wealth_within_d1
        @test common.wealth_d1 ≈ combined.wealth_common_d1
        @test common.wealth_d2 ≈ repeat(result.regular.scores.wealth_common_d2, 2)
        # A failed second input must not overwrite previously produced files.
        previous = read(joinpath(outdir, "wealth_indices.csv"))
        @test_throws Exception write_wealth_indices(input_path; indicators, anchor,
            output_dir=outdir, imputed_path=joinpath(dir, "absent.csv"))
        @test read(joinpath(outdir, "wealth_indices.csv")) == previous

        # Execute the actual replacement entry point with a config file.
        config_path = joinpath(dir, "config.jl")
        write(config_path, repr((; input_path, indicators, anchor, output_dir=outdir)))
        repo = dirname(@__DIR__)
        run(`$(Base.julia_cmd()) --startup-file=no --project=$repo $(joinpath(repo, "wealth", "wealth-mca.jl")) $config_path`)
        cli = CSV.read(joinpath(outdir, "wealth_indices.csv"), DataFrame)
        @test nrow(cli) == nrow(input)
        @test !any(cli.imputed)
        @test cli.wealth_common_d1 ≈ result.regular.scores.wealth_common_d1
    end
end
