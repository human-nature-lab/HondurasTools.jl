# code_variables.jl

function code_variables!(df)
    ns = names(df)
    
    ## individuals
    if "name" ∈ ns
        df.name = categorical(df.name)
    end
    if "perceiver" ∈ ns
        df.perceiver = categorical(df.perceiver)
    end

    # not ordered
    for v in [:village_code, :gender, :religion]
        if string(v) ∈ ns
            df[!,v] = categorical(df[!, v])
        end
    end

    if "b0510" ∈ ns
        replace!(df[!, "relig_import"], [rx => missing for rx in HondurasTools.rms]...)

        df[!, :relig_import] = categorical(df[!, :relig_import]; ordered = true);

        levels!(
            df[!, :relig_import],
            ["Not at all important",
            "Not very important",
            "Somewhat important",
            "Very important"], allowmissing = true
        );
    end

    v = "relig_freq"
    if v ∈ ns
        replace!(df[!, v], [rx => missing for rx in HondurasTools.rms]...)

        df[!, Symbol(v)] = categorical(df[!, Symbol(v)]; ordered = true);

        levels!(
            df[!, Symbol(v)],
            ["Never"
            "Sometimes"
            "About once a day"
            "More than once a day"], allowmissing = true
        );
    end

    v = "relig_attend"
    if v ∈ ns
        replace!(df[!, v], [rx => missing for rx in HondurasTools.rms]...)

        df[!, Symbol(v)] = categorical(df[!, Symbol(v)]; ordered = true);

        levels!(
            df[!, Symbol(v)],
            ["Never or almost never"
            "Once or twice a year"
            "Once a month"
            "Once per week"
            "More than once per week"], allowmissing = true
        );
    end

    # ordered
    v = :safety
    if string(v) ∈ ns
        replace!(df[!, v], [rm => missing for rm in rms]...);
        df.safety = categorical(df[!, v]; ordered = true);
        levels!(
            df[!, v],
            ["Refused", "Don't know", "Unsafe", "A little unsafe", "Safe"]
        );
    end

    if "occupation" ∈ ns
        df[!, :occupation] = categorical(df[!, :occupation]);
    end

    if "incomesuff" ∈ ns
        replace!(df[!, :incomesuff], [rm => missing for rm in rms]...);
        df.incomesuff = categorical(df.incomesuff; ordered = true);
        
        # N.B. names are simplified from original
        levels!(
            df.incomesuff,
            ["major hardship", "hardship", "sufficient", "live and save"]
        );
    end
    
    if "school" ∈ ns
        replace!(df[!, :school], [rm => missing for rm in rms]...);
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
    end

    if "invillage" ∈ ns
        replace!(df[!, :invillage], [rm => missing for rm in rms]...);
        df.invillage = categorical(df.invillage; ordered = true);
        levels!(
            df.invillage, ["Less than a year", "More than a year", "Since birth"]
        );
    end

    if "migrateplan" ∈ ns
        replace!(df[!, :migrateplan], [rm => missing for rm in rms]...);
        df.migrateplan = categorical(df.migrateplan; ordered = true)
        levels!(
            df.migrateplan, ["No", "Inside", "Outside", "Country"];
            allowmissing = true
        )
    end

    if "educated" ∈ ns
        replace!(df[!, :educated], [rm => missing for rm in rms]...);
        df.educated = categorical(df.educated)
        levels!(
            df.educated, ["No", "Some", "Yes"]; allowmissing = true
        )
    end

    if "indigenous" ∈ ns
        replace!(df[!, :indigenous], [rm => missing for rm in rms]...);
        df.indigenous = categorical(df.indigenous);
        levels!(df.indigenous, ["No", "Other", "Lenca", "Chorti"]);
    end

    ## household variables
    if "handwash" ∈ ns
        replace!(df[!, :handwash], [rm => missing for rm in rms]...);
        df.handwash = categorical(df.handwash; ordered = true);
        levels!(df.handwash, ["Not observed", "Observed, water not available", "Observed, water available"])
    end

    if "watersource" ∈ ns
        replace!(df[!, :watersource], [rm => missing for rm in rms]...);

        replace!(df.watersource, "Dug well (proctected)" => "Dug well (protected)", "Water from spring (unproctected)" => "Water from spring (unprotected)");
        replace!(df.watersource, "Surface water (river/dam/lake/pond/stream/canal/irrigation channel)" => "Surface water")
        
        df.watersource = categorical(df.watersource)
        levels!(
            df.watersource,
            [
                "Rainwater"
                "Surface water"
                "bottle water"
                "Water from spring (unprotected)"
                "Cart with small tank"
                "Water from spring (protected)"
                "Dug well (unprotected)"
                "Dug well (protected)"
                "Well with tube"
                "Other"
            ]
        );
    end

    if "toilettype" ∈ ns
        replace!(df[!, :toilettype], [rm => missing for rm in rms]...);
        df.toilettype = categorical(df.toilettype; ordered=true);
        levels!(df.toilettype, [
            "No facility (other home/establishment)"
            "No facility (other location)"
            "No facility (outdoors)"
            "Septic latrine"   
            "Bucket toilet"
            "Composting toilet"
            "Flush toilet"
        ])
    end

    if "toiletshared" ∈ ns
        binarize!(df, :toiletshared)
    end

    v = "kitchen"
    if string(v) ∈ ns
        binarize!(df, v)
    end

    if "cooktype" ∈ ns
        replace!(df[!, :cooktype], [rm => missing for rm in rms]...);
        df.cooktype = categorical(df.cooktype)
        replace!(df.cooktype, "Other" => missing)
        levels!(df.cooktype, [
            "None (there is no stove/firebox)"
            "Furnace/firebox without a chimney"
            "Furnace/firebox with a chimney"
            "Stove"
        ])
    end

    if "cookfueltype" ∈ ns
        replace!(df[!, :cookfueltype], [rm => missing for rm in rms]...);
        df.cookfueltype = categorical(df.cookfueltype);
        replace!(df.cookfueltype, "Keronsene" => "Kerosene")
        levels!(df.cookfueltype, [
            "None"
            "Other"
            "Wood"
            "Kerosene"
            "Gas (cylinder)"
            "Electricity"
        ])
    end

    if "windows" ∈ ns
        replace!(df[!, :windows], [rm => missing for rm in rms]...);
        df.windows = categorical(df.windows);
        replace!(df.windows, "Don't Know" => missing);
        levels!(
            df.windows,
            ["There aren't windows", "Other", "Yes, unfinished windows", "Yes, wooden windows", "Yes, metal windows", "Yes, glass windows"
        ]);
    end

    if "walltype" ∈ ns
        replace!(df[!, :walltype], [rm => missing for rm in rms]...);
        df.walltype = categorical(df.walltype);
        replace!(df.walltype, "Other" => missing, "Don't Know" => missing);
        levels!(
            df.walltype,
            ["There are no walls", "Discarded materials", "Clay/uncovered adobe/mud", "Cane/palm/trunks", "Clay bricks", "Cement blocks", "Wood (polished)", "Wood (unpolished)"]
        );
    end

    if "roofing" ∈ ns
        replace!(df[!, :roofing], [rm => missing for rm in rms]...);
        df.roofing = categorical(df.roofing)
        replace!(df.roofing, "Other" => missing, "Don't Know" => missing);
        levels!(df.roofing, [
            "No roof"
            "Thatch/palm leaf"
            "Plastic sheets/tiles"
            "Wood planks"
            "Clay tiles"
            "Concrete/concrete tiles"
            "Metal (aluminum/zinc sheets)"
        ]);
    end

    ## village-level

    if "hotel_hostel" ∈ ns
        df.hotel_hostel = passmissing(ifelse).(df.hotel_hostel .== 1, true, false);
    end

    if "access_to_village" ∈ ns
        df.access_to_village = replace(
            df.access_to_village, 1=>"Good", 2=>"Average", 3=> "Poor"
        );
        df.access_to_village = categorical(df.access_to_village; ordered = true);
        levels!(df.access_to_village, ["Poor", "Average", "Good"])
    end

    if "trash" ∈ ns
        df.trash = replace(
            df.trash, 1 => "None", 2 => "A little", 3 => "Some", 4 => "A lot"
        )
        df.trash = categorical(df.trash; ordered = true)
        levels!(df.trash, ["None", "A little", "Some", "A lot"], allowmissing=true);
    end

    ## perceptions (in respondent-level data)

    # code perception variables
    freqscale = ["Never", "Rarely", "Sometimes", "Always"];
    goodness = ["Bad", "Neither", "Good"];

    v = :girl_partner_moralperc
    if string(v) ∈ ns
        df[!, v] = categorical(df[!, v]; ordered = true)
        # assign levels to scale
        levels!(df[!, v], goodness)
    end

    v = :girl_baby_moralperc
    if string(v) ∈ ns
        df[!, v] = categorical(df[!, v]; ordered = true)
        levels!(df[!, v], goodness)
    end

    v = :avoid_preg_perc
    if string(v) ∈ ns
        df[!, v] = categorical(df[!, v]; ordered = true);
        levels!(df[!, v], freqscale);
    end

    v = :avoid_preg_moralperc
    if string(v) ∈ ns
        df[!, v] = categorical(df[!, v]; ordered = true);
        levels!(df[!, v], goodness);
    end

    v = :folic_perc
    if string(v) ∈ ns
        df[!, v] = categorical(df[!, v]; ordered = true)
        levels!(df[!, v], freqscale)
    end

    v = :folic_good_when
    if string(v) ∈ ns
        df[!, v] = categorical(df[!, v]; ordered = false)
    end

    v = :prenatal_care_perc
    if string(v) ∈ ns
        df[!, v] = categorical(df[!, v]; ordered = true);
        levels!(df[!, v], freqscale);
    end

    v = :prenatal_care_moralperc
    if string(v) ∈ ns
        df[!, v] = categorical(df[!, v]; ordered = true);
        levels!(df[!, v], goodness);
    end

    v = :homebirth_perc;
    if string(v) ∈ ns
        df[!, v] = categorical(df[!, v]; ordered = true);
        levels!(df[!, v], freqscale);
    end

    v = :homebirth_moralperc
    if string(v) ∈ ns
        df[!, v] = categorical(df[!, v]; ordered = true);
        levels!(df[!, v], goodness);
    end

    v = :birth_good_where
    if string(v) ∈ ns
        df[!, v] = categorical(df[!, v]; ordered = false);
    end

    v = :birthdecision_perc;
    if string(v) ∈ ns
        df[!, v] = categorical(df[!, v]; ordered = false);
    end

    v = :birthdecision;
    if string(v) ∈ ns
        df[!, v] = categorical(df[!, v]; ordered = false);
    end

    v = :postnatal_care_perc;
    if string(v) ∈ ns
        df[!, v] = categorical(df[!, v]; ordered = true);
        levels!(df[!, v], freqscale);
    end

    v = :baby_bath_perc;
    if string(v) ∈ ns
        df[!, v] = categorical(df[!, v]; ordered = true);
        levels!(df[!, v], freqscale);
    end

    v = :baby_bath_moralperc;
    if string(v) ∈ ns
        df[!, v] = categorical(df[!, v]; ordered = true);
        levels!(df[!, v], goodness);
    end

    v = :fajero_perc;
    if string(v) ∈ ns
        df[!, v] = categorical(df[!, v]; ordered = true);
        levels!(df[!, v], freqscale);
    end

    v = :chupon_perc
    if string(v) ∈ ns
        df[!, v] = categorical(df[!, v]; ordered = true);
        levels!(df[!, v], freqscale);
    end

    v = :father_check_perc
    if string(v) ∈ ns
        df[!, v] = categorical(df[!, v]; ordered = true);
        levels!(df[!, v], freqscale);
    end

    v = :father_check_moralperc
    if string(v) ∈ ns
        df[!, v] = categorical(df[!, v]; ordered = true);
        levels!(df[!, v], goodness);
    end

    v = :father_wait_perc
    if string(v) ∈ ns
        df[!, v] = categorical(df[!, v]; ordered = true);
        levels!(df[!, v], freqscale);
    end

    v = :father_wait_moralperc
    if string(v) ∈ ns
        df[!, v] = categorical(df[!, v]; ordered = true);
        levels!(df[!, v], goodness);
    end

    v = :father_care_sick_perc
    if string(v) ∈ ns
        df[!, v] = categorical(df[!, v]; ordered = true);
        levels!(df[!, v], freqscale);
    end

    v = :men_hit_perc
    if string(v) ∈ ns
        df[!, v] = categorical(df[!, v]; ordered = true);
        levels!(df[!, v], freqscale);
    end

    v = :men_hit_moralperc
    if string(v) ∈ ns
        df[!, v] = categorical(df[!, v]; ordered = true);
        levels!(df[!, v], goodness);
    end
end;

export code_variables!