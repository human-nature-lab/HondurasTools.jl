# variables.jl

# network names
# "health_advice_get"
# "health_advice_give"
# "provider"
# "town_leaders"
# "trust_borrow_money"
# "trust_lend_money"
# "religious_service"
# "child_over12_other_house"
# "father"
# "mother"
# "patron"

ids = (vc = :village_code, b = :building_id, n = :name)
export ids

rl = (ft = "free_time", pp = "personal_private", u = "union", a = "any");
rlmn = [rl.ft, rl.pp];

nets = (
    union = ["free_time", "personal_private", "kin"],
    core = ["free_time", "personal_private", "closest_friend"],
    kin = ["child_over12_other_house", "father", "mother", "sibling", "partner"]
)
export rl, rlmn, nets

ers = ["typei", "typeii", "hit", "corej"];
errstitle = ["Type I", "Type II", "Hit", "Correct Reject"];
ernice = ["Type I", "Type II"];

sym = [# relationships that are possibly symmetric (non-kin)
    "closest_friend",
    "free_time",
    "not_get_along",
    "partner",
    "sibling",
    "personal_private"
];

b5 = [:bfi10_extraversion, :bfi10_agreeableness, :bfi10_conscientiousness, :bfi10_neuroticism, :bfi10_openness_to_experience];

ldr = [:hlthprom, :commuityhlthvol, :communityboard, :patron, :midwife, :religlead, :council, :polorglead];

export b5, ldr

respvars = [
    :wave, :village_name, :resp_target, :complete, :data_source,
    :gender, :age, :agecat, :partnered,
    :other_alter_count, :lives_in_village, :works_in_village, # data source = 4
    :indigenous, :isindigenous,
    :school, :educated,
    :religion, :protestant,
    :relig_import, :relig_freq, :relig_attend,
    :occupation,
    :ext_occ_farm, :ext_occ_food, :ext_occ_const, :ext_occ_tourism,
    :ext_occ_trans, :ext_occ_handi, :ext_occ_fam, :ext_occ_oth,
    :wealth_w1, :wealth_w3, :wealth5_w1, :wealth5_w3, :wealth_d,
    :migrateplan, :invillage,
    :hlthprom, :commuityhlthvol, :communityboard, :council,
    :patron, :midwife, :religlead, :polorglead, :inter_village_leader,
    :health, :mentalhealth, :healthy, :mentallyhealthy,
    :foodworry, :foodlack, :foodskipadult, 
    :foodskipchild, :incomesuff, 
    :status, :survey_version,
    :moved_building, :moved_village, :new_building, :new_respondent,
    :safety, 
];

# diarrhea skipped
percvars = [
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

export respvars, percvars

ext_occs = [
    :ext_occ_farm, :ext_occ_food, :ext_occ_const, :ext_occ_tourism,
    :ext_occ_trans, :ext_occ_handi, :ext_occ_fam, :ext_occ_oth,
];

export ext_occs

relig = (
    r = :religion, p = :protestant, imp = :relig_import,
    fq = :relig_freq, at = :relig_attend
)

export relig

# village econ data
vecon = (
    stores = :stores_count, basket = :basket_of_goods, cof_inc = :coffee_income,
    prices = [:price_kerosene_bottle, :price_gasoline_gallon, :price_diesel_gallon, :price_firewood_bundle, :price_gas_cylinder] #:price_charcoal] missing?
);

export vecon
