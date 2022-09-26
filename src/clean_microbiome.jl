# clean_mb_data.jl

function clean_microbiome(cohort1pth, cohort2pth)

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

    select!(
        mb,
        [
            :name,
            :village_code,
            :lives_in_village, :works_in_village,
            :mb_a0100,
            :mb_a0200,
            :mb_a0300,
            :mb_a0400,
            :mb_a0500a, # ethnic group
            #:mb_a0500b,
            :mb_a0500c,
            #:mb_a0500d,
            #:mb_a0500e,
            #:mb_a0500f,
            #:mb_a0500g,
            #:mb_a0500h,
            :mb_a0500i,
            :mb_a0700, # eu citizen
            :mb_ab0200, # how often leave the village
            :mb_b0100, # health
            :mb_b1700, # chronic health condition
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
            :mb_c0000
        ]
    )

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

    return mb
end
