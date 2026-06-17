using Test
using HondurasTools
using DataFrames
using Dates

@testset "HondurasTools.jl" begin

# ─── pure utility functions ───────────────────────────────────────────────────

@testset "firstval" begin
    # returns the most-recent non-missing wave value
    @test HondurasTools.firstval(Dict(1 => "a", 3 => "b", 4 => "c")) == ("c", 4)
    @test HondurasTools.firstval(Dict(1 => "a", 3 => "b"))           == ("b", 3)
    @test HondurasTools.firstval(Dict(1 => "only"))                   == ("only", 1)

    # all-missing → (missing, 0)
    val, w = HondurasTools.firstval(Dict(1 => missing, 3 => missing))
    @test ismissing(val) && w == 0

    # sparse dict — wave not in keys must not throw KeyError (was bug #1)
    @test HondurasTools.firstval(Dict(1 => "x", 4 => "y")) == ("y", 4)

    # wave 4 missing, wave 3 present
    @test HondurasTools.firstval(Dict(1 => "a", 3 => "b", 4 => missing)) == ("b", 3)
end

@testset "addtypes!" begin
    mk(ets) = begin
        d = DataFrame(variable = [:v], eltypes = [ets])
        d[!, :type] = Vector{Type}(undef, 1)
        d
    end

    # single nullable type
    d = mk([Union{Missing,Int64}])
    HondurasTools.addtypes!(d)
    @test d.type[1] == Union{Missing, Int64}

    # multiple types; nullable first → use it
    d = mk([Union{Missing,Int64}, Int64])
    HondurasTools.addtypes!(d)
    @test d.type[1] == Union{Missing, Int64}

    # multiple types; nullable second → still found
    d = mk([Int64, Union{Missing,String}])
    HondurasTools.addtypes!(d)
    @test d.type[1] == Union{Missing, String}

    # no nullable type → fallback Union{e[1], Missing}
    d = mk([Int64, String])
    HondurasTools.addtypes!(d)
    @test d.type[1] == Union{Int64, Missing}

    # single non-nullable type
    d = mk([Float64])
    HondurasTools.addtypes!(d)
    @test d.type[1] == Union{Float64, Missing}
end

@testset "regularizecols!" begin
    df1 = DataFrame(a = [1, 2, 3], b = ["x", "y", "z"])
    df2 = DataFrame(a = [4, 5],    c = [1.0, 2.0])
    HondurasTools.regularizecols!([df1, df2])

    @test :c ∈ Symbol.(names(df1))
    @test :b ∈ Symbol.(names(df2))
    @test nrow(df1) == 3
    @test nrow(df2) == 2
    @test all(ismissing, df1.c)
    @test all(ismissing, df2.b)
end

# ─── processing pipeline ─────────────────────────────────────────────────────

@testset "variableassign! — change tracking uses correct wave pairs (1→2, 1→3, 3→4)" begin
    # respondent at waves 1, 3, 4 with constant value on :x
    vs_props = [:x]
    r = respondent("alice", missing, missing, [1, 3, 4], vs_props)
    ds = Dict("alice" => r)

    resp_df = DataFrame(
        name         = repeat(["alice"], 3),
        wave         = [1, 3, 4],
        x            = [10, 10, 10],
        village_code = [1, 1, 1],
        building_id  = ["b1", "b1", "b1"],
    )
    rgnp = combine(
        groupby(sort(resp_df, [:name, :wave]), :name),
        :wave => Ref => :wave,
        :x    => Ref => :x,
    )

    HondurasTools.variableassign!(ds, rgnp, vs_props, :name)

    # change[1] = 1→2: wave 2 absent → one side missing → true
    @test ds["alice"].change[:x][1] == true

    # change[2] = 1→3: value 10→10, same → false
    # Old bug computed 2→3 instead: wave 2 absent → one-missing → true (wrong)
    @test ds["alice"].change[:x][2] == false

    # change[3] = 3→4: value 10→10, same → false
    @test ds["alice"].change[:x][3] == false
