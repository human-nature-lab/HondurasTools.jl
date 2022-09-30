# clean_hh.jl

### process household level
    
function clean_household(hh_paths; selected = :standard)

    hh = [CSV.read(x, DataFrame; missingstring = "NA") for x in hh_paths];

    # strip waves
    hnme1 = names(hh[1]);
    hnme2 = names(hh[2]);
    hnme3 = names(hh[3]);

    hh[1][!, :wave] .= 1;
    hh[2][!, :wave] .= 2;
    hh[3][!, :wave] .= 3;

    whnme11 = hnme1[occursin.("_w1", hnme1)];
    strip_wave!(hh[1], whnme11, "_w1")

    # no 21
    whnme22 = hnme2[occursin.("_w2", hnme2)];
    strip_wave!(hh[2], whnme22, "_w2")

    whnme33 = hnme3[occursin.("_w3", hnme3)];
    strip_wave!(hh[3], whnme33, "_w3")

    regularizecols!(hh)

    hh = vcat(hh[1], hh[2], hh[3]);

    hh.building_id = categorical(hh.building_id);

    hh.household_wealth_index = categorical(
        hh.household_wealth_index; ordered = true
    );
    rename!(hh, :household_wealth_index => :hh_wealth);

    rename!(hh, :l0400 => :watersource);
    hh.watersource = categorical(hh.watersource);

    rename!(hh, :l0900a => :elec);
    hh.elec = categorical(hh.elec);
    recode!(hh.elec, "Electricity" => "Yes", missing => "No");

    # rename!(h3, :l0900b => :radio)
    # h3.radio = categorical(h3.radio)
    # recode!(h3.radio, "Radio" => "Yes", missing => "No")

    rename!(hh, :l0900c => :tv);
    hh.tv = categorical(hh.tv);
    recode!(hh.tv, "Television" => "Yes", missing => "No");

    rename!(hh, :l0900d => :cell);
    hh.cell = categorical(hh.cell);
    recode!(hh.cell, "Cell/mobile phone" => "Yes", missing => "No");

    rename!(hh, :l0900f => :fridge);
    hh.fridge = categorical(hh.fridge);
    recode!(hh.fridge, "Refrigerator" => "Yes", missing => "No");

    rename!(hh, :l0900g => :noneof);
    hh.noneof = categorical(hh.noneof);
    recode!(hh.noneof, "None of the above" => "Yes", missing => "No");

    if selected == :standard
        hdemos = [
            :building_id,
            :village_code,
            :hh_target,
            :household_wealth_index_w3,
            :l0400, # water source
            :l0900a, # electricity
            :l0900c, # television
            :l0900d, # cellphone
            :l0900f, # refrigerator
            :l0900g, # none of the above 
        ];
        select!(hh, hdemos);
    elseif !isnothing(selected)
        select!(hh, selected)
    end

    return hh
end

