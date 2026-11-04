# code_variables.jl

"""
    code_variables!(df; cb = nothing)

Apply categorical coding to cleaned columns in `df`. Hardcoded levels reflect
post-cleaning string values, which often differ from raw survey option labels
in the codebook (different case, simplified wording). Use `make_ordered_categorical`
from `cb` for new variables not yet listed here.
"""
function code_variables!(df; cb = nothing)
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

    v = :religion
    if string(v) ∈ ns
        df.protestant = passmissing(ifelse).(df.religion .== "Protestant", true, false);
    end
    
    let vbls = [:health, :mentalhealth]
        for v in vbls
            if string(v) ∈ ns
                df[!, v] = categorical(df[!, v]; ordered = true);

                levels!(
                    df[!, v],
                    ["Poor", "Fair", "Good", "Very good", "Excellent"]);
            end
        end
    end

    v = :agecat
    if string(v) ∈ ns
        df[!, v] = categorical(df[!, v]; ordered = true)
        levels!(df[!, v], ["<= 65", "> 65", "> 70", "> 75", "> 80"])
    end
    
    if "relig_import" ∈ ns
        
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
        df[!, v] = categorical(df[!, v]; ordered = true);
        levels!(df[!, v], ["Unsafe", "A little unsafe", "Safe"]);
    end

    if "occupation" ∈ ns
        df[!, :occupation] = categorical(df[!, :occupation]);
    end

    if "incomesuff" ∈ ns
        df.incomesuff = categorical(df.incomesuff; ordered = true);
        # N.B. names are simplified from original
        levels!(
            df.incomesuff,
            ["major hardship", "hardship", "sufficient", "live and save"]
        );
    end
    
    if "school" ∈ ns
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
        # create integer variable
        df.schoolyears = levelcode.(df.school); # questionable?
    end


    if "educated" ∈ ns
        df.educated = categorical(df.educated)
        levels!(
            df.educated, ["No", "Some", "Yes"]; allowmissing = true
        )
    end

    if "invillage" ∈ ns
        df.invillage = categorical(df.invillage; ordered = true);
        levels!(
            df.invillage, ["Less than a year", "More than a year", "Since birth"]
        );

        df.sincebirth = passmissing(ifelse).(df.invillage .== "Since birth", true, false);
    end

    if "migrateplan" ∈ ns
        df.migrateplan = categorical(df.migrateplan; ordered = true)
        levels!(
            df.migrateplan, ["No", "Inside", "Outside", "Country"];
            allowmissing = true
        )

        cpn = ["Outside", "Country"]
        df.leavecopan = passmissing(ifelse).(df.migrateplan .∈ Ref(cpn), true, false)
        df.leavecountry = passmissing(ifelse).(df.migrateplan .== "Country", true, false)
    end

    v = :indigenous
    if string(v) ∈ ns
        df[!, v] = categorical(df[!, v]);
        levels!(df[!, v], ["No", "Other", "Lenca", "Chorti"]);
    end

    ## household variables

    v = :hh_wealth_orig
    if string(v) ∈ ns
        df[!, v] = categorical(df[!, v]; ordered = true)
        levels!(df[!, v], [1,2,3,4,5])
    end

    v = :handwash
    if string(v) ∈ ns
        df[!, v] = categorical(df[!, v]; ordered = true);
        levels!(df[!, v], ["None", "No water", "Water"])
    end

    v = :watersource
    if string(v) ∈ ns        
        df[!, v] = categorical(df[!, v]; ordered = true)
        # NEED BETTER ORDER
        levels!(
            df[!, v],
            [
                "Surface water"
                "Spring (unprot.)"
                "Well with tube"
                "Dug well (unprot.)"
                "Rainwater"
                "Other"
                "Dug well (prot.)"
                "Spring (prot.)"
                "Cart with tank"
                "Bottle water"
                "Tanker truck"
            ]
        );
    end

    v = :toilettype
    if string(v) ∈ ns
        df.toilettype = categorical(df.toilettype; ordered=true);
        levels!(df.toilettype, [
            "No facility (outdoors)"
            "No facility (other location)"
            "No facility (other home/establishment)"
            "Other"
            "Bucket toilet"
            "Septic latrine"   
            "Composting toilet"
            "Flush toilet"
        ])
    end

    if "toilet" ∈ ns
        HondurasTools.irrelreplace!(df, :toilet)
        df.toilet = categorical(df.toilet; ordered = true)
        levels!(df.toilet, ["No toilet", "Shared", "Yes"])
    end

    # this probably is ordered
    if "toiletkind" ∈ ns
        HondurasTools.irrelreplace!(df, :toiletkind)
        df.toiletkind = categorical(df.toiletkind; ordered =true)
        levels!(df.toiletkind, [
            "No toilet"
            "Bucket toilet"
            "Composting toilet"
            "Septic latrine"
            "Flush toilet"
        ])
    end

    if "cooktype" ∈ ns
        df.cooktype = categorical(df.cooktype; ordered = true)
        levels!(df.cooktype, [
            "None"
            "Furnace no chimney"
            "Furnace chimney"
            "Stove"
        ])
    end

    if "cookfueltype" ∈ ns
        df.cookfueltype = categorical(df.cookfueltype; ordered = true);

        levels!(df.cookfueltype, [
            "None"
            "Wood"
            "Kerosene"
            "Gas (cylinder)"
            "Electricity"
        ])
    end

    if "windows" ∈ ns
        df.windows = categorical(df.windows);
        levels!(
            df.windows,
            ["There aren't windows", "Other", "Yes, unfinished windows", "Yes, wooden windows", "Yes, metal windows", "Yes, glass windows"
        ]);
    end

    if "walltype" ∈ ns
        df.walltype = categorical(df.walltype);
        levels!(
            df.walltype,
            ["There are no walls", "Discarded materials", "Clay/uncovered adobe/mud", "Cane/palm/trunks", "Clay bricks", "Cement blocks", "Wood (polished)", "Wood (unpolished)"]
        );
    end

    if "roofing" ∈ ns
        df.roofing = categorical(df.roofing)
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

    for v in [:community_center]
        if string(v) ∈ ns
            HondurasTools.binarize!(df, v)
        end
    end

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

    ## Perceptions: only frequency and approval items use ordered scales.
    # Boolean selections and nominal birth-decision responses are kept separate.
    freqscale = ["Never", "Rarely", "Sometimes", "Always"]
    goodness = ["Bad", "Neither", "Good"]
    frequency_vars = [
        :avoid_preg_perc, :folic_perc, :prenatal_care_perc, :homebirth_perc,
        :postnatal_care_perc, :baby_bath_perc, :baby_skin_perc, :fajero_perc,
        :chupon_perc, :laxatives_perc, :father_check_perc, :father_wait_perc,
        :father_care_sick_perc, :men_hit_perc,
    ]
    approval_vars = [
        :girl_partner_moralperc, :girl_baby_moralperc, :avoid_preg_moralperc,
        :prenatal_care_moralperc, :homebirth_moralperc, :baby_bath_moralperc,
        :baby_skin_moralperc, :chupon_moralperc, :father_check_moralperc,
        :father_wait_moralperc, :father_care_sick_moralperc, :men_hit_moralperc,
    ]
    for (vars, scale) in ((frequency_vars, freqscale), (approval_vars, goodness))
        for v in vars
            if string(v) in ns
                df[!, v] = categorical(df[!, v]; ordered=true)
                levels!(df[!, v], scale)
            end
        end
    end
    for v in [:folic_good_when, :birth_good_where, :birthdecision_perc, :birthdecision]
        if string(v) in ns
            df[!, v] = categorical(df[!, v]; ordered=false)
        end
    end
end

export code_variables!
