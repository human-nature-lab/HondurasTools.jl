# clean_household.jl

"""
        clean_household(hh)

Clean the household level data. `hh` must be a vector of dataframes. Data must Must be ordered by and match `waves`.

ARGS
≡≡≡≡≡≡≡≡≡≡

- resp: a vector of DataFrames, with entries for each wave of the data.
- waves: indicate the wave of each DataFrame in the same order as resp.

"""
function clean_household(hh::Vector{DataFrame}, waves; nokeymiss = true)

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

    regularizecols!(hh)

    hh = reduce(vcat, hh)

    # raw data description contains variable list and types
    hh_desc = describe(hh);

    # must be in data
    hh.building_id = categorical(hh.building_id);

    if :household_wealth_index ∈ hh_desc.variable
        hh.household_wealth_index = categorical(
            hh.household_wealth_index; ordered = true
        );
        rename!(hh, :household_wealth_index => :hh_wealth);
    end

    if :l0400 ∈ hh_desc.variable
        rename!(hh, :l0400 => :watersource);
        hh.watersource = categorical(hh.watersource);
    end

    if :l0900a ∈ hh_desc.variable
        rename!(hh, :l0900a => :elec);
        hh.elec = categorical(hh.elec);
        recode!(hh.elec, "Electricity" => "Yes", missing => "No");
    end

    # rename!(h3, :l0900b => :radio)
    # h3.radio = categorical(h3.radio)
    # recode!(h3.radio, "Radio" => "Yes", missing => "No")

    if :l0900c ∈ hh_desc.variable
        rename!(hh, :l0900c => :tv);
        hh.tv = categorical(hh.tv);
        recode!(hh.tv, "Television" => "Yes", missing => "No");
    end

    if :l0900d ∈ hh_desc.variable
        rename!(hh, :l0900d => :cell);
        hh.cell = categorical(hh.cell);
        recode!(hh.cell, "Cell/mobile phone" => "Yes", missing => "No");
    end

    if :l0900f ∈ hh_desc.variable
        rename!(hh, :l0900f => :fridge);
        hh.fridge = categorical(hh.fridge);
        recode!(hh.fridge, "Refrigerator" => "Yes", missing => "No");
    end

    if :l0900g ∈ hh_desc.variable
        rename!(hh, :l0900g => :noneof);
        hh.noneof = categorical(hh.noneof);
        recode!(hh.noneof, "None of the above" => "Yes", missing => "No");
    end

    # remove irrelevant variables
    select!(hh, Not([:household_id, :skip_glitch]));

    # rename to avoid conflicts with other data
    rename!(hh, :survey_start => :hh_survey_start);
    rename!(hh, :new_building => :hh_new_building);

    if nokeymiss
        dropmissing!(hh, :village_code);
        dropmissing!(hh, :building_id);
    end

    return hh
end
