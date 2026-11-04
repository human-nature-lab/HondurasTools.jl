using Test
using HondurasTools
using DataFrames
using Dates

include("wealth.jl")

# helpers for the "wave fill" testset

# A dict whose `keys`/iteration order is whatever we say, so a test can show
# the fill does not depend on Dict iteration (hash) order.
struct OrderedWaves <: AbstractDict{Int, Any}
    d::Dict{Int, Any}
    order::Vector{Int}
end
Base.length(p::OrderedWaves) = length(p.order)
Base.get(p::OrderedWaves, k, default) = get(p.d, k, default)
Base.getindex(p::OrderedWaves, k) = p.d[k]
Base.haskey(p::OrderedWaves, k) = haskey(p.d, k)
function Base.iterate(p::OrderedWaves, s = 1)
    s > length(p.order) && return nothing
    k = p.order[s]
    return (k => p.d[k]), s + 1
end

permutations_of(v) = length(v) <= 1 ? [copy(v)] :
    [vcat(v[i], q) for i in eachindex(v) for q in permutations_of(deleteat!(copy(v), i))]

"""
Fill one column `:x` for rows at wave `wv`, one row per entry of `props`
(each a wave => value dict). Returns `(values, impute)`.
"""
function fill_x(props, wv; noupd = Symbol[], T = String)
    ds = Dict(string(i) => (properties = Dict(:x => p),) for (i, p) in enumerate(props))
    ks = [string(i) for i in eachindex(props)]
    nf = DataFrame(name = ks, x = Vector{Union{Missing, T}}(missing, length(ks)))
    nf[!, :impute] = [Dict{Symbol, Int}() for _ in 1:nrow(nf)]
    HondurasTools._populate_datacol!(nf, :x, ds, noupd, nf.name, wv)
    return nf.x, nf.impute
end
fill1(p, wv; kw...) = ((v, imp) = fill_x([p], wv; kw...); (v[1], imp[1]))


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

# ─── cross-wave fill (`_populate_datacol!`) ───────────────────────────────────
#
# Rule: a row for wave `wv` takes its own wave's value; if that is missing, the
# latest earlier wave (wv-1, …, 1); never a later wave. Every value taken from
# another wave is recorded in `impute` with its source wave.

