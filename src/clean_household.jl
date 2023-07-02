# clean_household.jl

"""
        clean_household(hh, waves; nokeymiss = true)

Clean the household level data. `hh` must be a vector of dataframes. Data must Must be ordered by and match `waves`.

ARGS
≡≡≡≡≡≡≡≡≡≡

- resp: a vector of DataFrames, with entries for each wave of the data.
- waves: indicate the wave of each DataFrame in the same order as resp.
- nokeymiss = true : whether to filter to not missing on key variables: village code and building id

"""
function clean_household(hh::Vector{DataFrame}, waves; nokeymiss = true)

    # check presence of each wave
    # remove `_wx` suffix

    if 1 ∈ waves
        widx = findfirst(waves .== 1)

        hnme1 = names(hh[widx]);
        hh[widx][!, :wave] .= 1;
        whnme11 = hnme1[occursin.("_w1", hnme1)];
        strip_wave!(hh[widx], whnme11, "_w1")
    end

    if 2 ∈ waves
        widx = findfirst(waves .== 2)

        hnme2 = names(hh[widx]);
        hh[widx][!, :wave] .= 2;
        # no 21
        whnme22 = hnme2[occursin.("_w2", hnme2)];
        strip_wave!(hh[widx], whnme22, "_w2")
    end
       
    if 3 ∈ waves
        widx = findfirst(waves .== 3)

        hnme3 = names(hh[widx]);
        hh[widx][!, :wave] .= 3;
        whnme33 = hnme3[occursin.("_w3", hnme3)];
        strip_wave!(hh[widx], whnme33, "_w3")
    end

    # make a common set of columns that includes all unique
    # (e.g., if column only present a wave 1, it is present)
    regularizecols!(hh)

    # combine waves
    hh = reduce(vcat, hh)

    # raw data description contains variable list and types
    hh_desc = describe(hh);

    # remove irrelevant variables
    for e in [:household_id, :skip_glitch]
        if e ∈ hh_desc.variable
            select!(hh, Not(e))
        end
    end

    # rename to avoid conflicts with other data
    rename!(hh, :survey_start => :hh_survey_start);
    rename!(hh, :new_building => :hh_new_building);

    # must be in data
    hh.building_id = categorical(hh.building_id);

    if :household_wealth_index ∈ hh_desc.variable
        hh.household_wealth_index = categorical(
            hh.household_wealth_index; ordered = true
        );
        rename!(hh, :household_wealth_index => :hh_wealth);
    end

    xs = [
        (:l0100 => :children_under12, false, missing),
        (:l0200 => :girls_under12, false, missing),
        (:l0300 => :boys_under12, false, missing),
        (:l0400 => :watersource, true, ["Dont_Know" => "Don't Know"]),
        (:l0600 => :cleaningagent, true, ["Dont_Know" => "Don't Know"]),
        (:l0700 => :toilettype, true, ["Dont_Know" => "Don't Know"]),
        (:l0800 => :toiletshared, true, ["Dont_Know" => "Don't Know"]),
        (
            :l0900a => :electricity, true,
            ["Electricity" => "Yes", missing => "No"]
        ),
        (
            :l0900b => :radio, true,
            ["Radio" => "Yes", missing => "No"]
        ),
        (
            :l0900c => :tv, true,
            ["Television" => "Yes", missing => "No"]
        ),
        (
            :l0900d => :cell, true,
            ["Cell/mobile phone" => "Yes", missing => "No"]
        ),
        (
            :l0900e => :landline, true,
            ["Non-mobile phone" => "Yes", missing => "No"]
        ),
        (:l0900f => :fridge, true, ["Refrigerator" => "Yes", missing => "No"]),
        (:l1000 => :cooktype, true, ["Dont_Know" => "Don't Know"]),
        (:l1100 => :cookfueltype, true, ["Dont_Know" => "Don't Know"]),
        (:l1200 => :kitchen, true, ["Dont_Know" => "Don't Know"]),
        (:l1300 => :flooring, true, ["Dont_Know" => "Don't Know"]),
        (:l1400 => :windows, true, ["Dont_Know" => "Don't Know"]),
        (:l1500 => :walltype, true, ["Dont_Know" => "Don't Know"]),
        (:l1600 => :roofing, true, ["Dont_Know" => "Don't Know"]),
        (
            :l0900g => :noneof, true,
            ["None of the above" => "Yes", missing => "No"]
        )
    ];

    vs = [(:l0100, :children_under12), (:l0200, :boys_under12), (:l0300, :girls_under12)]

    for (vold, v) in vs
        if vold ∈ hh_desc.variable
            vx = Vector{Union{Missing, Int}}(missing, length(hh[!, v]))
            for (i, e) in enumerate(hh[!, v])
                if !ismissing(e)
                    x = tryparse(Int, e)
                    if !isnothing(x)
                        vx[i] = x
                    end
                end
            end
            hh[!, v] = vx
            if !any(ismissing.(hh[!, v]))
                disallowmissing!(hh, v)
            end
        end
    end
    
    for (pr, t, c) in xs
        (xold, x) = pr
        if xold ∈ hh_desc.variable
            rename!(hh, pr)
            if t
                hh[!, x] = categorical(hh[!, x]);
                if !ismissing(c)
                    recode!(hh[!, x],  c...)
                end

                # if really binary make boolean
                tst = sort(collect(skipmissing(unique(hh[!, x]))))
                if tst == ["No", "Yes"]
                    xv = Vector{Union{Missing, Bool}}(missing, length(hh[!, x]))
                    for (i, e) in enumerate(hh[!, x])
                        if !ismissing(e)
                            xv[i] = if e == "Yes"
                                true
                            elseif e == "No"
                                false
                            end
                        end
                    end
                    hh[!, x] = xv
                end
            end

            if !any(ismissing.(hh[!, x]))
                disallowmissing!(hh, x)
            end
        end
    end

    # decisions related to role of women
    xs = [
        (
            :i0200 => :how_husband_earnings_spent, true,
            ["Dont_Know" => "Don't Know"]
        ),
        (
            :i0300 => :beating_wife_neglect_children, true,
            ["Dont_Know" => "Don't Know"]
        ),
        (
            :i0400 => :beating_wife_leaves_house, true,
            ["Dont_Know" => "Don't Know"]
        ),
        (
            :i0500 => :beating_wife_argues, true,
            ["Dont_Know" => "Don't Know"]
        ),
        (
            :i0600 => :beating_burns_food, true,
            ["Dont_Know" => "Don't Know"]
        ),
        (
            :i0700 => :beating_refuse_sex, true,
            ["Dont_Know" => "Don't Know"]
        ),
        (
            :i0800 => :girl_join_partner_age, false,
            missing
        ),
        (
            :i0900 => :girl_join_partner_parents_decide, true,
            ["Dont_Know" => "Don't Know"]
        ),
        (
            :i1000 => :girl_first_baby_age, false, 
            missing
        ),
        (
            :i1100 => :woman_health_decision, true,
            ["Dont_Know" => "Don't Know"]
        ),
        (
            :i1200 => :woman_when_folic_acid, true,
            ["Dont_Know" => "Don't Know"]
        ),
        (
            :i1300 => :women_pregnancy_checkups, true,
            ["Dont_Know" => "Don't Know"]
        ),
        (
            :i1300 => :women_pregnancy_checkups, false,
            missing
        )
    ];

    # handle integer variables
    vs = [
        (:i0800, :girl_join_partner_age), (:i1000, :girl_first_baby_age),
        (:i1300, :women_pregnancy_checkups)
    ];
    
    for (vold, v) in vs
        if vold ∈ hh_desc.variable
            vx = Vector{Union{Missing, Int}}(missing, length(hh[!, v]))
            for (i, e) in enumerate(hh[!, v])
                if !ismissing(e)
                    x = tryparse(Int, e)
                    if !isnothing(x)
                        vx[i] = x
                    end
                end
            end
            hh[!, v] = vx
            if !any(ismissing.(hh[!, v]))
                disallowmissing!(hh, v)
            end
        end
    end

    for (pr, t, c) in xs
        (xold, x) = pr
        if xold ∈ hh_desc.variable
            rename!(hh, pr)
            if t
                hh[!, x] = categorical(hh[!, x]);
                if !ismissing(c)
                    recode!(hh[!, x], c...)
                end

                # if really binary make boolean
                tst = sort(collect(skipmissing(unique(hh[!, x]))))
                if tst == ["No", "Yes"]
                    xv = Vector{Union{Missing, Bool}}(missing, length(hh[!, x]))
                    for (i, e) in enumerate(hh[!, x])
                        if !ismissing(e)
                            xv[i] = if e == "Yes"
                                true
                            elseif e == "No"
                                false
                            end
                        end
                    end
                    hh[!, x] = xv
                end
            end
            
            if !any(ismissing.(hh[!, x]))
                disallowmissing!(hh, x)
            end
        end
    end

    # filters

    if nokeymiss
        dropmissing!(hh, :village_code);
        dropmissing!(hh, :building_id);
    end

    return hh
end
