# clean_village.jl

function clean_village(vdfs, waves; namedict = nothing)

    if isnothing(namedict)
        namedict = Dict{Symbol, Symbol}()
    end

    if 1 ∈ waves
        widx = findfirst(waves .== 1)

        vdfs[widx][!, :wave] .= 1
        rename!(vdfs[widx], :village_wealth_index_w1 => :village_wealth_index)
        rename!(vdfs[widx], :village_wealth_index_median_w1 => :village_wealth_index_median)
    end

    if 2 ∈ waves
        widx = findfirst(waves .== 2)

        vdfs[widx][!, :wave] .= 2
        rename!(vdfs[widx], :village_wealth_index_w2 => :village_wealth_index)
        rename!(vdfs[widx], :village_wealth_index_median_w2 => :village_wealth_index_median)
    end

    if 3 ∈ waves
        widx = findfirst(waves .== 3)

        vdfs[widx][!, :wave] .= 3;
        rename!(vdfs[widx], :village_wealth_index_w3 => :village_wealth_index)
        rename!(vdfs[widx], :village_wealth_index_median_w3 => :village_wealth_index_median)
    end

    regularizecols!(vdfs)

    vdf = reduce(vcat, vdfs)

    vdf_desc = describe(vdf)

    # recode variables as binary
    vbls = [
        :coffee_income, :coffee_cultivation, :agriculture, :livestock,
        :electricity, :potable_water, :television_service, :internet_service,
        :pool, :gas_station,
        :ngo_activity,
        :health_committee, :education_committee, :water_committee, 
        :women_committee, :management_committee, :religious_committee,
        :parent_society_committee, :school_snack_committee, :school_pto,
        :community_board, :education_development_council,
        :indigenous_org, :indigenous_org_2, :savings_group,
        :open_defecation,
        :friend_treatment, :isolation,
        :private_soccer_field, :public_soccer_field,
        :park_centrally_located, :security,


    ];

    for vbl in vbls
        if vbl ∈ vdf_desc.variable
            vdf[!, vbl] = boolvec(vdf[!, vbl])
        end
    end

    # fix typo
    if :cementary_location_village_code ∈ vdf_desc.variable
        rename!(vdf, :cementary_location_village_code => :cemetary_location_village_code);
    end

    vs = [:private_cementery, :public_cementery]
    nvs = [:private_cemetary, :public_cemetary]
    for (v, nv) in zip(vs, nvs)
        rename!(vdf, v => nv)
    end

    y = missings(Vector{Int}, nrow(vdf))
    for (i, x) in enumerate(vdf.cemetary_location_village_code)
        if !ismissing(x)
            y[i] = parse.(Int, split(x, ","))
        end
    end
    vdf.cemetary_location_village_code = y;

    rename!(vdf, :electricity => :electricity_village);
    
    # fix misc.
    if :prostestant_church ∈ vdf_desc.variable
        rename!(vdf, :prostestant_church => :protestant_church); # typo in data
    end

    dntwnt = [:ave_age, :pct_female, :num_resp, :pct_male,:village_wealth_index_median];
    select!(vdf, Not(dntwnt))

    return vdf
end