@testset "wave fill" begin
    @test HondurasTools.fillorder(4) == [4, 3, 2, 1]
    @test HondurasTools.fillorder(3) == [3, 2, 1]
    @test HondurasTools.fillorder(1) == [1]

    full = Dict{Int, Any}(1 => "a", 2 => "b", 3 => "c", 4 => "d")

    @testset "own value present → kept, not flagged" begin
        for wv in 1:4
            v, imp = fill1(full, wv)
            @test v == ["a", "b", "c", "d"][wv]
            @test isempty(imp)
        end
    end

    @testset "only later values → missing, not filled" begin
        v, imp = fill1(Dict{Int, Any}(4 => "d"), 1)
        @test ismissing(v) && isempty(imp)
        v, imp = fill1(Dict{Int, Any}(2 => "b", 3 => "c", 4 => "d"), 1)
        @test ismissing(v) && isempty(imp)
        v, imp = fill1(Dict{Int, Any}(1 => missing, 4 => "d"), 3)
        @test ismissing(v) && isempty(imp)
    end

    @testset "only earlier values → latest earlier one, flagged" begin
        v, imp = fill1(Dict{Int, Any}(1 => "a", 2 => "b"), 4)
        @test v == "b" && imp == Dict(:x => 2)
        v, imp = fill1(Dict{Int, Any}(1 => "a"), 3)
        @test v == "a" && imp == Dict(:x => 1)
        # own wave present as an explicit `missing`
        v, imp = fill1(Dict{Int, Any}(1 => "a", 3 => missing), 3)
        @test v == "a" && imp == Dict(:x => 1)
    end

    @testset "mixed waves" begin
        # earlier and later both present, own missing → earlier, never later
        p = Dict{Int, Any}(1 => "a", 2 => missing, 3 => missing, 4 => "d")
        @test fill1(p, 1) == ("a", Dict{Symbol, Int}())
        @test fill1(p, 2) == ("a", Dict(:x => 1))
        @test fill1(p, 3) == ("a", Dict(:x => 1))
        @test fill1(p, 4) == ("d", Dict{Symbol, Int}())

        # the audit's examples: Dict(1=>a, 3=>c, 4=>d)
        p = Dict{Int, Any}(1 => "a", 3 => "c", 4 => "d")
        @test first(fill1(p, 1)) == "a"   # was "d" (4,2,3,1) or "c" (3,2,1,4)
        @test first(fill1(p, 3)) == "c"   # was "d" under 4,2,3,1
        @test first(fill1(p, 4)) == "d"   # was "c" under 3,2,1,4
        p = Dict{Int, Any}(1 => "a", 2 => "b", 3 => missing, 4 => "d")
        @test fill1(p, 3) == ("b", Dict(:x => 2))   # W2, not W4; flagged
        @test fill1(p, 4) == ("d", Dict{Symbol, Int}())

        # several rows in one column, each row independent
        props = [
            Dict{Int, Any}(1 => "a", 4 => "d"),             # own (W3) missing, W1 earlier
            Dict{Int, Any}(3 => "c", 4 => "d"),             # own
            Dict{Int, Any}(4 => "d"),                       # later only
            Dict{Int, Any}(1 => "a", 2 => "b", 4 => "d"),   # latest earlier = W2
            Dict{Int, Any}(),                               # nothing
        ]
        v, imp = fill_x(props, 3)
        @test isequal(v, ["a", "c", missing, "b", missing])
        @test imp == [Dict(:x => 1), Dict{Symbol, Int}(), Dict{Symbol, Int}(),
                      Dict(:x => 2), Dict{Symbol, Int}()]
    end

    @testset "noupd variables: own wave only" begin
        p = Dict{Int, Any}(1 => "a", 4 => "d")
        @test fill1(p, 1; noupd = [:x]) == ("a", Dict{Symbol, Int}())
        v, imp = fill1(p, 3; noupd = [:x])
        @test ismissing(v) && isempty(imp)
    end

    @testset "type parse of filled string values" begin
        v, imp = fill1(Dict{Int, Any}(1 => "7", 4 => "9"), 2; T = Int)
        @test v === 7 && imp == Dict(:x => 1)
    end

    @testset "independent of Dict insertion and iteration order" begin
        cases = [
            Dict{Int, Any}(1 => "a", 2 => "b", 3 => "c", 4 => "d"),
            Dict{Int, Any}(1 => "a", 2 => missing, 3 => "c", 4 => "d"),
            Dict{Int, Any}(1 => "a", 2 => "b", 3 => missing, 4 => "d"),
            Dict{Int, Any}(1 => "a", 3 => missing, 4 => "d"),
            Dict{Int, Any}(1 => missing, 2 => "b", 4 => "d"),
            Dict{Int, Any}(3 => "c", 4 => "d"),
            Dict{Int, Any}(4 => "d"),
        ]
        for base in cases, wv in 1:4
            ref = fill1(base, wv)
            ks = sort(collect(keys(base)))
            for order in permutations_of(ks)
                # every iteration order of the keys
                @test isequal(fill1(OrderedWaves(base, order), wv), ref)
                # real Dicts built in every insertion order, with a perturbed
                # slot layout (filler keys inserted, then deleted)
                d = Dict{Int, Any}()
                for k in 5:40; d[k] = nothing; end
                for k in order; d[k] = base[k]; end
                for k in 5:40; delete!(d, k); end
                @test isequal(fill1(d, wv), ref)
            end
        end
        # sanity: the old call, `firstval(prop; waves = keys(prop))`, does
        # depend on iteration order, so the test above can detect the bug
        p = Dict{Int, Any}(1 => "a", 2 => "b", 3 => "c", 4 => "d")
        old = [HondurasTools.firstval(OrderedWaves(p, o); waves = o)
               for o in permutations_of([1, 2, 3, 4])]
        @test length(unique(old)) == 4
    end

    @testset "respwave end-to-end" begin
        mkr(name, waves, x) = begin
            r = respondent(name, Date(1990, 1, 1), true, waves, [:x, :survey_start, :invillage_yrs])
            for w in waves
                r.village_code[w] = 1
                r.building_id[w] = "b_" * name
                r.properties[:survey_start][w] = Date(2015 + w, 6, 1)
                r.properties[:invillage_yrs][w] = 10.0
            end
            for (w, v) in x; r.properties[:x][w] = v; end
            r
        end
        rd = Dict(
            "p1" => mkr("p1", [1, 3, 4], Dict(1 => "a", 3 => "c", 4 => "d")),
            "p2" => mkr("p2", [1, 3, 4], Dict(1 => "a", 3 => missing, 4 => "d")),
            "p3" => mkr("p3", [1, 4],    Dict(1 => missing, 4 => "d")),
        )
        noupd = [:survey_start]
        get_row(df, n) = only(df[df.name .== n, :])

        r1 = respwave(rd, noupd; wave = 1)
        @test get_row(r1, "p1").x == "a" && isempty(get_row(r1, "p1").impute)
        @test get_row(r1, "p2").x == "a"
        @test ismissing(get_row(r1, "p3").x)            # W4 answer not pulled back
        @test isempty(get_row(r1, "p3").impute)

        r3 = respwave(rd, noupd; wave = 3)
        @test sort(r3.name) == ["p1", "p2"]
        @test get_row(r3, "p1").x == "c" && isempty(get_row(r3, "p1").impute)
        @test get_row(r3, "p2").x == "a" && get_row(r3, "p2").impute == Dict(:x => 1)

        r4 = respwave(rd, noupd; wave = 4)
        @test all(==("d"), r4.x)
        @test all(isempty, r4.impute)
    end
