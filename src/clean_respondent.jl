# clean_respondent_data.jl

"""
        clean_respondent(respondent_paths, hh_pth)

Clean the respondent level data. Currently only processes the W3 data (uses prior waves to fill in selected missing values).
"""
function clean_respondent(respondent_paths, hh_pth)

    # load data
    resp = [
        CSV.read(df, DataFrame; missingstring = "NA") for df in respondent_paths
    ];
    h3 = CSV.read(hh_pth, DataFrame; missingstring = "NA");

    # drop wave names
    for (k, rp) in enumerate(resp)
        rename!(
            rp,
            Symbol("village_code_w"*string(k)) => :village_code,
            :respondent_master_id => :name,
            Symbol("building_id_w"*string(k)) => :building_id
        );
        gender_cleaning!(rp.gender)
    end
        
    # selected demographic characteristics
    demos = [
        :name, :village_code,
        :building_id,
        :gender,
        :date_of_birth,
        :survey_start,
        :inter_village_leader,
        :b0100, # grade in school
        :b0600, # what is your religion
        :b0700, # plans to leave village w/in 12 mo
        :b0800, # how long lived in village (cat)
        :b1000, # leader
        :c0100, # general health self-report
        :c0200, # mental-health self-report
        :c1820, # safety walking in village at night
        :d0100, # worry about food lack
        :d0200, # food lack
        :d0300, # skip meals adult money
        :d0400, # skip meals child money
        :d0700, # family income (ordinal)
        :e0200, # married or "free union"
        :e0700, # currently pregnant
        :i0200, # who should make household decisions (cat) 3 = together
        :i0300, # beat spouse justified?
        :i0400,
        :i0500,
        :i0600,
        :i0700,
    ];

    replace_withold!(resp[3], resp[2], resp[1], :date_of_birth)

    sum(ismissing.(resp[3][!, :b0100]))
    replace_withold!(resp[3], resp[2], resp[1], :b0100);
    sum(ismissing.(resp[3][!, :b0100]))

    sum(ismissing.(resp[3][!, :gender]))
    replace_withold!(resp[3], resp[2], resp[1], :gender);
    sum(ismissing.(resp[3][!, :gender]))

    sum(ismissing.(resp[3][!, :b0600]))
    replace_withold!(resp[3], resp[2], resp[1], :b0600);
    sum(ismissing.(resp[3][!, :b0600]))

    r3 = deepcopy(resp[3]);
    @subset!(r3, :complete .== 1)
    select!(r3, demos)

    r3.survey_start = [
        Dates.Date(split(r3.survey_start[i], " ")[1]) for i in 1:nrow(r3)
    ];

    r3.village_code = categorical(r3.village_code);
    rename!(r3, :b0600 => :religion)
    
    r3.religion = categorical(r3.religion);
    r3.gender = categorical(r3.gender);

    r3_desc = describe(r3)

    for r in eachrow(r3_desc)
        if r[:nmissing] == 0
            r3[!, r[:variable]] = disallowmissing(r3[!, r[:variable]])
        end
    end

    # calculate age in yrs from survey date and date of birth
    r3[!, :age] = [ismissing(x) ? missing : Int(round(Dates.value(x)*inv(365); digits=0)) for x in (r3.survey_start - r3.date_of_birth)];

    # convert "Dont_Know" and "Refused" to missing
    missingize!(r3, :b0100)
    r3.b0100 = categorical(r3.b0100; ordered = true)
    unique(r3.b0100)
    recode!(r3.b0100, "Have not completed any type of school" => "None")

    levels!(
        r3.b0100,
        [
            "None",
            "1st grade",
            "2nd grade",
            "3rd grade",
            "4th grade",
            "5th grade",
            "6th grade",
            "Some secondary",
            "Secondary",
            "More than secondary"
        ]
    );
    rename!(r3, :b0100 => :school)

    r3[!, :educated] = copy(r3[!, :school])
    recode!(
        r3[!, :educated],
        "None" => "No",
        "1st grade" => "Some",
        "2nd grade" => "Some",
        "3rd grade" => "Some",
        "4th grade" => "Some",
        "5th grade" => "Some",
        "6th grade" => "Yes",
        "Some secondary" => "Yes",
        "Secondary" => "Yes",
        "More than secondary" => "Yes"
    );

    # don't convert refused, dont know -> these are meaningful here
    # unique(r3.religion)
    # missingize!(r3, :religion)
    r3.religion = categorical(r3.religion);

    # "Dont_Know" is important here
    rename!(r3, :b0700 => :migrateplan);
    r3.migrateplan = categorical(r3.migrateplan);

    recode!(
        r3.migrateplan,
        "Dont_Know" => "Don't know",
        "No, no plans to leave" => "No",
        "Yes, to another village inside the department of Copan" => "Inside",
        "Yes, to another village outside of the department of Copan" => "Outside",
        "Yes, to another country" => "Country"
    );

    rename!(r3, :b0800 => :invillage);
    r3.invillage = categorical(r3.invillage; ordered = true);
    recode!(r3.invillage, "Dont_Know"  => missing);

    levels!(
        r3.invillage,
        [
            "Less than a year",
            "More than a year",
            "Since birth"
        ]
    );

    rename!(r3, :c0100 => :health);
    r3[!, :health] = categorical(r3[!, :health]; ordered = true);
    r3[!, :health] = recode(r3[!, :health], "Dont_Know" => missing);

    levels!(
        r3[!, :health],
        [
            "poor",
            "fair",
            "good",
            "very good",
            "excellent"
        ]
    );

    r3[!, :healthy] = copy(r3[!, :health]);
    recode!(
        r3[!, :healthy],
        "poor" => "No",
        "fair" => "No",
        "good" => "Yes",
        "very good" => "Yes",
        "excellent" => "Yes",
    );

    rename!(r3, :c0200 => :mentalhealth);
    r3[!, :mentalhealth] = categorical(r3[!, :mentalhealth]; ordered = true);
    r3[!, :mentalhealth] = recode(r3[!, :mentalhealth], "Dont_Know" => missing);

    levels!(
        r3[!, :mentalhealth],
        [
            "poor",
            "fair",
            "good",
            "very good",
            "excellent"
        ]
    );

    rename!(r3, :c1820 => :safety);
    r3.safety = categorical(r3.safety; ordered = true);
    levels(r3.safety);
    recode!(r3.safety, "Dont_Know" => "Don't know");

    levels!(
        r3.safety,
        ["Unsafe", "A little unsafe", "Don't know", "Safe"]
    );

    rename!(r3, :d0100 => :foodworry);
    r3.foodworry = categorical(r3.foodworry);

    rename!(r3, :d0200 => :foodlack);
    r3.foodlack = categorical(r3.foodlack);

    rename!(r3, :d0300 => :foodskipadult);
    r3.foodskipadult = categorical(r3.foodskipadult);

    rename!(r3, :d0400 => :foodskipchild);
    r3.foodskipchild = categorical(r3.foodskipchild);

    rename!(r3, :d0700 => :incomesuff);
    r3.incomesuff = categorical(r3.incomesuff; ordered = true);

    recode!(
        r3.incomesuff,
        "Refused" => "Refused",
        "It is not sufficient and there are major difficulties" => "major hardship",
        "It is not sufficient and there are difficulties" => "hardship",
        "Dont_Know" => "Don't know",
        "It is sufficient, without major difficulties" => "sufficient",
        "There is enough to live on and save" => "live and save"
    );

    rename!(r3, :e0200 => :partnered);
    r3.partnered = categorical(r3.partnered);

    rename!(r3, :e0700 => :pregnant);
    r3.pregnant = categorical(r3.pregnant);

    # ignore ivars for now
    select!(r3, Not([:i0200, :i0300, :i0400, :i0500, :i0600, :i0700]));

    ### process household level
    
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

    select!(h3, hdemos);

    h3.building_id = categorical(h3.building_id);

    h3.household_wealth_index_w3 = categorical(
        h3.household_wealth_index_w3; ordered = true
    );
    rename!(h3, :household_wealth_index_w3 => :hh_wealth);

    rename!(h3, :l0400 => :watersource);
    h3.watersource = categorical(h3.watersource);

    rename!(h3, :l0900a => :elec);
    h3.elec = categorical(h3.elec);
    recode!(h3.elec, "Electricity" => "Yes", missing => "No");

    # rename!(h3, :l0900b => :radio)
    # h3.radio = categorical(h3.radio)
    # recode!(h3.radio, "Radio" => "Yes", missing => "No")

    rename!(h3, :l0900c => :tv);
    h3.tv = categorical(h3.tv);
    recode!(h3.tv, "Television" => "Yes", missing => "No");

    rename!(h3, :l0900d => :cell);
    h3.cell = categorical(h3.cell);
    recode!(h3.cell, "Cell/mobile phone" => "Yes", missing => "No");

    rename!(h3, :l0900f => :fridge);
    h3.fridge = categorical(h3.fridge);
    recode!(h3.fridge, "Refrigerator" => "Yes", missing => "No");

    rename!(h3, :l0900g => :noneof);
    h3.noneof = categorical(h3.noneof);
    recode!(h3.noneof, "None of the above" => "Yes", missing => "No");

    r3.building_id = categorical(r3.building_id);

    nomiss = [:gender, :date_of_birth, :building_id];
    dropmissing!(r3, nomiss)
    dropmissing!(h3, [:village_code, :building_id])

    r3 = leftjoin(r3, h3, on = [:building_id, :village_code]);
    return r3
end
