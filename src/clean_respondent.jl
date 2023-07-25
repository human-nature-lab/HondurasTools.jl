# clean_respondent.jl

protestant(x) = return if x == "Protestant"
    true
elseif x == "Catholic"
    false
else
    missing
end

"""
        clean_respondent(
            resp::Vector{DataFrame};
            waves,
            nokeymiss = false,
            onlycomplete = true
        )

Clean the respondent level data. `resp` must be a vector of dataframes. Respondent data, `resp`, must be ordered by and match `waves`.

ARGS
≡≡≡≡≡≡≡≡≡≡

- resp: a vector of DataFrames, with entries for each wave of the data.
- waves: indicate the wave of each DataFrame in the same order as resp.
- nokeymiss: if true, do not allow entries with missing values for [:village_code, :gender, :date_of_birth, :building_id]
- onlycomplete: only include completed surveys

"""
function clean_respondent(
    resp::Vector{DataFrame},
    waves;
    nokeymiss = false,
    onlycomplete = true
)

    if 1 ∈ waves
        widx = findfirst(waves .== 1)
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
        resp[widx][!, :wave] .= 2;
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
    
    regularizecols!(resp)

    rf = reduce(vcat, resp)
    resp = nothing

    rename!(rf, :respondent_master_id => :name);

    if onlycomplete
        subset!(rf, :complete => x -> x .== 1; skipmissing = true)
    end

    ## these variables should be included in any dataset
    
    for vbl in [:survey_start, :date_of_birth]
        rf[!, vbl] = passmissing(string).(rf[!, vbl])
    end

    rf.survey_start = todate_split.(rf.survey_start)
    rf.date_of_birth = trydate.(rf.date_of_birth)

    rf[!, :age] = age.(rf.survey_start, rf.date_of_birth)

    rf.village_code = categorical(rf.village_code);
    rf.building_id = categorical(rf.building_id);
    rf.gender = categorical(rf.gender);

    # fix gender coding
    replace!(rf.gender, "male" => "man")
    replace!(rf.gender, "female" => "woman")

    ##

    # raw data description contains variable list and types
    rf_desc = describe(rf);

    for r in eachrow(rf_desc)
        if r[:nmissing] == 0
            rf[!, r[:variable]] = disallowmissing(rf[!, r[:variable]])
        end
    end

    # what grade did you complete in school?
    if :b0100 ∈ rf_desc.variable
        
        # convert "Dont_Know" and "Refused" to missing
        # missingize!(rf, :b0100);
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

    # belong to indigenous community
    if :b0200 ∈ rf_desc.variable
        rename!(rf, :b0200 => :indigenous)
        rf.indigenous_simple = deepcopy(rf.indigenous)
        for (i, e) in enumerate(rf.indigenous)
            if !ismissing(e)
                if e .== "Si, Maya Chorti"
                    rf.indigenous[i] = "Yes, Maya Chorti"
                end
                if (e .== "Yes, Maya Chorti") | (e .== "Yes, Lenca") | (e .== "Other")
                    rf.indigenous_simple[i] = "Yes"
                end
            end
        end
    end

    # What is your religion?
    if :b0600 ∈ rf_desc.variable
        rename!(rf, :b0600 => :religion);
        rf.religion = categorical(string.(rf.religion));
    end

    rf.protestant = passmissing(protestant).(rf.religion)

    # Do you plan to leave this village in the next 12 months (staying somewhere else for 3 months or longer)?
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

    # How long have you lived in this village?
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
    
    # Generally, you would say that your health is:
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

    # Now, thinking of your mental health, including stress, depression and emotional problems, how would you rate your overall mental health?
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

    # How safe do you feel walking alone in your village at night?
    if :c1820 ∈ rf_desc.variable
        rename!(rf, :c1820 => :safety);
        rf.safety = categorical(rf.safety; ordered = true);
        recode!(rf.safety, "Dont_Know" => "Don't know");

        levels!(
            rf.safety,
            ["Refused", "Don't know", "Unsafe", "A little unsafe", "Safe"]
        );
    end

    # In the past 3 months, for lack of money or other resources, did you ever worry that your household would run out of food?
    if :d0100 ∈ rf_desc.variable
        rename!(rf, :d0100 => :foodworry);
        rf.foodworry = categorical(rf.foodworry; ordered = true);
        recode!(rf.foodworry, "Dont_Know" => "Don't know");
        levels!(rf.foodworry, ["Refused", "Don't know", "No", "Yes"]);
    end

    # In the past 3 months, for lack of money or other resources, did your household ever run out of food?
    if :d0200 ∈ rf_desc.variable
        rename!(rf, :d0200 => :foodlack);
        rf.foodlack = categorical(rf.foodlack; ordered = true);
        recode!(rf.foodlack, "Dont_Know" => "Don't know");
        levels!(rf.foodlack, ["Refused", "Don't know", "No", "Yes"]);
    end

    # add variable question
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


    # ignore i- variables
    # select!(rf, Not([:i0200, :i0300, :i0400, :i0500, :i0600, :i0700]));

    # do not allow entries with missing variables on the following:
    if nokeymiss
        nomiss = [:village_code, :gender, :date_of_birth, :building_id];
        dropmissing!(rf, nomiss)
    end
    
    # leadership variables
    if :b1000i ∈ rf_desc.variable
        select!(rf, Not(:b1000i)) # this variable seems meaningless
    end

    ldrvars = [
        :b1000a, :b1000b, :b1000c, :b1000d, :b1000e, :b1000f, :b1000g, :b1000h
    ];
    
    # names for leadership categories
    # these are plausibly overlapping, so do not collapse to a single categorical variable
    ldict = Dict(
        :b1000a => :hlthprom,
        :b1000b => :commuityhlthvol,
        :b1000c => :communityboard, # (village council, water board, parents association)
        :b1000d => :patron, # (other people work for you)
        :b1000e => :midwife,
        :b1000f => :religlead,
        :b1000g => :council, # President/leader of indigenous council
        :b1000h => :polorglead, # Political organizer/leader
        # :b1000i => None of the above
    );

    for e in ldrvars
        if e ∈ rf_desc.variable
            rf[!, e] = HondurasTools.replmis.(rf[!, e])
            rename!(rf, e => ldict[e]);
        end
    end

    # remove irrelevant variables
    for e in [:household_id, :skip_glitch]
        if e ∈ rf_desc.variable
            select!(rf, Not(e))
        end
    end

    # age category
    begin
        rf[!, :agecat] = fill("<= 65", nrow(rf));

        for (i, x) in enumerate(rf[!, :age])
            if !ismissing(x)
                if x > 65
                    rf[i, :agecat] = if x > 80
                        "> 80"
                    elseif x > 75
                        "> 75"
                    elseif x > 70
                        "> 70"
                    elseif x > 65
                        "> 65"
                    end
                end
            end
        end
    end

    # older-wave variables to wave4
    # (pregnant is also missing at w4 - but cannot use old values)
    if 4 ∈ waves
        updatevalues!(rf, 4, :mentallyhealthy)
        updatevalues!(rf, 4, :healthy)
        updatevalues!(rf, 4, :safety)
        updatevalues!(rf, 4, :foodworry)
        updatevalues!(rf, 4, :incomesuff)
        updatevalues!(rf, 4, :partnered)

        # not sure
        updatevalues!(rf, 4, :invillage)

        # collected, but only asked if unknown or changed
        updatevalues!(rf, 4, :school)
        updatevalues!(rf, 4, :educated)

        nldrvars = [
            :hlthprom, :commuityhlthvol, :communityboard, :patron, :midwife,
            :religlead, :council, :polorglead
        ];

        for e in nldrvars
            updatevalues!(rf, 4, e)
        end

        # add leader variable
        rf[!, :leader] = fill(false, nrow(rf))
        for c in nldrvars
            for (i, b) in enumerate(rf[!, c])
                if !ismissing(b)
                    if b
                        rf[i, :leader] = true
                    end
                end
            end
        end
    end

    return rf
end
