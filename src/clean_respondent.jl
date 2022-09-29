# clean_respondent_data.jl

function regularizecols!(resp)
    dr1 = describe(resp[1])[!, [:variable, :eltype]]
    dr2 = describe(resp[2])[!, [:variable, :eltype]]
    dr3 = describe(resp[3])[!, [:variable, :eltype]]

    drs = unique(vcat(dr1, dr2, dr3))

    drs = combine(groupby(drs, :variable), :eltype => Ref∘unique => :eltypes);

    drs[!, :type] = Vector{Type}(undef, nrow(drs))
    addtypes!(drs)
    vardict = Dict(drs.variable .=> drs.type);

    for rp in resp
        misvars = setdiff(drs.variable, Symbol.(names(rp)))
        for misvar in misvars
            rp[!, misvar] = Vector{vardict[misvar]}(missing, nrow(rp))
        end
    end
    return
end

"""
        clean_respondent(
            respondent_paths; nokeymiss = false, selected = :standard
        )

Clean the respondent level data. Currently only processes the W3 data (uses prior waves to fill in selected missing values).
"""
function clean_respondent(
    respondent_paths; nokeymiss = false, selected = :standard
)

    # load data
    resp = [
        CSV.read(df, DataFrame; missingstring = "NA") for df in respondent_paths
    ];
    
    nm1 = names(resp[1])
    nm2 = names(resp[2])
    nm3 = names(resp[3])
    
    wnme11 = nm1[occursin.("_w1", nm1)]
    strip_wave!(resp[1], wnme11, "_w1")

    resp[1][!, :wave] .= 1;

    wnme21 = nm2[occursin.("_w1", nm2)]
    select!(resp[2], Not(wnme21))

    wnme22 = nm2[occursin.("_w2", nm2)]
    strip_wave!(resp[2], wnme22, "_w2")

    resp[2][!, :wave] .= 2;

    wnme31 = nm3[occursin.("_w1", nm3)]
    select!(resp[3], Not(wnme31))

    wnme32 = nm3[occursin.("_w2", nm3)]
    select!(resp[3], Not(wnme32))

    wnme33 = nm3[occursin.("_w3", nm3)]
    strip_wave!(resp[3], wnme33, "_w3")

    resp[3][!, :wave] .= 3;

    # rf = DataFrame(
    #     [v => tp[] for (v,tp) in zip(drs.variable, drs.type)]...
    # );

    regularizecols!(resp)

    rf = vcat(resp[1], resp[2], resp[3]);
    resp = nothing

    rename!(rf, :respondent_master_id => :name);
    @subset!(rf, :complete .== 1);

    rf.survey_start = [
        Dates.Date(split(rf.survey_start[i], " ")[1]) for i in 1:nrow(rf)
    ];

    rf.village_code = categorical(rf.village_code);
    rename!(rf, :b0600 => :religion);
    
    rf.religion = categorical(rf.religion);
    rf.gender = categorical(rf.gender);

    rf_desc = describe(rf);

    for r in eachrow(rf_desc)
        if r[:nmissing] == 0
            rf[!, r[:variable]] = disallowmissing(rf[!, r[:variable]])
        end
    end

    # calculate age in yrs from survey date and date of birth
    rf[!, :age] = [
        ismissing(x) ? missing : Int(round(Dates.value(x)*inv(365); digits=0)) for x in (rf.survey_start - rf.date_of_birth)
    ];

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

    rf.religion = categorical(rf.religion);

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

    rename!(rf, :c0200 => :mentalhealth);
    rf[!, :mentalhealth] = categorical(rf[!, :mentalhealth]; ordered = true);
    rf[!, :mentalhealth] = recode(rf[!, :mentalhealth], "Dont_Know" => "Don't know");

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

    rename!(rf, :c1820 => :safety);
    rf.safety = categorical(rf.safety; ordered = true);
    recode!(rf.safety, "Dont_Know" => "Don't know");

    levels!(
        rf.safety,
        ["Refused", "Don't know", "Unsafe", "A little unsafe", "Safe"]
    );

    rename!(rf, :d0100 => :foodworry);
    rf.foodworry = categorical(rf.foodworry; ordered = true);
    recode!(rf.foodworry, "Dont_Know" => "Don't know");
    levels!(rf.foodworry, ["Refused", "Don't know", "No", "Yes"]);

    rename!(rf, :d0200 => :foodlack);
    rf.foodlack = categorical(rf.foodlack; ordered = true);
    recode!(rf.foodlack, "Dont_Know" => "Don't know");
    levels!(rf.foodlack, ["Refused", "Don't know", "No", "Yes"]);

    rename!(rf, :d0300 => :foodskipadult);
    rf.foodskipadult = categorical(rf.foodskipadult; ordered = true);
    recode!(rf.foodskipadult, "Dont_Know" => "Don't know");
    levels!(rf.foodskipadult, ["Refused", "Don't know", "No", "Yes"]);

    rename!(rf, :d0400 => :foodskipchild);
    rf.foodskipchild = categorical(rf.foodskipchild; ordered = true);
    recode!(rf.foodskipchild, "Dont_Know" => "Don't know");
    levels!(rf.foodskipchild, ["Refused", "Don't know", "No", "Yes"]);

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

    rename!(rf, :e0200 => :partnered);
    rf.partnered = categorical(rf.partnered; ordered = true);
    recode!(rf.partnered, "Dont_Know" => "Don't know");
    levels!(rf.partnered, ["Refused", "Don't know", "No", "Yes"]);

    rename!(rf, :e0700 => :pregnant);
    rf.pregnant = categorical(rf.pregnant; ordered = true);
    recode!(rf.pregnant, "Dont_Know" => "Don't know");
    levels!(rf.pregnant, ["Refused", "Don't know", "No", "Yes"]);

    # ignore ivars for now
    # select!(rf, Not([:i0200, :i0300, :i0400, :i0500, :i0600, :i0700]));

    rf.building_id = categorical(rf.building_id);

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
    elseif !isnothing(selected)
        select!(rf, selected)
    end

    return rf
end
