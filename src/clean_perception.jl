# clean_perception.jl

function renametrack!(df, namedict, rns)
    rename!(df, rns...)
    for (a,b) in rns
        namedict[b] = a
    end
end

function rename_perception!(resp, namedict)

    renametrack!(resp, namedict, [:j0100 => :girl_partner_moralperc]);
    renametrack!(resp, namedict, [:i0800 => :girl_partner_good_age]);

    renametrack!(resp, namedict, [:j0200 => :girl_baby_moralperc]);
    renametrack!(resp, namedict, [:i1000 => :girl_baby_good_age]);


    renametrack!(resp, namedict, [:j0300 => :avoid_preg_perc]);
    renametrack!(resp, namedict, [:e0900 => :avoid_preg_ever, :e1100 => :avoid_preg_now]);

    renametrack!(resp, namedict, [:j0400 => :avoid_preg_moralperc]);

    renametrack!(
        resp, namedict,
        [:j0500 => :folic_perc,
        :e1400 => :folic_now,
        :e1500 => :folic_1wk,
        :i1200 => :folic_good_when]
    );

    renametrack!(
        resp, namedict,
        [:j0600 => :prenatal_care_perc,
        :f1900r01 => :prenatal_care_any,
        :f2000 => :prenatal_care_when]
    )

    renametrack!(
        resp, namedict,
        [:j0700 => :prenatal_care_moralperc, :i1300 => :prenatal_care_good_when]
    );

    renametrack!(
        resp, namedict,
        [:j0800 => :homebirth_perc,
        :f2700r01 => :wherebirth,
        :i1500 => :birth_good_where,
        :j0900 => :homebirth_moralperc]
    )

    renametrack!(
        resp, namedict,
        [:j1000 => :birthdecision_perc, :f2800 => :birthdecision]
    )

    renametrack!(
        resp, namedict,
        [:j1100 => :postnatal_care_perc,
        :f3600 => :postnatal_care_any,
        :f3700 => :postnatal_care_when,
        :i1900d => :postnatal_good]
    );

    renametrack!(
        resp, namedict,
        [:j1200 => :baby_bath_perc,
        :j1300 => :baby_bath_moralperc,
        :f4800p1 => :baby_bath]
    );

    renametrack!(
        resp, namedict,
        [:j1400 => :baby_skin_perc, 
        :j1500 => :baby_skin_moralperc]
    );

    renametrack!(resp, namedict, [:i1900a => :baby_skin_good])

    renametrack!(
        resp, namedict,
        [:j1600 => :fajero_perc,
        :f5000 => :fajero,
        :i1900c => :fajero_good_1,
        :i2200g => :fajero_good_2]
    );

    renametrack!(
        resp, namedict,
        [:j1700 => :chupon_perc,
        :j1800 => :chupon_moralperc,
        :f7000 => :chupon]
    );
    # i2500a-k

    renametrack!(
        resp, namedict,
        [:j1900 => :laxatives_perc,
        :i1900b => :laxatives_good]
    );

    renametrack!(resp, namedict, [:c0500 => :diarrhea_3wk]);

    renametrack!(
        resp, namedict,
        [:j2000a=>:diarrhea_antibiotic_perc,
        :j2000b=>:diarrhea_zinc_perc,
        :j2000c=>:diarrhea_specialfluid_perc,
        :j2000d=>:diarrhea_antidiarrhea_perc,
        :j2000e=>:diarrhea_laxative_perc,
        :j2000f=>:diarrhea_deworm_perc,
        :j2000g=>:diarrhea_homeremedy_perc,
        :j2000h=>:diarrhea_chupon_perc,
        :j2000i=>:diarrhea_massage_perc,
        :j2000j=>:diarrhea_stopfood_perc,
        :j2000k=>:diarrhea_stopliquid_perc,
        :j2000l=>:diarrhea_extrafood_perc,
        :j2000m=>:diarrhea_extraliquid_perc,
        :j2000n=>:diarrhea_govtfluid_perc,
        :j2000o=>:diarrhea_comliquid_perc,
        :j2000r=>:diarrhea_other_perc,
        :c0900b=>:diarrhea_antibiotic,
        :c0900c=>:diarrhea_zinc,
        :c0700a=>:diarrhea_specialfluid,
        :c0900d=>:diarrhea_antidiarrhea,
        :c0900f=>:diarrhea_laxative,
        :c0900g=>:diarrhea_deworm,
        :c0900e=>:diarrhea_homeremedy,
        :c0900h=>:diarrhea_chupon,
        :c0900i=>:diarrhea_massage,
        :c0900j=>:diarrhea_stopfood,
        :c0900k=>:diarrhea_stopliquid,
        # :c0900l=>:diarrhea_extrafood, MISSING
        :c0900m=>:diarrhea_extraliquid,
        :c0700b=>:diarrhea_govtfluid,
        :c0700c=>:diarrhea_comliquid,
        :c0900n=>:diarrhea_other]
    );

    renametrack!(resp, namedict, [:j2100 => :wash_perc, :i2900b => :wash_good]);

    renametrack!(resp, namedict, [:j2200 => :avoid_smoke_perc, :i2900d => :avoid_smoke]);

    renametrack!(
        resp, namedict, [:j2300 => :father_check_perc, :f2600 => :father_check]
    )

    renametrack!(resp, namedict, [:j2400 => :father_check_moralperc, :i3200 => :father_check_good]);

    renametrack!(resp, namedict, [:j2500 => :father_wait_perc, :f2900 => :father_wait]);

    renametrack!(resp, namedict, [:j2600 => :father_wait_moralperc, :i3300 => :father_wait_good]);

    # there appears to be no direct concordance
    renametrack!(resp, namedict, [:j2700 => :father_care_sick_perc])

    renametrack!(
        resp, namedict,
        [:j2800 => :father_care_sick_moralperc, :i3400 => :father_care_sick_good]
    );

    renametrack!(resp, namedict, [:j2900 => :men_hit_perc]);

    renametrack!(
        resp, namedict,
        [:j3000 => :men_hit_moralperc,
        :i0300 => :men_hit_neglect_good,
        :i0400 => :men_hit_house_good,
        :i0500 => :men_hit_argue_good,
        :i0600 => :men_hit_food_good,
        :i0700 => :men_hit_sex_good]
    );
