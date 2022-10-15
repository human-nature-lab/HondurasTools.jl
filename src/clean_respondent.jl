# clean_respondent_data.jl

"""
        clean_respondent(
            resp::Vector{DataFrame}; 
            nokeymiss = false,
            selected = :standard
            onlycomplete = true
        )

Clean the respondent level data. `resp` must be a vector of dataframes.

ARGS
≡≡≡≡≡≡≡≡≡≡

- resp
- waves: indicate the wave of each DataFrame in the same order as resp.
- selected: variables to select. The default is :standard, a pre-defined set, otherwise, select :all, or specify a vector of variables.

"""
function clean_respondent(
    resp::Vector{DataFrame}, waves;
    nokeymiss = false,
    selected = :standard,
    onlycomplete = true
)

    if 1 ∈ waves
        widx = findfirst(waves .== 2)
        nm1 = names(resp[widx])

        wnme11 = nm1[occursin.("_w1", nm1)]
        strip_wave!(resp[widx], wnme11, "_w1")
        resp[widx][!, :wave] .= 1;
    end

    if 2 ∈ waves
        widx = findfirst(waves .== 2)
        nm2 = names(resp[widx])

        wnme21 = nm2[occursin.("_w1", nm2)]
        select!(resp[widx], Not(wnme21))

        wnme22 = nm2[occursin.("_w2", nm2)]
        strip_wave!(resp[widx], wnme22, "_w2")
        resp[2][!, :wave] .= 2;
    end

    if 3 ∈ waves
        widx = findfirst(waves .== 3)
        nm3 = names(resp[widx])
        
        wnme31 = nm3[occursin.("_w1", nm3)]
        select!(resp[widx], Not(wnme31))
        
        wnme32 = nm3[occursin.("_w2", nm3)]
        select!(resp[widx], Not(wnme32))
    
        wnme33 = nm3[occursin.("_w3", nm3)]
        strip_wave!(resp[widx], wnme33, "_w3")
        resp[widx][!, :wave] .= 3;
    end

    if 4 ∈ waves
        widx = findfirst(waves .== 4)
        nm4 = names(resp[widx])

        wnme41 = nm4[occursin.("_w1", nm4)];
        select!(resp[widx], Not(wnme41));

        wnme42 = nm4[occursin.("_w2", nm4)];
        select!(resp[widx], Not(wnme42));

        wnme43 = nm4[occursin.("_w3", nm4)]
        select!(resp[widx], Not(wnme43))

        wnme44 = nm4[occursin.("_w4", nm4)];
        strip_wave!(resp[widx], wnme44, "_w4")

        resp[widx][!, :wave] .= 4;
    end
    
    # rf = DataFrame(
    #     [v => tp[] for (v,tp) in zip(drs.variable, drs.type)]...
    # );

    regularizecols!(resp)

    rf = reduce(vcat, resp)
    resp = nothing

    rename!(rf, :respondent_master_id => :name);

    if onlycomplete
        @subset!(rf, :complete .== 1);
    end


    rf[!, :age] = age.(rf.survey_start, rf.date_of_birth)
    # [
    #     ismissing(x) ? missing : Int(round(Dates.value(x)*inv(365); digits=0)) for x in (rf.survey_start - rf.date_of_birth)
    # ];

    rf.survey_start = [
        Dates.Date(split(rf.survey_start[i], " ")[1]) for i in 1:nrow(rf)
    ];

    rf.village_code = categorical(rf.village_code);
    rf.building_id = categorical(rf.building_id);
    rf.gender = categorical(rf.gender);

    rf_desc = describe(rf);

    for r in eachrow(rf_desc)
        if r[:nmissing] == 0
            rf[!, r[:variable]] = disallowmissing(rf[!, r[:variable]])
        end
    end

    # calculate age in yrs from survey date and date of birth

    # convert "Dont_Know" and "Refused" to missing
    # missingize!(rf, :b0100);

    if :b0100 ∈ rf_desc.variable

        rf.b0100 = categorical(rf.b0100; ordered = true);
        recode!(
            rf.b0100,
            "Dont_Know" => "Don't know",
            "Have not completed any type of school" => "None"
        )

        levels!(
            rf.b0100,
            [
                "Refused",
                "Don't know",
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
        
        rename!(rf, :b0100 => :school);
        rf[!, :educated] = copy(rf[!, :school]);
        
        recode!(
            rf[!, :educated],
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
    end

    if :b0600 ∈ rf_desc.variable
        rename!(rf, :b0600 => :religion);
        rf.religion = categorical(rf.religion);
    end

    if :b0700 ∈ rf_desc.variable
        # "Dont_Know" is important here
        rename!(rf, :b0700 => :migrateplan);
        rf.migrateplan = categorical(rf.migrateplan);

        recode!(
            rf.migrateplan,
            "Dont_Know" => "Don't know",
            "No, no plans to leave" => "No",
            "Yes, to another village inside the department of Copan" => "Inside",
            "Yes, to another village outside of the department of Copan" => "Outside",
            "Yes, to another country" => "Country"
        );
    end

    if :b0800 ∈ rf_desc.variable
        rename!(rf, :b0800 => :invillage);
        rf.invillage = categorical(rf.invillage; ordered = true);
        recode!(rf.invillage, "Dont_Know" => "Don't know");
    
        levels!(
            rf.invillage,
            [
                "Refused",
                "Don't know",
                "Less than a year",
                "More than a year",
                "Since birth"
            ]
        );
    end
    
    if :c0100 ∈ rf_desc.variable    

        rename!(rf, :c0100 => :health);
        
        recode!(rf.health, "Dont_Know" => "Don't know");
        rf[!, :health] = categorical(rf[!, :health]; ordered = true);

        levels!(
            rf[!, :health],
            [
                "Refused",
                "Don't know",
                "poor",
                "fair",
                "good",
                "very good",
                "excellent"
            ]
        );

        rf[!, :healthy] = copy(rf[!, :health]);
        recode!(
            rf[!, :healthy],
            "poor" => "No",
            "fair" => "No",
            "good" => "Yes",
            "very good" => "Yes",
            "excellent" => "Yes",
        );
    end

    if :c0200 ∈ rf_desc.variable
        rename!(rf, :c0200 => :mentalhealth);
        rf[!, :mentalhealth] = categorical(
            rf[!, :mentalhealth]; ordered = true
        );
        rf[!, :mentalhealth] = recode(
            rf[!, :mentalhealth], "Dont_Know" => "Don't know"
        );

        levels!(
            rf[!, :mentalhealth],
            [
                "Don't know",
                "Refused",
                "poor",
                "fair",
                "good",
                "very good",
                "excellent"
            ]
        );

        rf[!, :mentallyhealthy] = copy(rf[!, :mentalhealth]);
        recode!(
            rf[!, :mentallyhealthy],
            "poor" => "No",
            "fair" => "No",
            "good" => "Yes",
            "very good" => "Yes",
            "excellent" => "Yes",
        );
    end

    if :c1820 ∈ rf_desc.variable
        rename!(rf, :c1820 => :safety);
        rf.safety = categorical(rf.safety; ordered = true);
        recode!(rf.safety, "Dont_Know" => "Don't know");

        levels!(
            rf.safety,
            ["Refused", "Don't know", "Unsafe", "A little unsafe", "Safe"]
        );
    end

    if :d0100 ∈ rf_desc.variable
        rename!(rf, :d0100 => :foodworry);
        rf.foodworry = categorical(rf.foodworry; ordered = true);
        recode!(rf.foodworry, "Dont_Know" => "Don't know");
        levels!(rf.foodworry, ["Refused", "Don't know", "No", "Yes"]);
    end

    if :d0200 ∈ rf_desc.variable
        rename!(rf, :d0200 => :foodlack);
        rf.foodlack = categorical(rf.foodlack; ordered = true);
        recode!(rf.foodlack, "Dont_Know" => "Don't know");
        levels!(rf.foodlack, ["Refused", "Don't know", "No", "Yes"]);
    end

    if :d0300 ∈ rf_desc.variable
        rename!(rf, :d0300 => :foodskipadult);
        rf.foodskipadult = categorical(rf.foodskipadult; ordered = true);
        recode!(rf.foodskipadult, "Dont_Know" => "Don't know");
        levels!(rf.foodskipadult, ["Refused", "Don't know", "No", "Yes"]);
    end

    if :d0400 ∈ rf_desc.variable
        rename!(rf, :d0400 => :foodskipchild);
        rf.foodskipchild = categorical(rf.foodskipchild; ordered = true);
        recode!(rf.foodskipchild, "Dont_Know" => "Don't know");
        levels!(rf.foodskipchild, ["Refused", "Don't know", "No", "Yes"]);
    end

    if :d0700 ∈ rf_desc.variable
        rename!(rf, :d0700 => :incomesuff);
        rf.incomesuff = categorical(rf.incomesuff; ordered = true);

        recode!(
            rf.incomesuff,
            "Refused" => "Refused",
            "Dont_Know" => "Don't know",
            "It is not sufficient and there are major difficulties" => "major hardship",
            "It is not sufficient and there are difficulties" => "hardship",
            "It is sufficient, without major difficulties" => "sufficient",
            "There is enough to live on and save" => "live and save"
        );
    end

    if :e0200 ∈ rf_desc.variable
        rename!(rf, :e0200 => :partnered);
        rf.partnered = categorical(rf.partnered; ordered = true);
        recode!(rf.partnered, "Dont_Know" => "Don't know");
        levels!(rf.partnered, ["Refused", "Don't know", "No", "Yes"]);
    end

    if :e0700 ∈ rf_desc.variable
        rename!(rf, :e0700 => :pregnant);
        rf.pregnant = categorical(rf.pregnant; ordered = true);
        recode!(rf.pregnant, "Dont_Know" => "Don't know");
        levels!(rf.pregnant, ["Refused", "Don't know", "No", "Yes"]);
    end

    # ignore ivars for now
    # select!(rf, Not([:i0200, :i0300, :i0400, :i0500, :i0600, :i0700]));

    if nokeymiss
        nomiss = [:village_code, :gender, :date_of_birth, :building_id];
        dropmissing!(rf, nomiss)
    end

    if selected == :standard
        # selected demographic characteristics
        demos = [
            :name,
            :village_code,
            :resp_target,
            :building_id,
            :gender,
            :date_of_birth,
            :municipality,
            :office,
            :village_name,
            :data_source,
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
            # :i0200, # who should make household decisions (cat) 3 = together
            # :i0300, # beat spouse justified?
            # :i0400,
            # :i0500,
            # :i0600,
            # :i0700,
        ];
        select!(rf, demos);
    elseif !isnothing(selected) & (typeof(selected) == Vector{Symbol})
        select!(rf, selected)
    elseif selected == :all
        rf
    end

    return rf
end