end

@testset "indigenous coding — Chorti and Lenca are indigenous" begin
    rf = DataFrame(
        village_code = [1, 1, 1, 1, 2, 2, 2, 2, 2, 0],
        indigenous = Union{Missing,String}[
            "Yes, Maya Chorti", "Si, Maya Chorti", "Yes, Lenca", "No",
            "No", "No", "Other", "Dont_Know", missing, "Yes, Maya Chorti"],
    )
    HondurasTools._code_indigenous!(rf)
    @test isequal(rf.indigenous, ["Chorti", "Chorti", "Lenca", "No", "No", "No",
                                  missing, missing, missing, "Chorti"])
    @test isequal(rf.isindigenous, [true, true, true, false, false, false,
                                    missing, missing, missing, true])
    @test isequal(rf.notindigenous, [false, false, false, true, true, true,
                                     missing, missing, missing, false])
    # village shares over coded rows only; village 0 gets none
    @test rf.isindigenous_pct[1:4] ≈ fill(0.75, 4)
    @test all(==(0.0), rf.isindigenous_pct[5:9])
    @test ismissing(rf.isindigenous_pct[10])
    @test isequal(rf.maj_indigenous, [true, true, true, true, false, false, false, false, false, missing])
end

@testset "indigenous coding — no coded responses" begin
    for responses in (["Other", "Other"], [missing, missing], ["Refused", "Dont_Know"])
        rf = DataFrame(village_code = [1, 1],
                       indigenous = Union{Missing,String}[responses...])
        HondurasTools._code_indigenous!(rf)
        @test all(ismissing, rf.isindigenous)
        @test all(ismissing, rf.notindigenous)
        @test all(ismissing, rf.isindigenous_pct)
        @test all(ismissing, rf.maj_indigenous)
    end

    rf = DataFrame(village_code = [1, 1, 2, 2],
                   indigenous = Union{Missing,String}["Other", "Refused", "Yes, Lenca", "No"])
    HondurasTools._code_indigenous!(rf)
    @test isequal(rf.isindigenous_pct, [missing, missing, 0.5, 0.5])
    @test isequal(rf.maj_indigenous, [missing, missing, true, true])
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
    practice_vars = [k[2] for (k, v) in cb.outcome_type_index if v == "practice" && k[1] == "rct" && k[3] == 1]
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

