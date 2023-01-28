# clean_villages.jl

function clean_village(ville_paths)
    vdf1 = CSV.read(ville_paths[1], DataFrame);
    vdf2 = CSV.read(ville_paths[2], DataFrame);
    vdf3 = CSV.read(ville_paths[3], DataFrame);

    vdf1[!, :wave] .= 1
    rename!(vdf1, :village_wealth_index_w1 => :village_wealth_index)
    rename!(vdf1, :village_wealth_index_median_w1 => :village_wealth_index_median)

    vdf2[!, :wave] .= 2
    rename!(vdf2, :village_wealth_index_w2 => :village_wealth_index)
    rename!(vdf2, :village_wealth_index_median_w2 => :village_wealth_index_median)

    vdf3[!, :wave] .= 3;
    rename!(vdf3, :village_wealth_index_w3 => :village_wealth_index)
    rename!(vdf3, :village_wealth_index_median_w3 => :village_wealth_index_median)

    vdfs = [vdf1, vdf2, vdf3]

    HondurasTools.regularizecols!(vdfs)

    vdf = reduce(vcat, vdfs)

    # these variables should not be updated
    noupdate = [
        :num_hh_census, :num_hh_survey, :ave_resp_hh, :num_resp, :ave_age, :pct_male, :pct_female, :access_to_village, :vilage_wealth_index, :village_wealth_index_median,
        :village_name, :village_code, :municipality, :office, :wave
    ]

    for e in setdiff(Symbol.(names(vdf)), noupdate)
        updatevalues!(vdf, 2, e; unit = :village_name)
        updatevalues!(vdf, 3, e; unit = :village_name)
    end

    return vdf
end