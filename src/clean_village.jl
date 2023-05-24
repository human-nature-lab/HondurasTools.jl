# clean_village.jl

function clean_village(vdfs, waves)

    if 1 ∈ waves
        vdfs[1][!, :wave] .= 1
        rename!(vdfs[1], :village_wealth_index_w1 => :village_wealth_index)
        rename!(vdfs[1], :village_wealth_index_median_w1 => :village_wealth_index_median)
    end

    if 2 ∈ waves
        vdfs[2][!, :wave] .= 2
        rename!(vdfs[2], :village_wealth_index_w2 => :village_wealth_index)
        rename!(vdfs[2], :village_wealth_index_median_w2 => :village_wealth_index_median)
    end

    if 3 ∈ waves
        vdfs[3][!, :wave] .= 3;
        rename!(vdfs[3], :village_wealth_index_w3 => :village_wealth_index)
        rename!(vdfs[3], :village_wealth_index_median_w3 => :village_wealth_index_median)
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
