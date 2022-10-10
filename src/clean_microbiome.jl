# clean_mb_data.jl

"""
        clean_microbiome(cohort1pth, cohort2pth; selected = :standard)
        
"""
function clean_microbiome(cohort1pth, cohort2pth; selected = :standard)

    mb = begin
        mb1, mb2 = [CSV.read(x, DataFrame; missingstring = "NA") for x in [cohort1pth, cohort2pth]]
        mb1[!, :cohort] .= 1; mb2[!, :cohort] .= 2;
        commonnames = intersect(names(mb1), names(mb2))
        # setdiff(names(mb2), names(mb1))
        mb = vcat(mb1[!, commonnames], mb2[!, commonnames]);
        rename!(mb, :respondent_master_id => :name)
    end

    # process the risk data

    risk_vars = [
        Symbol("mb_c" * ifelse(i < 10, "0", "") * string(i) * "00") for i in 1:31
    ];

    risk = select(
        mb,
        :name,
        :village_code,
        risk_vars...
    );

    risk = process_risk(risk)

    # mb data

    mb = leftjoin(mb, risk, on = :name)

    mb.village_code = categorical(mb.village_code)
    mb.name = categorical(mb.name)

    # try to find missing village codes in w3 data
    # begin
    #     codemap = Dict(r3.name .=> r3.village_code)
    #     for (i, e) in enumerate(mb.name)
    #         if ismissing(mb.village_code[i])
    #             mb.village_code[i] = get(codemap, e, missing)
    #         end
    #     end
    # end

    mb.cognitive_status = categorical(mb.cognitive_status; ordered = true);
    levels!(mb.cognitive_status, ["none", "impairment", "dementia"]);

    mb.mb_a0100 = categorical(mb.mb_a0100)
    rename!(mb, :mb_a0100 => :whereborn)
    mb.mb_a0200 = categorical(mb.mb_a0200)

    rename!(mb, :mb_a0200 => :dept)
    rename!(mb, :mb_a0300 => :mb_municipality)
    rename!(mb, :mb_a0400 => :country)

    rename!(
        mb, 
        :mb_a0500a => :eth_Lenca
        # :mb_a0500b => :eth_Miskito,
        # :mb_a0500c => :eth_Chorti_Maya_Chorti,
        # :mb_a0500d => :eth_Tolupan_Jicaque_Xicaque,
        # :mb_a0500e => :eth_Pech_Paya,
        # :mb_a0500f => :eth_Sumo_Tawahka,
        # :mb_a0500g => :eth_Garifuna,
        # :mb_a0500h => :eth_Other,
        # :mb_a0500i => :eth_None_of_the_above,
        # :mb_a0700 => :eu_citizen
    )

    rename!(mb, :mb_ab0100 => :spend)

    mb.spend = convertspend.(mb.spend)

    rename!(mb, :mb_ab0200 => :leavevillage)
    rename!(mb, :mb_b0100 => :mb_health)
    rename!(mb, :mb_b1700 => :mb_chronic)
    rename!(mb, :mb_c0000 => :getmoney)

    if selected == :standard
        select!(
        mb,
        [
            :name,
            :village_code,
            :lives_in_village,
            :works_in_village,
            :whereborn,
            :dept,
            :mb_municipality,
            :country,
            # :eth_Chorti_Maya_Chorti,
            # :eth_Tolupan_Jicaque_Xicaque,
            # :eth_Pech_Paya,
            # :eth_Sumo_Tawahka,
            # :eth_Garifuna,
            # :eth_Other,
            # :eth_None_of_the_above,
            # :eu_citizen,
            :spend,
            :leavevillage, # how often leave the village
            :mb_health,
            :mb_chronic, # chronic health condition
            :photo_naming_score, # dementia
            :photo_verbal_fluidity_score,
            :photo_recall_score,
            :cognitive_score,
            :cognitive_status,
            :bfi10_extraversion,
            :bfi10_agreeableness,
            :bfi10_conscientiousness,
            :bfi10_neuroticism,
            :bfi10_openness_to_experience,
            :getmoney,
            :risk_score,
            :green_score,
            :purple_score
        ]
    )
    elseif !isnothing(selected)
        select!(mb, selected)
    end

    return mb
end
