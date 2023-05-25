# clean_village.jl

function clean_village(vdfs, waves)

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

    # these variables should not be updated
    noupdate = [
        :num_hh_census, :num_hh_survey, :ave_resp_hh, :num_resp, :ave_age, :pct_male, :pct_female, :access_to_village, :vilage_wealth_index, :village_wealth_index_median,
        :village_name, :village_code, :municipality, :office, :wave
    ];

    for e in setdiff(Symbol.(names(vdf)), noupdate)
        updatevalues!(vdf, 2, e; unit = :village_name)
        updatevalues!(vdf, 3, e; unit = :village_name)
    end

    return vdf
end