# ─── nothing / missing hygiene ───────────────────────────────────────────────

@testset "listen block — \"Very Much\" normalised to \"Very much\" before categorical" begin
    using CategoricalArrays
    col = ["Very much", "Very Much", "A little", missing, "Dont_Know"]
    tomissing = ["Refused" => missing, "Don't remember" => missing, "Dont_Know" => missing]
    replace!(col, tomissing...)
    replace!(col, "Very Much" => "Very much")
    cat = categorical(col)
    lvls = levels(cat)
    @test "Very Much" ∉ lvls
    @test "Very much" ∈ lvls
    @test sum(skipmissing(cat .== "Very much")) == 2
end

@testset "mb_ab0110/0120 — Dont_Know replaced with missing before categorical" begin
    using CategoricalArrays
    col = ["Very much", "Dont_Know", "A little", missing, "Refused"]
    irrelreplace! = HondurasTools.irrelreplace!
    df = DataFrame(:mb_ab0110 => col)
    irrelreplace!(df, :mb_ab0110)
    df[!, :mb_ab0110] = categorical(df[!, :mb_ab0110])
    lvls = levels(df.mb_ab0110)
    @test "Dont_Know" ∉ lvls
    @test "Refused"   ∉ lvls
    @test "Very much" ∈ lvls
    @test sum(ismissing.(df.mb_ab0110)) == 3  # original missing + Dont_Know + Refused
end

@testset "outval — returns missing (not nothing) for unrecognized outcomes" begin
    tple = (32, 31)

    @test HondurasTools.outval("Flip a coin", tple)  === 32
    @test HondurasTools.outval("Sure payment", tple)  === 31

    # unrecognized value must produce missing, never nothing
    result = HondurasTools.outval("Dont_Know", tple)
    @test ismissing(result)
    @test result !== nothing

    result2 = HondurasTools.outval("some_unexpected_string", tple)
    @test ismissing(result2)
    @test result2 !== nothing
end

@testset "process_risk — unrecognized outcome yields missing risk_score, not nothing" begin
    # Construct minimal input: one row per person, columns named <prefix>_c<state*100>
    # State 31 (stage 5), state 29 (stage 4 / penultimate)
    risk_input = DataFrame(
        :name         => ["alice", "bob"],
        :village_code => [1, 2],
        Symbol("ch_c3100") => ["Flip a coin",          "Unrecognized_Outcome"],
        Symbol("ch_c2900") => ["Sure payment",          "Flip a coin"],
    )

    result = HondurasTools.process_risk(risk_input)

    # column eltype must not include Nothing
    @test !(Nothing <: eltype(result.risk_score))
    @test !(Nothing <: eltype(result.green_score))
    @test !(Nothing <: eltype(result.purple_score))

    alice = only(result[result.name .== "alice", :])
    @test alice.risk_score   === 32
    @test alice.green_score  === 8
    @test alice.purple_score === 4

    bob = only(result[result.name .== "bob", :])
    # unrecognized outcome → missing risk_score (not nothing)
    @test ismissing(bob.risk_score)
    @test bob.risk_score !== nothing
    # penultimate state still scored
    @test bob.green_score  === 8
    @test bob.purple_score === 4
end

