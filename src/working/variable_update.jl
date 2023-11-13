# variable_update.j;
# update variables to wave

## update religion
function update_resp!(resp)

    nldrvars = [
        :hlthprom, :commuityhlthvol, :communityboard, :patron, :midwife,
        :religlead, :council, :polorglead
    ];

    upd = [:indigenous, :religion, :educated, :mentallyhealthy, :safety, :healthy, :foodworry, :incomesuff, :leader, nldrvars...]
    for y in upd
        for x in [2,3,4]
            updatevalues!(resp, x, y)
        end
    end
    # (pregnant is also missing at w4 - but cannot use old values)
end

function update_perc!(resp)

    # update variables: this will basically copy wave 3 values to wave 4
    # most of these were not likely collected in wave 4

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

    let wx = 4
        # update perception variables
        for pvar in pvars
            updatevalues!(resp, wx, pvar)
        end
    end
end

function update_hh!(hh)
    hh_desc = describe(hh)
    noupdate = [:building_id, :village_code, :hh_resp_name, :hh_survey_start, :data_source_hh, :hh_wealth, :wave, :hh_new_building]
    
    for x in setdiff(hh_desc.variable, noupdate)
        if x ∈ hh_desc.variable
            updatevalues!(hh, 2, x; unit = :building_id)
            updatevalues!(hh, 3, x; unit = :building_id)
            updatevalues!(hh, 4, x; unit = :building_id)
        end
    end
end

function update_vill!(vdf)
    vdf_desc = describe(vdf);
    noupdate = [
        :num_hh_census, :num_hh_survey, :ave_resp_hh, :num_resp,
        :ave_age, :pct_male, :pct_female, :access_to_village,
        :vilage_wealth_index, :village_wealth_index_median,
        :village_name, :village_code, :municipality, :office, :wave,
        :cemetary_location_village_code # does not work with function
    ];
    upd = setdiff(vdf_desc.variable, noupdate)
    
    for e in upd
        if e ∈ vdf_desc.variable
            updatevalues!(vdf, 2, e; unit = :village_code)
            updatevalues!(vdf, 3, e; unit = :village_code)
            updatevalues!(vdf, 4, e; unit = :village_code)
        end
    end
end;

export update_resp!, update_perc!, update_hh!, update_vill!