end

@testset "variableassign! — actual change detected on 1→3" begin
    vs_props = [:x]
    r = respondent("bob", missing, missing, [1, 3, 4], vs_props)
    ds = Dict("bob" => r)

    resp_df = DataFrame(
        name         = repeat(["bob"], 3),
        wave         = [1, 3, 4],
        x            = [10, 30, 30],
        village_code = [1, 1, 1],
        building_id  = ["b1", "b1", "b1"],
    )
    rgnp = combine(
        groupby(sort(resp_df, [:name, :wave]), :name),
        :wave => Ref => :wave,
        :x    => Ref => :x,
    )

    HondurasTools.variableassign!(ds, rgnp, vs_props, :name)

    # 1→3: 10→30, changed
    @test ds["bob"].change[:x][2] == true
    # 3→4: 30→30, same
    @test ds["bob"].change[:x][3] == false
end

# ─── codebook API ────────────────────────────────────────────────────────────

@testset "load_codebook" begin
    cb = load_codebook()

    @test nrow(cb.variables)    > 0
    @test nrow(cb.options)      > 0
    @test nrow(cb.derivations)  > 0
    @test !isempty(cb.outcome_type_map)
    @test "rct" ∈ unique(cb.variables.study)

    # no double-space artifacts in outcome_type_map values (OCR normalisation)
    @test all(v -> !occursin(r"  ", v), values(cb.outcome_type_map))
end

@testset "variable_info" begin
    cb = load_codebook()

    vi = variable_info(cb, "village_code")
    @test nrow(vi) > 0
    @test all(==("village_code"), vi.variable_id)

    # missing variable → empty DataFrame with correct columns
    empty_vi = variable_info(cb, "does_not_exist_xyz")
    @test nrow(empty_vi) == 0
    @test :variable_id ∈ Symbol.(names(empty_vi))
end

@testset "variable_options" begin
    cb = load_codebook()

    # missing variable → empty
    @test nrow(variable_options(cb, "does_not_exist_xyz")) == 0

    # a known variable with options
    opts = variable_options(cb, "invillage")
    if !isempty(opts)
        @test :option_code ∈ Symbol.(names(opts))
        @test :label_en    ∈ Symbol.(names(opts))
        # sorted by option_code at load time
        @test opts.option_code == sort(opts.option_code)
    end
end

@testset "variables_by_type / variables_by_level" begin
    cb = load_codebook()

    @test !isempty(variables_by_type(cb, "survey"))
    @test  isempty(variables_by_type(cb, "not_a_real_type"))

    @test !isempty(variables_by_level(cb, "respondent"))
    @test  isempty(variables_by_level(cb, "not_a_real_level"))
end

# ─── clean_outcomes ───────────────────────────────────────────────────────────

@testset "clean_outcomes — wave suffix stripping and rename" begin
    df = DataFrame(
        respondent_master_id = ["a", "b"],
        village_code         = [1, 2],
        diarrhea_zinc_w1     = [0, 1],
        resp_target_w1       = [1, 0],
    )
    result = clean_outcomes([df], [1])

    @test :name ∈ Symbol.(names(result))
    @test "diarrhea_zinc" ∈ names(result)
    @test "resp_target"   ∈ names(result)
    @test "diarrhea_zinc_w1" ∉ names(result)
    @test nrow(result) == 2
end

@testset "clean_outcomes — codebook recode" begin
    cb = load_codebook()
    practice_vars = [k for (k, v) in cb.outcome_type_map if v == "practice"]
    if !isempty(practice_vars)
        v = first(practice_vars)
        df = DataFrame(
            respondent_master_id = ["a", "b", "c"],
            village_code         = [1, 1, 2],
        )
        df[!, Symbol(v * "_w1")] = [0, 1, missing]

        result = clean_outcomes([df], [1]; codebook = cb)
        @test eltype(result[!, v]) == Union{Missing, Bool}
    end
end

end  # HondurasTools.jl