@testset "getmoney parsing — tryparse returns missing (not nothing) for unrecognized strings" begin
    # passmissing(tryparse) was the old form: returns nothing on parse failure.
    # The fix wraps with coalesce(..., missing).
    f = passmissing(x -> something(tryparse(Int, x), missing))

    @test f("5")      === 5
    @test ismissing(f(missing))
    @test ismissing(f("Refused"))
    @test ismissing(f("NA"))
    @test ismissing(f("Dont_Know"))

    # column-level: eltype must not include Nothing
    col = [missing, "0", "Refused", "3", "NA"]
    result = f.(col)
    @test !(Nothing <: eltype(result))
    @test isequal(result, [missing, 0, missing, 3, missing])
end

@testset "relig_weekly recode — unmapped attendance values become missing, not false" begin
    attend = ["Once per week", "Never or almost never", "Rarely", missing, "More than once per week"]
    recoded = recode(
        attend,
        missing,
        "Never or almost never" => "<= Monthly",
        "Once or twice a year"  => "<= Monthly",
        "Once a month"          => "<= Monthly",
        "Once per week"         => ">= Weekly",
        "More than once per week" => ">= Weekly"
    )

    # known values map correctly
    @test recoded[1] == ">= Weekly"
    @test recoded[2] == "<= Monthly"
    # unmapped non-missing → missing (not passed through, not false)
    @test ismissing(recoded[3])
    # already-missing → still missing
    @test ismissing(recoded[4])
    @test recoded[5] == ">= Weekly"

    # downstream ifelse: unmapped → missing, not false
    weekly_flag = passmissing(ifelse).(recoded .== ">= Weekly", true, false)
    @test weekly_flag[1] === true
    @test weekly_flag[2] === false
    @test ismissing(weekly_flag[3])   # was incorrectly false before fix
    @test ismissing(weekly_flag[4])
end

@testset "convertspend — missing / refusal strings → missing; valid string → Int" begin
    @test ismissing(HondurasTools.convertspend(missing))
    @test ismissing(HondurasTools.convertspend("Dont_Know"))
    @test ismissing(HondurasTools.convertspend("Refused"))
    @test HondurasTools.convertspend("42") === 42
end

end  # HondurasTools.jl

