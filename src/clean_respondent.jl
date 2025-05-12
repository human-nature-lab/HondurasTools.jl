# clean_respondent.jl

"""
        clean_respondent(
            resp::Vector{DataFrame};
            waves,
            nokeymiss = false,
            onlycomplete = true
        )

Clean the respondent level data. `resp` must be a vector of dataframes. Respondent data, `resp`, must be ordered by and match `waves`.

Combines and processes.

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
    onlycomplete = false,
    namedict = nothing
)

    # combine respondent data
    if isnothing(namedict)
        namedict = Dict{Symbol, Symbol}()
    end

    if 1 ∈ waves
        widx = findfirst(waves .== 1)
        nm1 = names(resp[widx])

        wnme11 = nm1[occursin.("_w1", nm1)]
        strip_wave!(resp[widx], wnme11, "_w1")
        resp[widx][!, :wave] .= 1;
    end;

    if 2 ∈ waves
        widx = findfirst(waves .== 2)
        nm2 = names(resp[widx])

        wnme21 = nm2[occursin.("_w1", nm2)]
        select!(resp[widx], Not(wnme21))

        wnme22 = nm2[occursin.("_w2", nm2)]
        strip_wave!(resp[widx], wnme22, "_w2")
        resp[widx][!, :wave] .= 2;
    end;

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
    end;

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
    end;
    
    regularizecols!(resp)

    rf = reduce(vcat, resp);

    ## cleaning

    let # correct `data_source`
        rwds1 = rf.data_source[rf.wave .== 1];
        rwds1n = replace(
            rwds1,
            1 => "Census, survey",
            2 => "Census, no survey",
            3 => "Alter"
        );
    
        rwds2 = rf.data_source[rf.wave .> 1];
        rwds2n = replace(
            rwds2,
            1 => "Census, survey",
            2 => "Census, survey",
            3 => "Census, no survey",
            4 => "Alter"
        );
    
        rf.data_source = fill("", nrow(rf));
        rf.data_source[rf.wave .== 1] .= rwds1n;
        rf.data_source[rf.wave .> 1] .= rwds2n;
    end

    rename!(rf, :respondent_master_id => :name);
    namedict[:name] = :respondent_master_id;

    @subset!(rf, :name .∉ Ref(["#NAME?", "#REF!"]));
    replace!(rf.building_id, "ideres Comunitarios" => "Lideres Comunitarios");

    rf.complete = passmissing(ifelse).(rf.complete .== 1, true, false);

    if onlycomplete
        subset!(rf, :complete => x -> x .== 1; skipmissing = true)
    end

    ## these variables should be included in any dataset
    
    for vbl in [:survey_start, :date_of_birth]
        rf[!, vbl] = passmissing(string).(rf[!, vbl])
    end

    rf.survey_start = todate_split.(rf.survey_start);
    rf.date_of_birth = trydate.(rf.date_of_birth);

    # fix gender coding
    replace!(rf.gender, "male" => "man");
    replace!(rf.gender, "female" => "woman");

    # raw data description contains variable list and types
    # used to determine which variables are included
    rf_desc = describe(rf);

    if (:survey_start ∈ rf_desc.variable) & (:date_of_birth ∈ rf_desc.variable)
        rf[!, :age] = age.(rf.survey_start, rf.date_of_birth);
    else @warn "survey start or date of birth not in the data"
    end;

    for r in eachrow(rf_desc)
        if r[:nmissing] == 0
            rf[!, r[:variable]] = disallowmissing(rf[!, r[:variable]])
        end
    end

    ov = :f0100; v = :child;
    if :f0100 ∈ rf_desc.variable
        namedict[v] = ov;
        rename!(rf, ov => v)
        
        rf[!, v] = passmissing(String).(rf[!, v]);
    end;

    numclean!(:f0200, :childcount, rf, rf_desc, namedict)

    # what grade did you complete in school?
    ov = :b0100; v = :school;
    if ov ∈ rf_desc.variable
        namedict[v] = ov;
        rename!(rf, :b0100 => v);
        
        irrelreplace!(rf, v)
        replace!(
            rf[!, v],
            "Have not completed any type of school" => "None"
        );
        
        rf[!, :educated] = copy(rf[!, v]);
        
        replace!(
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
    end;

    # belong to indigenous community
    v = :indigenous
    if :b0200 ∈ rf_desc.variable
        rename!(rf, :b0200 => v)
        namedict[v] = :b0200;
        irrelreplace!(rf, v)
        replace!(
            rf[!, v],
            "Si, Maya Chorti" => "Chorti",
            "Yes, Maya Chorti" => "Chorti", "Yes, Lenca" => "Lenca"
        )

        rf[!, :isindigenous] = copy(rf[!, v]);
        replace!(
            rf[!, v],
            "Yes, Maya Chorti" => "Yes", "Yes, Lenca" => "Yes"
        );

        replace!(rf.indigenous, "Other" => missing)
        binarize!(rf, :isindigenous)

        
        rf.notindigenous = .!(rf.isindigenous);

        v_indigenous = @chain rf begin
            groupby([:village_code])
            combine(
                nrow => :n,
                :isindigenous => sum∘skipmissing => :isindigenous_sum,
                :notindigenous => sum∘skipmissing => :notindigenous_sum,
            )
            @transform(:isindigenous_pct = :isindigenous_sum .* inv.(:isindigenous_sum + :notindigenous_sum))
            @subset :village_code .!= 0
        end;

        select!(v_indigenous, Not([:notindigenous_sum, :isindigenous_sum]))

        dropmissing!(v_indigenous, :village_code);
        leftjoin!(rf, v_indigenous, on = :village_code, matchmissing=:notequal);

        rf.maj_indigenous = rf.isindigenous_pct .>= 0.5;
    end;

    # religion
    vs = [:b0600, :b0510, :b0520, :b0530];
    nvs = [:religion, :relig_import, :relig_freq, :relig_attend];
    @assert length(vs) == length(nvs)
    for (v, nv) in zip(vs, nvs)
        if v ∈ rf_desc.variable
            rename!(rf, v => nv);
            namedict[nv] = v;
            irrelreplace!(rf, nv)
        end
    end;

    if :b0600 ∈ rf_desc.variable
        rf.protestant = passmissing(ifelse).(rf.religion .== "Protestant", true, false);
        rf.catholic = passmissing(ifelse).(rf.religion .== "Catholic", true, false);

        rf.religion_c = deepcopy(rf.religion);
        replace!(rf.religion_c, "Mormon" => missing, "Other" => missing);

        rcath = @chain rf begin
            select([:village_code, :religion_c])
            @transform(:iscatholic = :religion_c .== "Catholic")
            groupby(:village_code)
            combine(
                nrow => :n,
                :iscatholic => sum∘skipmissing => :iscatholic
            )
            @transform(:pct_catholic = :iscatholic .* inv.(:n))
            select!([:village_code, :pct_catholic])
        end
        leftjoin!(rf, rcath, on = :village_code, matchmissing = :notequal)
        # percentages
        rf.maj_catholic = rf.pct_catholic .>= 0.5;
    end

    # add cleaner religious attendance variable
    if :b0530 ∈ rf_desc.variable
        rf.relig_weekly = recode(
            rf.relig_attend,
            "Never or almost never" => "<= Monthly",
            "Once or twice a year" => "<= Monthly",
            "Once a month" => "<= Monthly",
            "Once per week" => ">= Weekly",
            "More than once per week" => ">= Weekly"
            );
        
            rf.relig_weekly = passmissing(ifelse).(
                rf.relig_weekly .== ">= Weekly", true, false
        );
    end
    
    # Do you plan to leave this village in the next 12 months (staying somewhere else for 3 months or longer)?
    v = :migrateplan
    if :b0700 ∈ rf_desc.variable
        # "Dont_Know" could be important here
        # ignore for now anyway
        rename!(rf, :b0700 => v);
        namedict[v] = :b0700;
        irrelreplace!(rf, v)

        replace!(
            rf[!, v],
            "No, no plans to leave" => "No",
            "Yes, to another village inside the department of Copan" => "Inside",
            "Yes, to another village outside of the department of Copan" => "Outside",
            "Yes, to another country" => "Country"
        );
    end;

    # How long have you lived in this village?
    strclean!(:b0800, :invillage, rf, rf_desc, namedict)
    strclean!(:b0900, :invillage_yrs, rf, rf_desc, namedict)
    
    # Generally, you would say that your health is:
    v = :health
    if :c0100 ∈ rf_desc.variable    
        rename!(rf, :c0100 => v);
        namedict[v] = :c0100;
        irrelreplace!(rf, v)
        
        replace!(rf[!, v],
        "poor" => "Poor",
        "fair" => "Fair",
        "good" => "Good",
        "very good" => "Very good",
        "Very Good" => "Very good",
        "excellent" => "Excellent")

        rf[!, :healthy] = copy(rf[!, v]);
        replace!(
            rf[!, :healthy],
            "Poor" => "No",
            "Fair" => "No",
            "Good" => "Yes",
            "Very good" => "Yes",
            "Excellent" => "Yes",
        );
        binarize!(rf, :healthy)
    end;

    # Now, thinking of your mental health, including stress, depression and emotional problems, how would you rate your overall mental health?
    v = :mentalhealth
    if :c0200 ∈ rf_desc.variable
        rename!(rf, :c0200 => :mentalhealth);
        namedict[v] = :c0200;
        irrelreplace!(rf, v)

        replace!(
            rf[!, v],
            "poor" => "Poor",
            "fair" => "Fair",
            "good" => "Good",
            "very good" => "Very good",
            "excellent" => "Excellent"
        )

        rf[!, :mentallyhealthy] = copy(rf[!, v]);
        recode!(
            rf[!, :mentallyhealthy],
            "Poor" => "No",
            "Fair" => "No",
            "Good" => "Yes",
            "Very good" => "Yes",
            "Excellent" => "Yes",
        );
        binarize!(rf, :mentallyhealthy)
    end;

    # How safe do you feel walking alone in your village at night?
    v = :safety;
    if :c1820 ∈ rf_desc.variable
        rename!(rf, :c1820 => v);
        namedict[v] = :c1820;
        irrelreplace!(rf, v)
    end;

    # food availability questions
    # what about d0500, d0600?
    # partnered
    vs = [:d0100, :d0200, :d0300, :d0400, :e0200];
    nvs = [:foodworry, :foodlack, :foodskipadult, :foodskipchild, :partnered];
    @assert length(vs) == length(nvs)
    for (v, nv) in zip(vs, nvs)
        if v ∈ rf_desc.variable
            rename!(rf, v => nv);
            namedict[nv] = v;
            irrelreplace!(rf, nv)
            binarize!(rf, nv)
        end
    end

    v = :incomesuff
    if :d0700 ∈ rf_desc.variable
        rename!(rf, :d0700 => v);
        namedict[v] = :d0700;
        irrelreplace!(rf, v);

        replace!(
            rf[!, v],
            "It is not sufficient and there are major difficulties" => "major hardship",
            "It is not sufficient and there are difficulties" => "hardship",
            "It is sufficient, without major difficulties" => "sufficient",
            "There is enough to live on and save" => "live and save"
        );
    end;

    # occupational data
    b0116s = ["b0116" * lt for lt in 'b':'i']; 
    for (a, b) in zip(b0116s, string.(ext_occs))
        if Symbol(a) ∈ rf_desc.variable
            rename!(rf, a => b)
            namedict[Symbol(b)] = Symbol(a);
            irrelreplace!(rf, b)
            # if is not missing, then it is true
            # but only collected in wave 4
            oldvals = copy(rf[!, Symbol(b)])
            rf[!, Symbol(b)] = missings(Bool, nrow(rf))
            for (i, e) in enumerate(oldvals)
                w = rf[i, :wave]
                if ismissing(e) & (w == 4)
                    rf[i, Symbol(b)] = false
                else (w == 4)
                    rf[i, Symbol(b)] = true
                end
            end
        end
    end

    v = :occupation
    if :b0111 ∈ rf_desc.variable
        rename!(rf, :b0111 => v);
        namedict[v] = :b0111;

        oldnames = [
            "Armed or police forces"
            "Employee of a service or goods sales company (for example stores, food merchant, clothing, etc.)"
            "Housework, housewife, caring for children or elderly people at home"
            "Looking for a job"
            "Merchant, business owner, boss or employer (for example clothing, food, etc.)"
            "Not working but not looking for a job/ employment"
            "Not working due to disability"
            "Other"
            "Owner of a farm"
            "Profession (for example teachers, nurses, promoters, etc.)"
            "Trades (for example construction, carpenter, craftsman, mechanic, driver, midwife, security guard, etc.)"
            "Work in the field (farmer, day laborer, etc.)"
            "Retired/ pensioned"
            "Student"
        ];

        newnames = [
            "Armed/police forces"
            "Emp. service/goods co."
            "Care work"
            "Unemp. looking"
            "Merchant/bus. owner"
            "Unemp: not looking"
            "Unemp. disabled"
            "Other"
            "Farm owner"
            "Profession"
            "Trades"
            "Work in field"
            "Retired/pensioned"
            "Student"
        ];
    
        for (oldname, newname) in zip(oldnames, newnames)
            replace!(rf[!, v], oldname => newname)
        end

        # simplified occupations
        rf.occ_simp = recode(rf.occupation,
            "Armed/police forces" => "Other",
            "Care work" => "Care work",
            "Dont_Know" => missing,
            "Emp. service/goods co." => "Other",
            "Farm owner" => "Other",
            "Merchant/bus. owner" => "Other",
            "Other" => "Other",
            "Profession" => "Other",
            "Retired/pensioned" => "Other",
            "Student" => "Other",
            "Trades" => "Other",
            "Unemp. disabled" => "Other",
            "Unemp. looking" => "Other",
            "Unemp: not looking" => "Other",
            "Work in field" => "Work in field"
        );
    end;

    # ignore i- variables
    # select!(rf, Not([:i0200, :i0300, :i0400, :i0500, :i0600, :i0700]));

    # leadership variables
    if :b1000i ∈ rf_desc.variable
        select!(rf, Not(:b1000i)) # this variable seems meaningless
    end

    ldrvars = [
        :b1000a, :b1000b, :b1000c, :b1000d, :b1000e, :b1000f, :b1000g, :b1000h
    ];
    nldrvars = [
        :hlthprom, :commuityhlthvol, :communityboard, :patron, :midwife,
        :religlead, :council, :polorglead
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
            namedict[ldict[e]] = e;
        end
    end
    
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

    # do not allow entries with missing variables on the following:
    if nokeymiss
        nomiss = [:village_code, :gender, :date_of_birth, :building_id];
        dropmissing!(rf, nomiss)
    end

    # remove irrelevant variables
    for e in [:household_id, :skip_glitch]
        if e ∈ rf_desc.variable
            select!(rf, Not(e))
        end
    end

    # others

    let
        nvs  = [:motherliveinvillage, :fatherliveinvillage];
        vs = [:a0200, :a0400];
        for (nv, v) in zip(nvs, vs)
            if v ∈ rf_desc.variable
                bstrclean!(v, nv, rf, rf_desc, namedict)
            end
        end
    end

    numclean!(:a0600, :siblings, rf, rf_desc, namedict);
    numclean!(:a0700, :brothers, rf, rf_desc, namedict)
    numclean!(:a0800, :sisters, rf, rf_desc, namedict)
    numclean!(:a0900, :siblings_over12, rf, rf_desc, namedict)
    
    bstrclean!(:a1100, :notinvillage_children_over12, rf, rf_desc, namedict)
    bstrclean!(:a1300, :married, rf, rf_desc, namedict)

    bstrclean!(:a2400, :havepatron, rf, rf_desc, namedict)
    numclean!(:a2600, :othervillage_friends_rel, rf, rf_desc, namedict)

    numclean!(:a2700, :othervillage_loc, rf, rf_desc, namedict) # village codes

    # isn't this hh level?
    bstrclean!(:b0400, :eatfromkitchen, rf, rf_desc, namedict)

    # Over the last 2 weeks, how often have you been bothered by any of the following problems? Little interest or pleasure in doing things
    
    # little pleasure
    strclean!(:c0300, :littlepleas, rf, rf_desc, namedict)
    # feeling down
    strclean!(:c0400, :downdep, rf, rf_desc, namedict)
    
    # diarrhea (other vars here ignored)
    # bstrclean!(:c0500, :diarr, rf, rf_desc, namedict)

    bstrclean!(:e0300, :livewithpart, rf, rf_desc, namedict)
    numclean!(:e0400, :livewithpart_yrs, rf, rf_desc, namedict; tpe = Float64)
    numclean!(:e0500, :partnercount, rf, rf_desc, namedict)
    numclean!(:e0600, :partnerliveage, rf, rf_desc, namedict)

    bstrclean!(:e0700, :preg_now, rf, rf_desc, namedict)
    # bstrclean!(:e0900, :preg_delayavoid, rf, rf_desc, namedict)

    # methods to delay or avoid pregnancy
    # assume false if not asnwered
    let e1000s = ["e1000" * d for d in 'a':'h']
        pmeth = ["pill", "condom", "f_condom", "preg_iud", "preg_inject_implant", "preg_rhythm", "preg_surg_steril.", "preg_other"]
        for (a, b) in zip(e1000s, string.(pmeth))
            if Symbol(a) ∈ rf_desc.variable
                rename!(rf, a => b)
                namedict[Symbol(b)] = Symbol(a);
                irrelreplace!(rf, b)
                # if is not missing, then it is true
                # but only collected in wave 4
                oldvals = copy(rf[!, Symbol(b)])
                rf[!, Symbol(b)] = missings(Bool, nrow(rf))
                for (i, e) in enumerate(oldvals)
                    w = rf[i, :wave]
                    if ismissing(e) & (w < 4)
                        rf[i, Symbol(b)] = false
                    else (w < 4)
                        rf[i, Symbol(b)] = true
                    end
                end
            end
        end
    end

    # bstrclean!(:e1100, :preg_delayavoid_now, rf, rf_desc, namedict)
    # ignore e1200 -- now version of e1000

    # at hh level
    let nosel = [:b0300, ]
        select!(rf, Not(nosel))
    end

    # irrel
    let nosel = [:b1000]
        select!(rf, Not(nosel))
    end

    # add village population
    pp = @chain rf begin
        groupby([:village_code, :wave])
        combine(nrow => :population)
        dropmissing()
    end

    leftjoin!(rf, pp, on = [:village_code, :wave], matchmissing=:notequal)

    return rf
end

export clean_respondent