end

"""
        clean_perception!(resp)

Clean the behavior/norm perception variables in the respondent data.
"""
function clean_perception!(resp; namedict = nothing)

    if isnothing(namedict)
        namedict = Dict{Symbol, Symbol}()
    end

    rename_perception!(resp, namedict)

    # responses with children
    ch = resp[!, :child]
    ch = passmissing(ifelse).(ch .== "Yes", true, false)
    bidx = coalesce.(ch, false);

    let
        # If a girl younger than 18 joins with a partner, will people in the community think this is good, bad or neither?
        v = :girl_partner_moralperc
        
        # replace irrelevant values with missing
        replace!(resp[!, v], [rx => missing for rx in rms]...)
        
        # type as regular string (basically fixed by changing CSV.read)
        resp[!, v] = passmissing(String∘string).(resp[!, v]);

    end;

    let
        v = :girl_partner_good_age
        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(parse).(Int, resp[!, v]);

        resp[!, :girl_partner_good] = resp[!, v] .< 18;
    end;

    let
        # If a girl younger than 18 has a baby, will people in the community think this is good, bad or neither?
        v = :girl_baby_moralperc

        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(String∘string).(resp[!, v]);

        v = :girl_baby_good_age

        replace!(resp[!, v], [rx => missing for rx in rms]...);
        resp[!, v] = passmissing(parse).(Int, resp[!, v]);

        resp[!, :girl_baby_good] = resp[!, v] .< 18;
    end

    let
        # Do people in your community use or do anything to delay or avoid pregnancies? 
        v = :avoid_preg_perc

        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(String∘string).(resp[!, v]);

        v1 = :avoid_preg_ever; v2 = :avoid_preg_now;

        for v in [v1, v2]
            replace!(resp[!, v], [rx => missing for rx in rms]...)
            resp[!, v] = passmissing(ifelse).(resp[!, v] .== "Yes", true, false)    
        end

        resp[!, :avoid_preg] = resp[!, v1] .| resp[!, v2];
    end;

    let
        # If someone decides to use or do something to delay or avoid pregnancy, would people in this commnuity think this is good, bad or neither?

        v = :avoid_preg_moralperc

        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(String∘string).(resp[!, v]);

        # no ground, e.g., "do you think that it is good to avoid preg?"
    end;

    let
        # Do women in your community take folic acid tablets?

        v = :folic_perc

        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(String∘string).(resp[!, v]);

        v = :folic_good_when

        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(String∘string).(resp[!, v]);

        # good under at least some circumstance
        resp[!, :folic_good] = passmissing(ifelse).(resp[!, v] .== "Never", false, true);

        v1 = :folic_now; v2 = :folic_1wk

        for v in [v1, v2]
            replace!(resp[!, v], [rx => missing for rx in rms]...)
        end

        resp[!, v1] = passmissing(ifelse).(resp[!, v1] .== "Yes", true, false)    
        resp[!, v2] = passmissing(parse).(Int, resp[!, v2]);

        resp[!, :folic] = resp[!, v1] .| (resp[!, v2] .> 0);
    end;

    let
        # Do women in your community receive pregnancy care within the first 12 weeks of the pregnancy?

        # V1 MISSING?
        # :f1900 => :prenatal_care_seek_this

        v = :prenatal_care_perc

        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(String∘string).(resp[!, v]);

        v2 = :prenatal_care_when

        replace!(resp[!, v2], [rx => missing for rx in rms]...)
        resp[!, v2] = passmissing(parse).(Int, resp[!, v2]);

        resp[!, :prenatal_care] = resp[!, v2] .<= 3;
        
        v = :prenatal_care_any
        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(ifelse).(resp[!, v] .== "Yes", true, false);

        # resp[!, :prenatal_care_any] = .!ismissing.(resp[!, v2]);
    end

    let
        # If a woman in your community does not receive pregnancy care within the first 12 weeks of pregnancy, will people in the community think it is good, bad,  or neither?

        v = :prenatal_care_moralperc

        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(String∘string).(resp[!, v]);

        v = :prenatal_care_good_when
        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(parse).(Int, resp[!, v]);
        resp[!, :prenatal_care_good] = resp[!, v] .<= 3;
        resp[!, :prenatal_care_good_any] = .!ismissing.(resp[!, v]);
    end

    let
        # Do the women in your community give birth at home?
        v = :homebirth_perc;

        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(String∘string).(resp[!, v]);

        # If a woman in your community gives birth at home, will people in the community think it is good, bad, or neither?
        v = :homebirth_moralperc

        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(String∘string).(resp[!, v]);

        v = :birth_good_where

        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(String∘string).(resp[!, v]);

        v = :wherebirth
        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, :homebirth] = passmissing(ifelse).(resp[!, v] .== "At home/someone else's home", true, false);
        
        v = :birth_good_where
        
        resp[!, :homebirth_good] = passmissing(ifelse).(resp[!, v] .== "At home", true, false);
    end;

    let
        v = :birthdecision_perc;

        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(String∘string).(resp[!, v]);

        v = :birthdecision;

        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(String∘string).(resp[!, v]);

        pidx = resp[!, :birthdecision] .== "Partner";
        pidx = coalesce.(pidx, false);
        resp[pidx, :birthdecision] .= ifelse.(
            resp[pidx, :gender] .== "man",
            "Wife/companion", "Husband/companion"
        );

        pidx = resp[!, :birthdecision] .== "Respondent";
        pidx = coalesce.(pidx, false);
        resp[pidx, :birthdecision] .= ifelse.(
            resp[pidx, :gender] .== "woman",
            "Wife/companion", "Husband/companion"
        );

        # decision
        birthdec_dict = Dict(
            "Respondent and partner jointly" => "Husband wife/companions together",
            # "Respondent", # infer based on gender
            # "Partner", # infer based on gender
            "Other" => "Other",
            "Respondent's mother in law" => "Other",
            "Respondent's mother" => "Other",
            "Midwife" => "Midwife",
            "Doctor" => "Healthcare personnel "
        );

        # decision perception
        # "Husband wife/companions together"
        # "Husband/companion"
        # "Wife/companion"
        # "Healthcare personnel "
        # "Other"
        # "Midwife"

        for (i, e) in enumerate(resp[!, :birthdecision])
            if !ismissing(e)
                resp[i, :birthdecision] = get(birthdec_dict, e, e)
            end
        end
    end;

    let
        # Do women in this community have their health checked at any time during the 7 days following the birth of their baby?
        v = :postnatal_care_perc;

        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(String∘string).(resp[!, v]);

        v = :postnatal_care_any;

        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(String∘string).(resp[!, v]);
        resp[!, v] = passmissing(ifelse).(resp[!, v] .== "Yes", true, false);

        v = :postnatal_care_when;
        

        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(String∘string).(resp[!, v]);
        resp[!, v] = passmissing(parse).(Int, resp[!, v]);

        resp[!, :postnatal_care] = resp[!, v] .<= 7

        # within the first seven days
        v = :postnatal_good;
        
        replace!(resp[!, v], [rx => missing for rx in rms]...)

        resp[!, v] = ifelse.(ismissing.(resp[!, v]), false, true);
    end;

    let
        # Do people in this community bathe their babies as soon as possible after birth? 
        v = :baby_bath_perc;

        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(String∘string).(resp[!, v]);

        # If a baby is not bathed as soon as possible after she/he is born, would people in this community see it as good, bad, neither?
        v = :baby_bath_moralperc;

        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(String∘string).(resp[!, v]);

        v = :baby_bath;
        # all are in days
        # v2 = :f4800p2;
        # resp[!, v2]
        # sort(unique(resp[!, v2]))

        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(String∘string).(resp[!, v]);
        resp[!, v] = passmissing(parse).(Float64, resp[!, v]);

        resp[!, :baby_bath_1dy] = resp[!, v] .< 1
    end;

    let
        # Do people in this community hold their babies skin to skin during their first month of life?

        f5100_vrs = Symbol.("f5100" .* string.(collect('a':'i')))
        mt = Matrix(resp[!, f5100_vrs]); # a-i
        mt = [mt[r, :] for r in 1:size(mt, 1)]
        mt = [(unique∘collect∘skipmissing)(m) for m in mt]

        # there are cases where more than one option was selected
        # unique(length.(mt))
        # unique(mt)

        resp[!, :baby_skin] = missings(Bool, nrow(resp));
        for (i, x) in enumerate(mt)
            resp[i, :baby_skin] = if length(x) == 0
                missing
            elseif (length(x) == 1) & (x[1] == "No")
                false
            else true
            end
        end

        v = :baby_skin_good;
        

        # N.B. assume that missing is "No"
        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = ifelse.(ismissing.(resp[!, v]), false, true)
    end;

    let
        # Do people in this community wrap fajeros or ombligueros around their newborn babies?
        v = :fajero

        replace!(resp[!, v], [rx => missing for rx in rms]...);
        resp[!, v] = passmissing(ifelse).(resp[!, v] .== "Yes", true, false);

        v = :fajero_perc;

        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(String∘string).(resp[!, v]);
        
        v = :fajero_good_1;
        
        
        # N.B. assume that missing is "No"
        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = ifelse.(ismissing.(resp[!, v]), false, true)
        
        v = :fajero_good_2;
        
        
        # N.B. assume that missing is "No"
        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = ifelse.(ismissing.(resp[!, v]), false, true)
        
        resp[!, :fajero_good] = resp[!, :fajero_good_1] .| resp[!, :fajero_good_2];
    end;

    let
        # Do the people in your community give the baby chupones during the first
        # 6 months of life?
        v = :chupon_perc

        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(String∘string).(resp[!, v]);

        v = :chupon_moralperc
        

        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(String∘string).(resp[!, v]);

        v = :chupon
        

        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(String∘string).(resp[!, v]);
        resp[!, v] = passmissing(ifelse).(resp[!, v] .== "Yes", true, false);

        i2500_vrs = Symbol.("i2500" .* string.(collect('a':'k')))
        mt = Matrix(resp[!, i2500_vrs]); # a-k
        mt = [mt[r, :] for r in 1:size(mt, 1)]
        mt = [(unique∘collect∘skipmissing)(m) for m in mt]

        # there are cases where more than one option was selected
        # unique(length.(mt))
        # unique(mt)

        # this could be turned into levels based on knowledge of the chupon
        # right now, it is "good in any case"
        resp[!, :chupon_good] = missings(Bool, nrow(resp));
        for (i, x) in enumerate(mt)
            resp[i, :chupon_good] = if length(x) == 0
                missing
            elseif (length(x) == 1) & (x[1] == "Never")
                false
            else true
            end
        end
    end;

    let
        # Do people in your community use purgantes to newborn babies soon after they are born? 

        v = :f6000m
        v2 = :f5900

        replace!(@views(resp[bidx, v]), missing => "No", "Laxative" => "Yes");
        resp[!, v] = passmissing(ifelse).(resp[!, v] .== "Yes", true, false);

        # need to check who this was asked to
        # assumes missing "No"

        # seems like this question was asked to everyone?
        # but are there genuinely missing values?
        resp[!, :laxatives_good] = passmissing(String).(resp[!, :laxatives_good]);
        # resp[!, :laxatives_good] = passmissing(ifelse).(resp[!, :laxatives_good] .== "Giving a purgante", true, false);
        resp[!, :laxatives_good] = ifelse.(ismissing.(resp[!, v]), false, true)
    end

    diar = [
        :diarrhea_antibiotic
        :diarrhea_zinc
        :diarrhea_specialfluid
        :diarrhea_antidiarrhea
        :diarrhea_laxative
        :diarrhea_deworm
        :diarrhea_homeremedy
        :diarrhea_chupon
        :diarrhea_massage
        :diarrhea_stopfood
        :diarrhea_stopliquid
        # :diarrhea_extrafood
        :diarrhea_extraliquid
        :diarrhea_govtfluid
        :diarrhea_comliquid
        :diarrhea_other
    ];

    diar_perc = [Symbol(string(x) * "_perc") for x in diar];

    let
        # What do people in this community take or do to treat diarrhea, whether its in a child or adult? DO NOT READ RESPONSES 
        # j2000a-r

        vrs_perc = diar_perc
        vrs_do = diar

        mt = Matrix(resp[!, vrs_perc]);
        mt = [mt[r, :] for r in 1:size(mt, 1)];
        mt = [(unique∘collect∘skipmissing)(m) for m in mt];

        mt_ = Matrix(resp[!, vrs_do]);
        mt_ = [mt_[r, :] for r in 1:size(mt_, 1)];
        mt_ = [(unique∘collect∘skipmissing)(m) for m in mt_];

        
    end;

    let
        # What do people in this community take or do to treat diarrhea, whether
        # its in a child or adult? DO NOT READ RESPONSES

        v = :diarrhea_3wk;
        resp[!, v] = passmissing(String).(resp[!, v])

        yesd = resp[!, v] .== "Yes";
        yesd = coalesce.(yesd, false);

        ##

        # nothing/no variable needs special treatment
        resp[!, :diarrhea_nothing] = ifelse.(
            ismissing.(resp[!, :c0900a]) .& ismissing.(resp[!, :c0700d]), false, true
        );

        select!(resp, Not([:c0900a, :c0700d]));

        for (a, b) in zip(diar, diar_perc)
            for x in [a, b]
                replace!(resp[!, x], [rx => missing for rx in rms]...)
                replace!(@views(resp[yesd, x]), missing => "No")
                resp[!, x] = passmissing(ifelse).(resp[!, x] .== "No", false, true)
            end
        end
    end;

    let
        # Do people in this community wash their hands regularly to avoid illnesses like diarrhea and cough?
        v = :wash_perc
        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(ifelse).(resp[!, v] .== "Yes", true, false);

        v = :wash_good
        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(ifelse).(ismissing.(resp[!, v]), false, true);
    end;

    let
        # Do people in this community avoid smoke from open stoves to prevent illnesses with a cough?
        v = :avoid_smoke_perc
        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(ifelse).(resp[!, v] .== "Yes", true, false);

        v = :avoid_smoke
        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(ifelse).(ismissing.(resp[!, v]), false, true);
    end;

    let
        # Do fathers in your community attend pregnancy check-ups with their pregnant wives/companions?
        v = :father_check_perc
        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(String∘string).(resp[!, v]);

        v = :father_check
        replace!(resp[!, v], [rx => missing for rx in rms]...);

        resp[!, v] = passmissing(ifelse).(resp[!, v] .== "Yes", true, false);

        # If a father in your community does not attend pregnancy check-ups with his wife/partner people in the community think it is good, bad or neither? 

        v = :father_check_moralperc
        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(String∘string).(resp[!, v]);

        v = :father_check_good
        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(ifelse).(resp[!, v] .== "Yes", true, false);
    end;

    let
        # Do fathers in your community wait around the place of the birth while their wives/partners are in labor and giving birth?
        v = :father_wait_perc
        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(String∘string).(resp[!, v]);

        v = :father_wait
        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(ifelse).(resp[!, v] .== "Yes", true, false);

        # If a father in your community does not wait around while his wife/partner is in labor and giving birth, will people in the community think it is good bad or neither?
        v = :father_wait_moralperc
        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(String∘string).(resp[!, v]);

        v = :father_wait_good
        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(String∘string).(resp[!, v]);
        resp[!, v] = passmissing(ifelse).(resp[!, v] .== "Yes", true, false);
    end;

    let
        # Do fathers in your community help care for their sick  children?
        v = :father_care_sick_perc
        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(String∘string).(resp[!, v]);

        # If a father in your community does not help care for his sick children, will people in the community think it is good bad or neither?
        v = :father_care_sick_good
        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(ifelse).(resp[!, v] .== "Yes", true, false);

    end;

    let
        # Do men in this community hit their wives/partners?
        v = :men_hit_perc
        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(String∘string).(resp[!, v]);

        # If a man in this community hits his wife/partner, will people in the community think it is good bad or neither?
        v = :men_hit_moralperc
        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(String∘string).(resp[!, v]);

        vs = [:men_hit_neglect_good, :men_hit_house_good, :men_hit_argue_good, :men_hit_food_good, :men_hit_sex_good]

        for v in vs
            replace!(resp[!, v], [rx => missing for rx in rms]...)
            resp[!, v] = passmissing(ifelse).(resp[!, v] .== "Yes", true, false);
        end

        # if any reason exists
        resp[!, :men_hit_good] = missings(Bool, nrow(resp));

        mt = Matrix(resp[!, vs]);
        for (i, r) in enumerate(eachrow(mt))
            rx = collect(skipmissing(r))
            resp[i, :men_hit_good] = if length(rx) > 0
                any(rx)
            else
                missing
            end
        end
    end;

    # diarrhea skipped
    pvars = [
        :girl_partner_moralperc, :girl_partner_good_age,
        :girl_baby_moralperc, :girl_baby_good_age,
        :avoid_preg_perc, :avoid_preg_ever, :avoid_preg_now, :avoid_preg,
        :avoid_preg_moralperc,
        :folic_perc, :folic_now, :folic_1wk, :folic_good_when,
        :folic_good, :folic,
        :prenatal_care_perc, :prenatal_care_any, :prenatal_care_when,
        :prenatal_care_moralperc, :prenatal_care_good_when,
        :homebirth_perc, :wherebirth, :birth_good_where, :homebirth_moralperc,
        :birthdecision_perc, :birthdecision,
        :postnatal_care_perc, :postnatal_care_any, :postnatal_care_when, 
        :postnatal_good,
        :baby_bath_perc, :baby_bath_moralperc, :baby_bath,
        :baby_skin_perc, :baby_skin_moralperc, :baby_skin_good, :baby_skin,
        :fajero_perc, :fajero, :fajero_good_1, :fajero_good_2,
        :chupon_perc, :chupon_moralperc, :chupon,
        :laxatives_perc, :laxatives_good,
        :diarrhea_3wk,
        :wash_perc, :wash_good, :avoid_smoke_perc, :avoid_smoke,
        :father_check_perc, :father_check,
        :father_check_moralperc, :father_check_good,
        :father_wait_perc, :father_wait, :father_wait_moralperc, :father_wait_good,
        :father_care_sick_perc, :father_care_sick_moralperc, :father_care_sick_good,
        :men_hit_perc, :men_hit_moralperc, :men_hit_neglect_good,
        :men_hit_house_good, :men_hit_argue_good, :men_hit_food_good,
        :men_hit_sex_good,
        :men_hit_good, 
    ];
    
end

export clean_perception!