@testset "Codebook review regressions" begin
    mbrow(id) = DataFrame(respondent_master_id=[id], village_code=[5],
                         lives_in_village=[1], works_in_village=[1])
    a, b = mbrow("a"), mbrow("b")
    b.mb_ab0110 = ["Yes"]
    combined = clean_microbiome(a, b)
    @test "mb_ab0110" in names(combined)
    @test ismissing(combined.mb_ab0110[1])
    @test combined.mb_ab0110[2] == "Yes"
    @test combined.cohort == [1, 2]
    @test !("getmoney" in names(combined))
    for value in (500, 500.0, "500", missing, "Refused")
        a, b = mbrow("a"), mbrow("b")
        a.mb_c0000 = [value]
        result = clean_microbiome(a, b)
        @test isequal(result.getmoney[1], value === missing || value == "Refused" ? missing : 500)
        @test ismissing(result.getmoney[2])
    end
    a, b = mbrow("a"), mbrow("b")
    a.mb_c0000 = [1.5]
    @test_throws ArgumentError clean_microbiome(a, b)

    cb = load_codebook()
    mktempdir() do dir
        CSV.write(joinpath(dir, "variables.csv"), cb.variables)
        CSV.write(joinpath(dir, "options.csv"), cb.options)
        derivs = copy(cb.derivations)
        derivs.outcome_type = replace(derivs.outcome_type,
            "knowledge and attitudes" => "knowled ge and attitudes",
            "intervention knowledge" => "intervent ion knowled ge")
        CSV.write(joinpath(dir, "derivations.csv"), derivs)
        external = load_codebook(path=dir)
        @test external.outcome_type_map == cb.outcome_type_map
        raw = DataFrame(respondent_master_id=["a", "b"], dia_child_zinc_ka_w2=[1, 2])
        result = clean_outcomes([raw], [2]; codebook=external)
        @test isequal(result.dia_child_zinc_ka, HondurasTools.recode_outcome([1, 2]))
        derivs.outcome_type[findfirst(!ismissing, derivs.outcome_type)] = "unknown"
        CSV.write(joinpath(dir, "derivations.csv"), derivs)
        @test_throws ArgumentError load_codebook(path=dir)
    end
    for v in (:resp_target_w1, :friend_treatment_w1, :household_target_w1)
        raw = DataFrame(respondent_master_id=["a", "b", "c"])
        raw[!, v] = [missing, 0, 1]
        result = clean_outcomes([raw], [1]; codebook=cb)
        @test isequal(result[!, Symbol(replace(string(v), "_w1"=>""))], [missing, false, true])
        raw = DataFrame(respondent_master_id=["a"])
        raw[!, v] = [2]
        @test_throws ArgumentError clean_outcomes([raw], [1]; codebook=cb)
    end
    options = DataFrame(study=fill("rct", 4), variable_id=fill("test", 4),
                        wave=[1, 1, 2, 2], option_code=[1, 2, 1, 2],
                        label_en=["No", "Yes", "No", "Yes"])
    fake = (; options, goptions=groupby(sort(options, :option_code), [:study, :variable_id]))
    @test levels(make_ordered_categorical(fake, "test", ["Yes"])) == ["No", "Yes"]
    options.label_en[3:4] = ["Yes", "No"]
    fake = (; options, goptions=groupby(sort(options, :option_code), [:study, :variable_id]))
    @test_throws ArgumentError make_ordered_categorical(fake, "test", ["Yes"])
    @test levels(make_ordered_categorical(fake, "test", ["Yes"]; wave=2)) == ["Yes", "No"]
    risk = DataFrame(name=["a"], village_code=[5], mb_c3100=["Flip a coin"])
    result = HondurasTools.process_risk(risk)
    @test result.risk_score == [32]
    @test ismissing(result.green_score[1])
    @test ismissing(result.purple_score[1])
    risk.mb_c3000 = ["Sure payment"] # also terminal: missing predecessor still safe
    @test nrow(HondurasTools.process_risk(risk)) == 1
end

