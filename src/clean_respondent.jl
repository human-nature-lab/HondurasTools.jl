# clean_respondent_data.jl

function strip_wave!(resp, wnme, wavestring)
    for e in wnme
        rename!(resp, Symbol(e) => Symbol(split(e, wavestring)[1]))
    end
end

function addtypes!(drs)
    for (i, e) in enumerate(drs.eltypes)
        if length(e) > 1
            for ε in e
                tp = if Missing .∈ Ref(Base.uniontypes(ε))
                    drs.type[i] = ε
                    break
                end
                drs.type[i] = Union{e[1], Missing}
            end
        elseif length(e) == 1
            drs.type[i] = Union{e[1], Missing}
        end
    end
end

"""
        clean_respondent(respondent_paths, hh_pth)

Clean the respondent level data. Currently only processes the W3 data (uses prior waves to fill in selected missing values).
"""
function clean_respondent(respondent_paths, hh_path)

    # load data
    resp = [
        CSV.read(df, DataFrame; missingstring = "NA") for df in respondent_paths
    ];
    
    h3 = CSV.read(hh_path, DataFrame; missingstring = "NA");

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

    dr1 = describe(resp[1])[!, [:variable, :eltype]]
    dr2 = describe(resp[2])[!, [:variable, :eltype]]
    dr3 = describe(resp[3])[!, [:variable, :eltype]]

    drs = unique(vcat(dr1, dr2, dr3))
    nrow(drs) == length(unique(drs.variable))

    drs = combine(groupby(drs, :variable), :eltype => Ref∘unique => :eltypes);

    drs[!, :type] = Vector{Type}(undef, nrow(drs))
    addtypes!(drs)
    vardict = Dict(drs.variable .=> drs.type);
    
    # rf = DataFrame(
    #     [v => tp[] for (v,tp) in zip(drs.variable, drs.type)]...
    # );

    cnt = 0; cntj = 0;
    for rp in resp
        cnt += 1
        misvars = setdiff(drs.variable, Symbol.(names(rp)))
        for misvar in misvars
            cntj += 1
            rp[!, misvar] = Vector{vardict[misvar]}(missing, nrow(rp))
        end
    end

    rf = vcat(resp[1], resp[2], resp[3]);
    resp = nothing
        
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
        :i0200, # who should make household decisions (cat) 3 = together
        :i0300, # beat spouse justified?
        :i0400,
        :i0500,
        :i0600,
        :i0700,
    ];

    rename!(rf, :respondent_master_id => :name);
    @subset!(rf, :complete .== 1);

    # replace_withold!(resp[3], resp[2], resp[1], :date_of_birth)

    select!(rf, demos)

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
    missingize!(rf, :b0100);
    rf.b0100 = categorical(rf.b0100; ordered = true)
    recode!(rf.b0100, "Have not completed any type of school" => "None")

    levels!(
        rf.b0100,
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

    # don't convert refused, dont know -> these are meaningful here
    # unique(r3.religion)
    # missingize!(r3, :religion)
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
    missingize!(rf.invillage)
    rf.invillage = categorical(rf.invillage; ordered = true);

    levels!(
        rf.invillage,
        [
            "Less than a year",
            "More than a year",
            "Since birth"
        ]
    );

    rename!(rf, :c0100 => :health);
    missingize!(rf, :health)
    rf[!, :health] = categorical(rf[!, :health]; ordered = true);

    levels!(
        rf[!, :health],
        [
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
    rf[!, :mentalhealth] = recode(rf[!, :mentalhealth], "Dont_Know" => missing);

    levels!(
        rf[!, :mentalhealth],
        [
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
        ["Refused", "Unsafe", "A little unsafe", "Don't know", "Safe"]
    );

    rename!(rf, :d0100 => :foodworry);
    rf.foodworry = categorical(rf.foodworry);

    rename!(rf, :d0200 => :foodlack);
    rf.foodlack = categorical(rf.foodlack);

    rename!(rf, :d0300 => :foodskipadult);
    rf.foodskipadult = categorical(rf.foodskipadult);

    rename!(rf, :d0400 => :foodskipchild);
    rf.foodskipchild = categorical(rf.foodskipchild);

    rename!(rf, :d0700 => :incomesuff);
    rf.incomesuff = categorical(rf.incomesuff; ordered = true);

    recode!(
        rf.incomesuff,
        "Refused" => "Refused",
        "It is not sufficient and there are major difficulties" => "major hardship",
        "It is not sufficient and there are difficulties" => "hardship",
        "Dont_Know" => "Don't know",
        "It is sufficient, without major difficulties" => "sufficient",
        "There is enough to live on and save" => "live and save"
    );

    rename!(rf, :e0200 => :partnered);
    rf.partnered = categorical(rf.partnered);

    rename!(rf, :e0700 => :pregnant);
    rf.pregnant = categorical(rf.pregnant);

    # ignore ivars for now
    select!(rf, Not([:i0200, :i0300, :i0400, :i0500, :i0600, :i0700]));

    ### process household level
    
    ## NEED TO HANDLE W1, 2

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

    rf.building_id = categorical(rf.building_id);

    nomiss = [:gender, :date_of_birth, :building_id];
    dropmissing!(rf, nomiss)
    dropmissing!(h3, [:village_code, :building_id])

    rf = leftjoin(rf, h3, on = [:building_id, :village_code]);
    
    return rf
end
