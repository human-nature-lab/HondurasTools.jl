# clean_mb_data.jl

"""
        clean_microbiome(mb1, mb2)
        
Clean the microbiome data.

ARGS
≡≡≡≡≡≡≡≡≡≡

- mb1: cohort 1 raw data
- mb2: cohort 2 raw data

"""
function clean_microbiome(mb1, mb2; nokeymiss = true)

    mb = let
        mb1[!, :cohort] .= 1;
        mb2[!, :cohort] .= 2;
        
        commonnames = intersect(names(mb1), names(mb2))
        mb = vcat(mb1[!, commonnames], mb2[!, commonnames]);
        rename!(mb, :respondent_master_id => :name)
        
        mb
    end;

    mb_desc = describe(mb);

    mb.village_code = categorical(mb.village_code)
    mb.name = categorical(mb.name)
    
    # process the risk data
    risk_vars = [
        Symbol("mb_c" * ifelse(i < 10, "0", "") * string(i) * "00") for i in 1:31
    ];

    if all(risk_vars .∈ Ref(mb_desc.variable))
        risk = select(
            mb,
            :name,
            :village_code,
            risk_vars...
        );

        risk = process_risk(risk)

        mb = leftjoin(mb, risk, on = :name)
    end
    
    if :cognitive_status ∈ mb_desc.variable
        mb.cognitive_status = categorical(mb.cognitive_status; ordered = true);
        levels!(mb.cognitive_status, ["none", "impairment", "dementia"]);
    end

    if :mb_a0100 ∈ mb_desc.variable
        mb.mb_a0100 = categorical(mb.mb_a0100)
        rename!(mb, :mb_a0100 => :whereborn)
    end
    
    if :mb_a0200 ∈ mb_desc.variable
        mb.mb_a0200 = categorical(mb.mb_a0200)
        rename!(mb, :mb_a0200 => :dept)
    end
    
    if :mb_a0300 ∈ mb_desc.variable
        rename!(mb, :mb_a0300 => :mb_municipality)
    end
    
    if :mb_a0400 ∈ mb_desc.variable
        rename!(mb, :mb_a0400 => :country)
    end

    if :mb_a0500a ∈ mb_desc.variable
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
    end

    if :mb_ab0100 ∈ mb_desc.variable
        rename!(mb, :mb_ab0100 => :spend)
        mb.spend = convertspend.(mb.spend)
    end

    if :mb_a0200 ∈ mb_desc.variable
        rename!(mb, :mb_ab0200 => :leavevillage)
    end

    if :mb_b0100 ∈ mb_desc.variable
        rename!(mb, :mb_b0100 => :mb_health)
    end

    if :mb_b1700 ∈ mb_desc.variable
        rename!(mb, :mb_b1700 => :mb_chronic)
    end
    
    if :mb_c0000 ∈ mb_desc.variable
        rename!(mb, :mb_c0000 => :getmoney)
    end

    # 19 villages that are in the study
    microbiome_villages = load_mbvillages();
    mb[!, :mbset] = mb.village_code .∈ Ref(microbiome_villages.village_code)

    if nokeymiss
        dropmissing!(mb, [:village_code, :name]);

        # drop non-unique names
        nu_names_loc = nonunique(mb[!, [:name]]);
        deleteat!(mb, nu_names_loc)
    end

    # rename to avoid conflicts with other data
    rename!(
        mb,
        :lives_in_village => :mb_lives_in_village,
        :works_in_village => :mb_works_in_village
    )

    # leftjoin!(resp, mb; on = :name)
    
    # create new variables
    
    if :cognitive_score ∈ mb_desc.variable
        mb[!, :impaired] = Vector{Union{Missing, Bool}}(missing, nrow(mb));
        for (i, e) in enumerate(mb.cognitive_score)
            if !ismissing(e)
                mb[i, :impaired] = e < 29 ? true : false
            end
        end
        mb[!, :cognitive_status] = convert(
            Vector{Union{Missing, String}}, mb.cognitive_status
        )
    end
    
    return mb
end