@testset "Study, wave, and administration identity" begin
    derivs = DataFrame(study=["rct", "rct", "ih"], variable_id=["x_w1", "x_w2", "other_w1"],
                      outcome_type=fill("practice", 3))
    wave1 = DataFrame(respondent_master_id=["a", "b"], x_w1=[1, 2], resp_target_w1=[1, 0])
    wave2 = DataFrame(respondent_master_id=["a"], x_w2=[2])
    result = clean_outcomes(deepcopy([wave1, wave2]), [1, 2]; codebook=derivs)
    @test isequal(result.x, [false, true, true])
    @test isequal(result.resp_target, [true, false, missing])
    ih = clean_outcomes([deepcopy(wave1)], [1]; codebook=derivs, study="ih")
    @test ih.x == [1, 2]
    uncovered = DataFrame(respondent_master_id=["a"], x_w3=[1])
    @test_throws ArgumentError clean_outcomes([uncovered], [3]; codebook=derivs)
    conflict = vcat(derivs, DataFrame(study=["rct"], variable_id=["x_w1"], outcome_type=["intervention knowledge"]))
    @test_throws ArgumentError clean_outcomes([deepcopy(wave1)], [1]; codebook=conflict)
    @test_throws ArgumentError clean_outcomes([deepcopy(wave1)], [1, 2])
    @test_throws ArgumentError clean_outcomes([deepcopy(wave1), deepcopy(wave1)], [1, 1])
    @test_throws ArgumentError clean_outcomes([DataFrame(x=[1])], [1])

    function administration(id, answer)
        df = DataFrame(respondent_master_id=[id], village_code=[5],
                       lives_in_village=[1], works_in_village=[1])
        for i in 1:31
            df[!, Symbol("mb_c", lpad(i, 2, '0'), "00")] = Union{Missing,String}[missing]
        end
        df.mb_c3100[1] = answer
        df
    end
    baseline = administration("a", "Flip a coin")
    followup = administration("a", "Sure payment")
    cohort2 = administration("b", "Flip a coin")
    followup.followup_only = [42]
    result = clean_microbiome([baseline, followup, cohort2], [1, 2, 3])
    @test nrow(result) == 3
    @test result.administration == [1, 2, 3]
    @test result.cohort == [1, 1, 2]
    @test result.risk_score == [32, 31, 32]
    @test isequal(result.followup_only, [missing, 42, missing])
    @test !("administration" in names(baseline)) # no mutation on either API
    @test_throws ArgumentError clean_microbiome([vcat(baseline, baseline)], [1])
    unknown = administration(missing, "Flip a coin")
    @test nrow(clean_microbiome([unknown], [1])) == 0
    kept = clean_microbiome([unknown], [1]; nokeymiss=false)
    @test nrow(kept) == 1
    @test ismissing(kept.risk_score[1])
    @test_throws ArgumentError clean_microbiome([DataFrame(x=[1])], [1])
    @test_throws ArgumentError clean_microbiome([baseline], [4])
    risk = DataFrame(name=["a", "a"], village_code=[5, 5], mb_c3100=["Flip a coin", "Sure payment"])
    @test_throws ArgumentError HondurasTools.process_risk(risk)
    for cleaner in (clean_respondent, clean_household, clean_connections, clean_village)
        @test_throws ArgumentError cleaner([DataFrame(x=[1])], [1])
    end
    @test_throws ArgumentError clean_ihr(DataFrame(x=[1]), DataFrame(x=[1]))
end

# Full historical perception delivery, with unselected component fields missing.
function perception_fixture(n=1)
    fields = [
        :j0100, :i0800, :j0200, :i1000, :j0300, :e0900,
        :e1100, :j0400, :j0500, :e1400, :e1500, :i1200,
        :j0600, :f1900r01, :f2000, :j0700, :i1300, :j0800,
        :f2700r01, :i1500, :j0900, :j1000, :f2800, :j1100,
        :f3600, :f3700, :i1900d, :j1200, :j1300, :f4800p1,
        :j1400, :j1500, :i1900a, :j1600, :f5000, :i1900c,
        :i2200g, :j1700, :j1800, :f7000, :j1900, :i1900b,
        :c0500, :j2000a, :j2000b, :j2000c, :j2000d, :j2000e,
        :j2000f, :j2000g, :j2000h, :j2000i, :j2000j, :j2000k,
        :j2000l, :j2000m, :j2000n, :j2000o, :j2000r, :c0900b,
        :c0900c, :c0700a, :c0900d, :c0900f, :c0900g, :c0900e,
        :c0900h, :c0900i, :c0900j, :c0900k, :c0900m, :c0700b,
        :c0700c, :c0900n, :j2100, :i2900b, :j2200, :i2900d,
        :j2300, :f2600, :j2400, :i3200, :j2500, :f2900,
        :j2600, :i3300, :j2700, :j2800, :i3400, :j2900,
        :j3000, :i0300, :i0400, :i0500, :i0600, :i0700,

    ]
    append!(fields, Symbol.("f5100" .* string.(collect('a':'i'))))
    append!(fields, Symbol.("i2500" .* string.(collect('a':'k'))))
    append!(fields, [:f6000m, :c0900a, :c0700d])
    df = DataFrame([v => Vector{Union{Missing,String}}(missing, n) for v in unique(fields)])
    df.child = fill("No", n)
    df.gender = fill("man", n)
    df
end

