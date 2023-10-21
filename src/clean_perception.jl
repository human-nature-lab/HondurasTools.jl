# clean_perception.jl

function rename_perception!(resp)

    rename!(resp, :j0100 => :girl_partner_moralperc);
    rename!(resp, :i0800 => :girl_partner_good_age);

    rename!(resp, :j0200 => :girl_baby_moralperc);
    rename!(resp, :i1000 => :girl_baby_good_age);


    rename!(resp, :j0300 => :avoid_preg_perc);
    rename!(resp, :e0900 => :avoid_preg_ever, :e1100 => :avoid_preg_now);

    rename!(resp, :j0400 => :avoid_preg_moralperc);

    rename!(
        resp,
        :j0500 => :folic_perc,
        :e1400 => :folic_now,
        :e1500 => :folic_1wk,
        :i1200 => :folic_good_when
    );

    rename!(
        resp,
        :j0600 => :prenatal_care_perc,
        :f1900r01 => :prenatal_care_any,
        :f2000 => :prenatal_care_when
    )

    rename!(
        resp,
        :j0700 => :prenatal_care_moralperc, :i1300 => :prenatal_care_good_when
    );

    rename!(
        resp,
        :j0800 => :homebirth_perc,
        :f2700r01 => :wherebirth,
        :i1500 => :birth_good_where,
        :j0900 => :homebirth_moralperc,
    )

    rename!(
        resp,
        :j1000 => :birthdecision_perc, :f2800 => :birthdecision,
    )

    rename!(
        resp,
        :j1100 => :postnatal_care_perc,
        :f3600 => :postnatal_care_any,
        :f3700 => :postnatal_care_when,
        :i1900d => :postnatal_good
    );

    rename!(
        resp,
        :j1200 => :baby_bath_perc,
        :j1300 => :baby_bath_moralperc,
        :f4800p1 => :baby_bath
    );

    rename!(
        resp,
        :j1400 => :baby_skin_perc, 
        :j1500 => :baby_skin_moralperc
    );

    rename!(resp, :i1900a => :baby_skin_good)

    rename!(
        resp,
        :j1600 => :fajero_perc,
        :f5000 => :fajero,
        :i1900c => :fajero_good_1,
        :i2200g => :fajero_good_2
    );

    rename!(
        resp,
        :j1700 => :chupon_perc,
        :j1800 => :chupon_moralperc,
        :f7000 => :chupon
    );
    # i2500a-k

    rename!(
        resp,
        :j1900 => :laxatives_perc,
        :i1900b => :laxatives_good,
    );

    rename!(resp, :c0500 => :diarrhea_3wk);

    rename!(
        resp,
        :j2000a=>:diarrhea_antibiotic_perc,
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
        :c0900n=>:diarrhea_other
    );

    rename!(resp, :j2100 => :wash_perc, :i2900b => :wash_good);

    rename!(resp, :j2200 => :avoid_smoke_perc, :i2900d => :avoid_smoke);

    rename!(
        resp, :j2300 => :father_check_perc,
        :f2600 => :father_check
    )

    rename!(resp, :j2400 => :father_check_moralperc, :i3200 => :father_check_good);

    rename!(resp, :j2500 => :father_wait_perc, :f2900 => :father_wait);

    rename!(resp, :j2600 => :father_wait_moralperc, :i3300 => :father_wait_good);

    # there appears to be no direct concordance
    rename!(resp, :j2700 => :father_care_sick_perc)

    rename!(
        resp,
        :j2800 => :father_care_sick_moralperc, :i3400 => :father_care_sick_good
    );

    rename!(resp, :j2900 => :men_hit_perc);

    rename!(
        resp,
        :j3000 => :men_hit_moralperc,
        :i0300 => :men_hit_neglect_good,
        :i0400 => :men_hit_house_good,
        :i0500 => :men_hit_argue_good,
        :i0600 => :men_hit_food_good,
        :i0700 => :men_hit_sex_good
    );
end

