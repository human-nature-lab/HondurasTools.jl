# code_variables.jl



## individuals

function code_variables!(df)
    ns = names(df)
    
    if "name" ∈ ns
        df.name = categorical(df.name)
    end
    if "perceiver" ∈ ns
        df.perceiver = categorical(df.perceiver)
    end

    # not ordered
    for v in [:village_code, :gender, :religion]
        df[!,v] = categorical(df[!, v])
    end

    # ordered
    df.safety = categorical(df.safety; ordered = true);
    levels!(
        df.safety,
        ["Refused", "Don't know", "Unsafe", "A little unsafe", "Safe"]
    );

    df.incomesuff = categorical(df.incomesuff; ordered = true);
    
    # levels!(
    #     df.incomesuff,
    #     "It is not sufficient and there are major difficulties" => "major hardship",
    #     "It is not sufficient and there are difficulties" => "hardship",
    #     "It is sufficient, without major difficulties" => "sufficient",
    #     "There is enough to live on and save" => "live and save"
    # );

    levels!(
        df.incomesuff,
        ["major hardship", "hardship", "sufficient", "live and save"]
    );

    df.school = categorical(df.school; ordered = true);

    levels!(
        df.school,
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

    df.invillage = categorical(df.invillage; ordered = true);
    levels!(
        df.invillage, ["Less than a year", "More than a year", "Since birth"]
    );

    df.migrateplan = categorical(df.migrateplan; ordered = true)
    levels!(
        df.migrateplan, ["No", "Inside", "Outside", "Country"];
        allowmissing = true
    )

    df.educated = categorical(df.educated)
    levels!(
        df.educated, ["No", "Some", "Yes"]; allowmissing = true
    )    

    # ## health

    # df.healthy = categorical(df.healthy)

    # ## mental health


    # levels!(
    #     df.mentalhealth,
    #     ["Don't know", "poor", "fair", "good", "very good", "excellent"];
    #     allowmissing = true
    # ) # Refused

    # df.mentallyhealthy = categorical(df.mentallyhealthy, ordered = true)
    # recode!(
    #     df.mentallyhealthy,
    #     "poor" => "No",
    #     "fair" => "No",
    #     "good" => "Yes",
    #     "very good" => "Yes",
    #     "excellent" => "Yes",
    # );


    # ## food

    # df.foodworry = categorical(df.foodworry; ordered = true);
    # levels!(df.foodworry, ["Refused", "Don't know", "No", "Yes"]);

    # df.foodlack = categorical(df.foodlack; ordered = true);
    # levels!(df.foodlack, ["Refused", "Don't know", "No", "Yes"]);

    # df.foodskipadult = categorical(df.foodskipadult; ordered = true);
    # levels!(df.foodskipadult, ["Refused", "Don't know", "No", "Yes"]);

    # df.foodskipchild = categorical(df.foodskipchild; ordered = true);
    # levels!(df.foodskipchild, ["Refused", "Don't know", "No", "Yes"]);

    # ## pregnant

    # df.pregnant = categorical(df.pregnant; ordered = true);
    # levels!(df.pregnant, ["Refused", "Don't know", "No", "Yes"]);

    # df.indigenous = categorical(df.indigenous)

    # ## age

    # df.agecat = categorical(df.agecat; ordered = true);

    # ## microbiome

    # mb[!, :cognitive_status] = categorical(
    #     mb[!, :cognitive_status];
    #     levels = ["none", "impairment", "dementia"]
    # )

    # mb.village_code = categorical(mb.village_code)
    # mb.name = categorical(mb.name)
    # mb.cognitive_status = categorical(mb.cognitive_status; ordered = true);
    # mb.whereborn = categorical(mb.whereborn)
    # mb.dept = categorical(mb.dept)

    # ## household

    # hh.building_id = categorical(hh.building_id);
    # hh.hh_wealth = categorical(
    #     hh.hh_wealth; ordered = true
    # );

    # let
    #     vbl = [
    #         :watersource, :cleaningagent, :toilettype, :toiletshared, :cooktype, :cookfueltype, :flooring, :windows, :walltype, :roofing
    #     ];
    #     for v in vbl
    #         hh[!, v] = categorical(hh[!, v])
    #     end
    # end

    ## perceptions

    # code perception variables
    freqscale = ["Never", "Rarely", "Sometimes", "Always"];
    goodness = ["Bad", "Neither", "Good"];

    v = :girl_partner_moralperc

    df[!, v] = categorical(df[!, v]; ordered = true)
    # assign levels to scale
    levels!(df[!, v], goodness)

    v = :girl_baby_moralperc
    df[!, v] = categorical(df[!, v]; ordered = true)
    levels!(df[!, v], goodness)

    v = :avoid_preg_perc
    df[!, v] = categorical(df[!, v]; ordered = true);
    levels!(df[!, v], freqscale);

    v = :avoid_preg_moralperc
    df[!, v] = categorical(df[!, v]; ordered = true);
    levels!(df[!, v], goodness);

    v = :folic_perc
    df[!, v] = categorical(df[!, v]; ordered = true)
    levels!(df[!, v], freqscale)

    v = :folic_good_when
    df[!, v] = categorical(df[!, v]; ordered = false)

    v = :prenatal_care_perc
    df[!, v] = categorical(df[!, v]; ordered = true);
    levels!(df[!, v], freqscale);

    v = :prenatal_care_moralperc
    df[!, v] = categorical(df[!, v]; ordered = true);
    levels!(df[!, v], goodness);

    v = :homebirth_perc;
    df[!, v] = categorical(df[!, v]; ordered = true);
    levels!(df[!, v], freqscale);

    v = :homebirth_moralperc
    df[!, v] = categorical(df[!, v]; ordered = true);
    levels!(df[!, v], goodness);

    v = :birth_good_where
    df[!, v] = categorical(df[!, v]; ordered = false);

    v = :birthdecision_perc;
    df[!, v] = categorical(df[!, v]; ordered = false);

    v = :birthdecision;
    df[!, v] = categorical(df[!, v]; ordered = false);

    v = :postnatal_care_perc;
    df[!, v] = categorical(df[!, v]; ordered = true);
    levels!(df[!, v], freqscale);

    v = :baby_bath_perc;
    df[!, v] = categorical(df[!, v]; ordered = true);
    levels!(df[!, v], freqscale);

    v = :baby_bath_moralperc;
    df[!, v] = categorical(df[!, v]; ordered = true);
    levels!(df[!, v], goodness);

    v = :fajero_perc;
    df[!, v] = categorical(df[!, v]; ordered = true);
    levels!(df[!, v], freqscale);

    v = :chupon_perc
    df[!, v] = categorical(df[!, v]; ordered = true);
    levels!(df[!, v], freqscale);

    v = :father_check_perc
    df[!, v] = categorical(df[!, v]; ordered = true);
    levels!(df[!, v], freqscale);

    v = :father_check_moralperc
    df[!, v] = categorical(df[!, v]; ordered = true);
    levels!(df[!, v], goodness);

    v = :father_wait_perc
    df[!, v] = categorical(df[!, v]; ordered = true);
    levels!(df[!, v], freqscale);

    v = :father_wait_moralperc
    df[!, v] = categorical(df[!, v]; ordered = true);
    levels!(df[!, v], goodness);

    v = :father_care_sick_perc
    df[!, v] = categorical(df[!, v]; ordered = true);
    levels!(df[!, v], freqscale);

    v = :men_hit_perc
    df[!, v] = categorical(df[!, v]; ordered = true);
    levels!(df[!, v], freqscale);

    v = :men_hit_moralperc
    df[!, v] = categorical(df[!, v]; ordered = true);
    levels!(df[!, v], goodness);
end;

export code_variables!