@testset "Perception end-to-end regression checks" begin
    # Refusals are unknown, not evidence of behavior or approval.
    df = perception_fixture(7)
    df.f5100a = ["Refused", "No", "Respondent", missing, "No", "Respondent", "Dont_Know"]
    df.f5100b = [missing, missing, missing, missing, "Refused", "Refused", missing]
    df.i2500a = ["Refused", "Never", "When they are crying a lot", missing, "Never", "When they are crying a lot", "Dont_Know"]
    df.i2500b = [missing, missing, missing, missing, "Refused", "Refused", missing]
    df.i1900b = ["Refused", missing, "Giving a purgante", "Dont_Know", "Removed", "Don't know", "Don't Know"]
    clean_perception!(df)
    expected = [missing, false, true, missing, missing, true, missing]
    @test isequal(df.baby_skin, expected)
    @test isequal(df.chupon_good, expected)
    @test isequal(df.laxatives_good, [missing, false, true, missing, missing, missing, missing])

    # Already parsed numeric CSV columns and numeric strings yield the same results.
    for numeric in (:string, :integer, :float)
        df = perception_fixture()
        for (v, value) in [(:i0800, 17), (:i1000, 19), (:e1500, 1),
                            (:f2000, 2), (:i1300, 3), (:f3700, 5)]
            df[!, v] = numeric == :string ? [string(value)] : numeric == :float ? [Float64(value)] : [value]
        end
        df.f4800p1 = numeric == :string ? ["0.5"] : [0.5]
        clean_perception!(df)
        @test df.girl_partner_good == [true]
        @test df.girl_baby_good == [false]
        @test df.folic == [true]
        @test df.prenatal_care == [true]
        @test df.prenatal_care_good == [true]
        @test df.postnatal_care == [true]
        @test df.baby_bath_1dy == [true]
    end
    df = perception_fixture()
    df.i0800 = [17.5]
    @test_throws InexactError clean_perception!(df)

    df = perception_fixture(7)
    df.gender = [missing, "unknown", "man", "woman", "man", "woman", missing]
    df.f2800 = ["Partner", "Respondent", "Partner", "Partner", "Respondent", "Respondent", "Doctor"]
    clean_perception!(df)
    @test isequal(df.birthdecision, [missing, missing, "Wife/companion", "Husband/companion", "Husband/companion", "Wife/companion", "Healthcare personnel "])

    # Apply the public categorical step to actual cleaner output.
    df = perception_fixture(3)
    freq = [:j0300, :j0500, :j0600, :j0800, :j1100, :j1200, :j1400,
            :j1600, :j1700, :j1900, :j2300, :j2500, :j2700, :j2900]
    moral = [:j0100, :j0200, :j0400, :j0700, :j0900, :j1300,
             :j1500, :j1800, :j2400, :j2600, :j2800, :j3000]
    for v in freq
        df[!, v] = ["Sometimes", "Never", missing]
    end
    for v in moral
        df[!, v] = ["Good", "Bad", missing]
    end
    df.j2100 = ["Yes", "No", missing]
    df.j2200 = ["No", "Yes", missing]
    name_map = Dict{Symbol,Symbol}()
    clean_perception!(df; namedict=name_map)
    code_variables!(df)
    reverse_map = Dict(raw => output for (output, raw) in name_map)
    for v in freq
        col = df[!, reverse_map[v]]
        @test levels(col) == ["Never", "Rarely", "Sometimes", "Always"]
        @test isordered(col)
        @test ismissing(col[3])
    end
    for v in moral
        col = df[!, reverse_map[v]]
        @test levels(col) == ["Bad", "Neither", "Good"]
        @test isordered(col)
        @test ismissing(col[3])
    end
    @test isequal(df.wash_perc, [true, false, missing])
    @test isequal(df.avoid_smoke_perc, [false, true, missing])
    @test eltype(df.wash_perc) == Union{Missing,Bool}
    @test eltype(df.avoid_smoke_perc) == Union{Missing,Bool}
end