"""
        clean_perception!(resp)

Clean the behavior/norm perception variables in the respondent data.
"""
function clean_perception!(resp)

    rename_perception!(resp)

    # responses with children
    bidx = coalesce.(resp[!, :child], false);

    let
        # If a girl younger than 18 joins with a partner, will people in the community think this is good, bad or neither?
        v = :girl_partner_moralperc
        
        # replace irrelevant values with missing
        replace!(resp[!, v], [rx => missing for rx in rms]...)
        
        # type as regular string (basically fixed by changing CSV.read)
        resp[!, v] = passmissing(String∘string).(resp[!, v]);
        
        # change to an ordered categorical variable
        resp[!, v] = categorical(resp[!, v]; ordered = true)

        # assign levels to scale
        levels!(resp[!, v], goodness)
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
        resp[!, v] = categorical(resp[!, v]; ordered = true)
        levels!(resp[!, v], goodness)

        v = :girl_baby_good_age

        replace!(resp[!, v], [rx => missing for rx in rms]...);
        resp[!, v] = passmissing(parse).(Int, resp[!, v]);

        resp[!, :girl_baby_good] = resp[!, v] .< 18;
    end

    let
        # Do people in your community use or do anything to delay or avoid pregnancies? 
        v = :avoid_preg_perc
        sort(unique(resp[!, v]))

        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(String∘string).(resp[!, v]);
        resp[!, v] = categorical(resp[!, v]; ordered = true);
        levels!(resp[!, v], freqscale);

        v1 = :avoid_preg_ever; v2 = :avoid_preg_now;

        sort(unique(resp[!, [v1, v2]]))

        for v in [v1, v2]
            replace!(resp[!, v], [rx => missing for rx in rms]...)
            resp[!, v] = passmissing(ifelse).(resp[!, v] .== "Yes", true, false)    
        end

        resp[!, :avoid_preg] = resp[!, v1] .| resp[!, v2];
    end;

    let
        # If someone decides to use or do something to delay or avoid pregnancy, would people in this commnuity think this is good, bad or neither?

        v = :avoid_preg_moralperc
        sort(unique(resp[!, v]))

        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(String∘string).(resp[!, v]);
        resp[!, v] = categorical(resp[!, v]; ordered = true);
        levels!(resp[!, v], goodness);

        # no ground, e.g., "do you think that it is good to avoid preg?"
    end;

    let
        # Do women in your community take folic acid tablets?

        v = :folic_perc
        sort(unique(resp[!, v]))

        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(String∘string).(resp[!, v]);
        resp[!, v] = categorical(resp[!, v]; ordered = true)
        levels!(resp[!, v], freqscale)

        v = :folic_good_when

        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(String∘string).(resp[!, v]);
        resp[!, v] = categorical(resp[!, v]; ordered = false)

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
        resp[!, v] = categorical(resp[!, v]; ordered = true);
        levels!(resp[!, v], freqscale);

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
        sort(unique(resp[!, v]))

        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(String∘string).(resp[!, v]);
        resp[!, v] = categorical(resp[!, v]; ordered = true);
        levels!(resp[!, v], goodness);

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
        resp[!, v] = categorical(resp[!, v]; ordered = true);
        levels!(resp[!, v], freqscale);

        # If a woman in your community gives birth at home, will people in the community think it is good, bad, or neither?
        v = :homebirth_moralperc

        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(String∘string).(resp[!, v]);
        resp[!, v] = categorical(resp[!, v]; ordered = true);
        levels!(resp[!, v], goodness);

        v = :birth_good_where

        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(String∘string).(resp[!, v]);
        resp[!, v] = categorical(resp[!, v]; ordered = false);

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
        resp[!, v] = categorical(resp[!, v]; ordered = false);

        v = :birthdecision;
        sort(unique(resp[!, v]))

        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(String∘string).(resp[!, v]);
        resp[!, v] = categorical(resp[!, v]; ordered = false);

        sunique(resp[bidx, v]) # why are there missings for the birth rows?
        sunique(resp[.!bidx, v])

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
        sort(unique(resp[!, v]))

        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(String∘string).(resp[!, v]);
        resp[!, v] = categorical(resp[!, v]; ordered = true);
        levels!(resp[!, v], freqscale);

        v = :postnatal_care_any;
        sort(unique(resp[!, v]))

        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(String∘string).(resp[!, v]);
        resp[!, v] = passmissing(ifelse).(resp[!, v] .== "Yes", true, false);

        v = :postnatal_care_when;
        sort(unique(resp[!, v]))

        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(String∘string).(resp[!, v]);
        resp[!, v] = passmissing(parse).(Int, resp[!, v]);

        resp[!, :postnatal_care] = resp[!, v] .<= 7

        # within the first seven days
        v = :postnatal_good;
        sort(unique(resp[!, v]))
        replace!(resp[!, v], [rx => missing for rx in rms]...)

        resp[!, v] = ifelse.(ismissing.(resp[!, v]), false, true);
    end;

    let
        # Do people in this community bathe their babies as soon as possible after birth? 
        v = :baby_bath_perc;
        sort(unique(resp[!, v]))

        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(String∘string).(resp[!, v]);
        resp[!, v] = categorical(resp[!, v]; ordered = true);
        levels!(resp[!, v], freqscale);

        # If a baby is not bathed as soon as possible after she/he is born, would people in this community see it as good, bad, neither?
        v = :baby_bath_moralperc;
        sort(unique(resp[!, v]))

        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(String∘string).(resp[!, v]);
        resp[!, v] = categorical(resp[!, v]; ordered = true);
        levels!(resp[!, v], goodness);

        v = :baby_bath;
        # all are in days
        # v2 = :f4800p2;
        # resp[!, v2]
        # sort(unique(resp[!, v2]))

        sunique(resp[!, v])

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
        sort(unique(resp[!, v]))

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
        sort(unique(resp[!, v]))

        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(String∘string).(resp[!, v]);
        resp[!, v] = categorical(resp[!, v]; ordered = true);
        levels!(resp[!, v], freqscale);
        
        v = :fajero_good_1;
        sort(unique(resp[!, v]))
        
        # N.B. assume that missing is "No"
        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = ifelse.(ismissing.(resp[!, v]), false, true)
        
        v = :fajero_good_2;
        sort(unique(resp[!, v]))
        
        # N.B. assume that missing is "No"
        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = ifelse.(ismissing.(resp[!, v]), false, true)
        
        resp[!, :fajero_good] = resp[!, :fajero_good_1] .| resp[!, :fajero_good_2];
    end;

    let
        # Do the people in your community give the baby chupones during the first
        # 6 months of life?
        v = :chupon_perc
        sort(unique(resp[!, v]))

        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(String∘string).(resp[!, v]);
        resp[!, v] = categorical(resp[!, v]; ordered = true);
        levels!(resp[!, v], freqscale);

        v = :chupon_moralperc
        sort(unique(resp[!, v]))

        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(String∘string).(resp[!, v]);
        resp[!, v] = categorical(resp[!, v]; ordered = true);
        levels!(resp[!, v], goodness);

        v = :chupon
        sort(unique(resp[!, v]))

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
        sort(unique(resp[!, v]))
        sort(unique(resp[!, v2]))

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
        resp[!, v] = categorical(resp[!, v]; ordered = true);
        levels!(resp[!, v], freqscale);

        v = :father_check
        replace!(resp[!, v], [rx => missing for rx in rms]...);

        resp[!, v] = passmissing(ifelse).(resp[!, v] .== "Yes", true, false);

        # If a father in your community does not attend pregnancy check-ups with his wife/partner people in the community think it is good, bad or neither? 

        v = :father_check_moralperc
        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(String∘string).(resp[!, v]);
        resp[!, v] = categorical(resp[!, v]; ordered = true);
        levels!(resp[!, v], goodness);

        v = :father_check_good
        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(ifelse).(resp[!, v] .== "Yes", true, false);
    end;

    let
        # Do fathers in your community wait around the place of the birth while their wives/partners are in labor and giving birth?
        v = :father_wait_perc
        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(String∘string).(resp[!, v]);
        resp[!, v] = categorical(resp[!, v]; ordered = true);
        levels!(resp[!, v], freqscale);

        v = :father_wait
        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(ifelse).(resp[!, v] .== "Yes", true, false);

        # If a father in your community does not wait around while his wife/partner is in labor and giving birth, will people in the community think it is good bad or neither?
        v = :father_wait_moralperc
        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(String∘string).(resp[!, v]);
        resp[!, v] = categorical(resp[!, v]; ordered = true);
        levels!(resp[!, v], goodness);

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
        resp[!, v] = categorical(resp[!, v]; ordered = true);
        levels!(resp[!, v], freqscale);

        # If a father in your community does not help care for his sick children, will people in the community think it is good bad or neither?
        v = :father_care_sick_good
        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(ifelse).(resp[!, v] .== "Yes", true, false);

        sunique(resp[!, v])
    end;

    let
        # Do men in this community hit their wives/partners?
        v = :men_hit_perc
        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(String∘string).(resp[!, v]);
        resp[!, v] = categorical(resp[!, v]; ordered = true);
        levels!(resp[!, v], freqscale);

        # If a man in this community hits his wife/partner, will people in the community think it is good bad or neither?
        v = :men_hit_moralperc
        replace!(resp[!, v], [rx => missing for rx in rms]...)
        resp[!, v] = passmissing(String∘string).(resp[!, v]);
        resp[!, v] = categorical(resp[!, v]; ordered = true);
        levels!(resp[!, v], goodness);

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

    # update variables: this will basically copy wave 3 values to wave 4
    # most of these were not likely collected in wave 4
    let wx = 4
        # update perception variables
        for pvar in pvars
            updatevalues!(resp, wx, pvar)
        end
    end
end
