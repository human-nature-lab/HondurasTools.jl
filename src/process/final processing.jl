## data processing info

"""
    HondurasConfig

Configuration struct for Honduras data processing pipeline.
Contains paths, constants, and tracking dictionaries needed for data processing.
"""
struct HondurasConfig
    # Basic configuration
    date_stamp::String
    waves::Vector{Int}
    base_path::String
    write_path::String
    
    # Variable tracking
    namedict::Dict{Symbol, Symbol}
    
    # Data file paths by category
    int_paths::Vector{String}
    oc_paths::Vector{String}
    hh_paths::Vector{String}
    respondent_paths::Vector{String}
    con_paths::Vector{String}
    village_paths::Vector{String}
    
    # Microbiome data paths
    mb_path::String
    cohort1_path::String
    cohort2_path::String
    
    # CSS data path
    css_path::String
end

"""
    hondurasconfig(; kwargs...)

Create a config struct with default values. Override any parameter as needed.

Note that this function is hardcoded for specific directories (change as needed).
"""
function hondurasconfig(;
    date_stamp::String = "2025-05-07",
    waves::Vector{Int} = [1, 2, 3, 4],
    base_path::String = "../",
    write_path::String = datapath,  # Assumes datapath from environment.jl
    namedict::Dict{Symbol, Symbol} = Dict{Symbol, Symbol}()
)
    # Intervention data
    int_paths = "INTERVENTION/v3/" .* [
        "honduras_intervention_household_summary_v3.csv",
        "honduras_intervention_respondent_summary_v3.csv",
        "honduras_intervention_village_summary_v3.csv"
    ]
    
    # Outcomes data
    oc_paths = [
        "WAVE1/v8_2021-03/honduras_outcomes_WAVE1_v8.csv",
        "WAVE2/v5_2021-03/honduras_outcomes_WAVE2_v5.csv",
        "WAVE3/v3_2021-03/honduras_outcomes_WAVE3_v3.csv",
        "WAVE4/v2/honduras_outcomes_WAVE4_v2.csv"
    ]
    
    # Household data
    hh_paths = [
        "WAVE1/v8_2021-03/honduras_households_WAVE1_v8.csv",
        "WAVE2/v5_2021-03/honduras_households_WAVE2_v5.csv",
        "WAVE3/v3_2021-03/honduras_households_WAVE3_v3.csv",
        "WAVE4/v2/honduras_households_WAVE4_v2.csv"
    ]
    
    # Respondent data
    respondent_paths = [
        "WAVE1/v8_2021-03/honduras_respondents_WAVE1_v8.csv",
        "WAVE2/v5_2021-03/honduras_respondents_WAVE2_v5.csv",
        "WAVE3/v3_2021-03/honduras_respondents_WAVE3_v3.csv",
        "WAVE4/v2/honduras_respondents_WAVE4_v2.csv"
    ]
    
    # Connection data
    con_paths = [
        "WAVE1/v8_2021-03/honduras_connections_WAVE1_v8.csv",
        "WAVE2/v5_2021-03/honduras_connections_WAVE2_v5.csv",
        "WAVE3/v3_2021-03/honduras_connections_WAVE3_v3.csv",
        "WAVE4/v2/honduras_connections_WAVE4_v2.csv"
    ]
    
    # Village data
    village_paths = [
        "WAVE1/v8_2021-03/honduras_villages_WAVE1_v8.csv",
        "WAVE2/v5_2021-03/honduras_villages_WAVE2_v5.csv",
        "WAVE3/v3_2021-03/honduras_villages_WAVE3_v3.csv"
    ]
    
    # Microbiome data
    mb_path = "/WORKAREA/work/HONDURAS_MICROBIOME/E_FELTHAM/"
    cohort1_path = "COHORT_1/v1/hmb_respondents_cohort1_baseline_v1_E_FELTHAM_2022-09-08.csv"
    cohort2_path = "COHORT_2/v1/hmb_respondents_cohort2_v1_E_FELTHAM_2022-09-08.csv"
    
    # CSS data
    css_path = "CSS/final_data/v1/css_edges_v1.csv"
    
    return HondurasConfig(
        date_stamp,
        waves,
        base_path,
        write_path,
        namedict,
        int_paths,
        oc_paths,
        hh_paths,
        respondent_paths,
        con_paths,
        village_paths,
        mb_path,
        cohort1_path,
        cohort2_path,
        css_path
    )
end

"""
    get_full_path(config::HondurasConfig, path_type::Symbol)

Get absolute paths for the requested path type.
"""
function get_full_path(config::HondurasConfig, path_type::Symbol)
    if path_type == :intervention
        return config.base_path .* config.int_paths
    elseif path_type == :outcomes
        return config.base_path .* config.oc_paths
    elseif path_type == :household
        return config.base_path .* config.hh_paths
    elseif path_type == :respondent
        return config.base_path .* config.respondent_paths
    elseif path_type == :connection
        return config.base_path .* config.con_paths
    elseif path_type == :village
        return config.base_path .* config.village_paths
    elseif path_type == :microbiome_cohort1
        return config.mb_path * config.cohort1_path
    elseif path_type == :microbiome_cohort2
        return config.mb_path * config.cohort2_path
    elseif path_type == :css
        return config.base_path * config.css_path
    else
        throw(ArgumentError("Invalid path_type: $path_type"))
    end
end

## Process Respondent Data

# ==========================================================

"""
process_respondent_data()

Load, clean, and process respondent data across all waves.
Returns processed data structures for further analysis.
"""
function process_respondent_data(hc)
println("Processing respondent data...")

    # Load respondent data for all waves
    resps = [
        CSV.read(hc.base_path * x, DataFrame; missingstring="NA") 
        for x in hc.respondent_paths
    ]
    
    # Fix W4 village code issue - villages have names instead of codes
    #=
    this uses villages names in w4 instead of codes.
    better to just drop it for now, and assume that it is the same
    (since we have the names in the village data already)
    =#
    resps[4].a2700 .= missing
    
    # Clean and standardize respondent data
    resp = clean_respondent(
        resps, hc.waves;
        nokeymiss=false,
        onlycomplete=false,
        namedict=hc.namedict
    )
    
    # Process perception data embedded in respondent dataset
    clean_perception!(resp; namedict=hc.namedict)
    
    # Free memory
    resps = nothing
    
    # Fix birth date for specific respondent with ID issue
    fix_birth_date!(resp, "Obit-245df0ae-8e2b-4672-bdd1-67970c794271")
    
    # Select relevant variables for processing
    vs = intersect(unique(vcat(respvars, percvars)), Symbol.(names(resp)))
    
    # Create respondent data structure
    rd = respprocess(
        resp, vs;
        unit=:name,
        ids=ids, 
        respvars=respvars, 
        percvars=percvars
    )
    
    # Process wave 4 respondent data
    r4 = create_wave4_respondent_data(rd)
    
    # Code categorical variables
    code_variables!(r4)
    
    # Create indigenous status variable
    r4.isindigenous = passmissing(ifelse).(r4.indigenous .== "No", false, true)
    
    return resp, rd, r4
    end

"""
fix_birth_date!(df, resp_id)

Fix birth date for a specific respondent by copying the last valid date.
"""
function fix_birth_date!(df, resp_id)
    match_indices = df.name .== resp_id
    last_valid_idx = findlast(match_indices)
    df[match_indices, :date_of_birth] .= df.date_of_birth[last_valid_idx]
    return nothing
end

"""
create_wave4_respondent_data(rd)

Create a DataFrame for wave 4 respondent data, with appropriate non-imputed variables.
"""
function create_wave4_respondent_data(rd)
    # Variables that should not be imputed
    noupd_resp = [
    :wave, :complete, :data_source,
    :survey_start, :survey_end, :municipality, :office,
    :survey_version, :status,
    :new_building, :moved_village, :moved_building,
    :age_range, :preg_now, :avoid_preg_now,
    :fajero  # intervention variable
    ]

    # Create wave 4 dataset
    r4 = respwave(rd, noupd_resp; ids=ids, wave=4)
    return r4
end

## Process Household Data

# ==========================================================

"""
process_household_data(rd, hc)

Load, clean, and process household data across all waves.
Requires respondent data structures for member information.
"""
function process_household_data(rd, hc)
    println("Processing household data...")

    # Load household data for all waves
    hh_data = [
        CSV.read(hc.base_path * x, DataFrame; missingstring="NA") 
        for x in hc.hh_paths
    ]
    
    # Clean and standardize household data
    hh = clean_household(hh_data, hc.waves; namedict=hc.namedict, nokeymiss=true)
    select!(hh, Not(:hh_target))
    
    # Process household data and create wave 4 dataset
    h4, hd = create_household_structures(hh)

    # Add members to household structs from respondent data
    add_members_to_households!(hd, rd)
    
    # Process wealth index data
    wealthindex = process_wealth_index(hc)
    
    # Join wealth index with household data
    leftjoin!(h4, wealthindex, on=:building_id)

    # add positions
    # causes issues if it happens earlier (in household structs, basically it cannot update this type)
    h4.position = [
        (a, b) for (a,b) in zip(h4.building_latitude, h4.building_longitude)
    ];
    
    return hh, h4, hd
end

"""
process_wealth_index(hc)

Process and standardize the wealth index data to unit range.
"""
function process_wealth_index(hc)
windex = CSV.read("mca/wealth_index.csv", DataFrame)

    # Create dimension 1 wealth index
    d1 = @chain windex begin
        transform([:wave] => ByRow(string) => :wi)
        unstack([:building_id], :wi, :wealth_d1;
            renamecols=x->Symbol(:wealth_d1_, x)
        )
    end
    
    # Create dimension 2 wealth index
    d2 = @chain windex begin
        transform([:wave] => ByRow(string) => :wi)
        unstack([:building_id], :wi, :wealth_d2;
            renamecols=x->Symbol(:wealth_d2_, x)
        )
    end
    
    @assert d1.building_id == d2.building_id
    wealthindex = hcat(d1, d2[!, 2:end])

    # no wealth index at wave 2
    wv = setdiff(hc.waves, [2])
    
    # Standardize to unit range
    ds = vcat(
        [Symbol("wealth_d1_" * string(i)) for i in wv],
        [Symbol("wealth_d2_" * string(i)) for i in wv]
    )
    
    for x in ds
        y = wealthindex[!, x]
        mn, mx = extrema(skipmissing(y))
        wealthindex[!, x] = (y .- mn) ./ (mx - mn)
    end
    
    return wealthindex
end

## Process Microbiome Data

# ==========================================================

"""
process_microbiome_data()

Load, clean, and process microbiome data from cohorts.
"""
function process_microbiome_data(hc)
println("Processing microbiome data...")

    mb1, mb2 = [
        CSV.read(hc.mb_path * x, DataFrame; missingstring="NA") 
        for x in [hc.cohort1_path, hc.cohort2_path]
    ]
    
    # Clean and standardize microbiome data
    mb = clean_microbiome(mb1, mb2; namedict=hc.namedict)
    rename!(mb, :data_source => :data_source_mb)
    
    # Remove duplicate columns
    mbdupes = [
        :gender, :date_of_birth, :age_at_survey, :marital_name, 
        :building_id, :village_name, :municipality, :age_range, :notes
    ]
    select!(mb, Not(mbdupes))
    
    # Code categorical variables
    code_variables!(mb)
    
    return mb
end

## Process Village Data

# ==========================================================

"""
process_village_data()

Load, clean, and process village data across waves 1-3.
"""
function process_village_data(hc)
println("Processing village data...")

    # Load village data for waves 1-3 (no W4 village-level data)
    vdfs = [
        CSV.read(hc.base_path * vpth, DataFrame; missingstring="NA") 
        for vpth in hc.village_paths
    ]
    
    # Clean and standardize village data

    # exclude wave 4 where there is no village data
    wv = setdiff(hc.waves, [4])

    vill = clean_village(vdfs, wv; namedict=hc.namedict)
    
    # Remove unnecessary columns
    select!(vill, Not([:village_wealth_index, :num_hh_targeted, :ave_resp_hh]))
    
    # Process village data and create wave 4 dataset
    v4, vd = create_village_structures(vill)
    
    # Code categorical variables
    code_variables!(v4)
    
    return vill, v4, vd
end

## Process Network Data

# ==========================================================

"""
process_network_data()

Load, clean, and process network connection data across all waves.
Creates derived networks and calculates network metrics.
"""
function process_network_data(hc)
println("Processing network data...")

    # Load connection data for all waves
    conns = [
        CSV.read(hc.base_path * con_path, DataFrame; missingstring="NA") 
        for con_path in hc.con_paths
    ]
    
    # Clean and standardize connection data
    con = clean_connections(
        conns,
        hc.waves;
        alter_source=false,
        same_village=false,
        removemissing=false
    )
    
    # Filter to census connections
    @subset! con :alter_source .== "Census"
    
    # Remove self-connections
    @subset!(con, :ego .!= :alter)
    
    # Process kinship and add symmetric ties
    shiftkin!(con)
    addsymmetric!(con)
    select!(con, Not(:tie))
    
    # Remove non-person entries
    nons = ["No one", "No_One", "Refused", "Dont_Know"]
    con = con[con.alter .∉ Ref(nons), :]
    con = con[con.ego .∉ Ref(nons), :]
    
    # Create borrow-lend network
    ndf_m = jointnetwork(
        con, 
        "trust_borrow_money", 
        "trust_lend_money", 
        "borrow_et_lend"
    )
    
    # Create give-get health network
    ndf_h = jointnetwork(
        con, 
        "health_advice_get", 
        "health_advice_give", 
        "give_et_get_health"
    )
    
    # Process all network data
    for x in [con, ndf_m, ndf_h]
        select!(x, Not(["symmetric", "alter_as_ego"]))
        HondurasTools.addties!(x)
    end
    
    # Combine all network data
    con = vcat(con, ndf_m, ndf_h)
    addsymmetric!(con)
    
    # Calculate network variables
    ndf = networkinfo(
        con;
        hc.waves,
        relnames = [
            "free_time", "personal_private", "are_related", "union", "any"
        ]
    );
    
    # Ensure relation is string type
    ndf.relation = convert(Vector{Base.String}, ndf.relation)
    
    return con, ndf
end

## Process CSS Data

# ==========================================================

"""
process_css_data(ndf, con, hc)

Load, clean, and process CSS (network perception) data.
Links perception data with actual network structure.
"""
function process_css_data(ndf, con, hc; savedistances = true)
println("Processing CSS data...")

    # Load CSS data
    css = CSV.read(hc.base_path * hc.css_path, DataFrame; missingstring="NA")
    
    # Clean and arrange CSS data
    clean_css!(css)
    css = arrangecss(css)
    
    # Remove problematic rows
    @subset!(css, :alter1 .!= :alter2)
    @subset!(css, :perceiver .!= :alter2)
    @subset!(css, :perceiver .!= :alter1)
    
    # Drop rows with missing crucial data
    dropmissing!(css, [:perceiver, :village_code, :response, :relation])
    
    # Filter to wave 4 network data
    ndf4 = @subset ndf :wave .== 4
    
    # Calculate CSS distances
    cssdx = cssdistances(
        css, 
        ndf4;
        ids=ids,
        post=true
    )
    
    if savedistances
        # Save CSS distances
        BSON.bson(
            hc.write_path * "css_distances_" * hc.date_stamp * ".bson", 
            Dict(:cssxdx => prepare_for_bson(cssdx))
        )
    end
    
    css = cssdx
    
    # Filter to friendship and partnership relations
    @subset!(css, :relation .∈ Ref([rl.ft, rl.pp]))
    
    # Filter out non-responses
    @subset!(css, :response .∉ Ref(["Dont_Know", "Refused", "Don't Know"]))
    
    # Convert response to boolean
    css.response = ifelse.(css.response .== "Yes", true, false)
    
    # Calculate ground truth
    gt = groundtruth(css, con; alter_source=nothing, nets)
    groundtruthprocess!(gt)
    
    # Merge ground truth with CSS data
    vsmerge!(
        css, 
        gt;
        vs=[
            :socio4, :socio431, :kin4, :kin431, 
            :union4, :union431, :any4, :any431
        ],
        xs=[:perceiver, :alter1, :alter2, :relation]
    )    
    
    return css, gt
end

## Support Functions

# ==========================================================

"""
create_household_structures(hh)

Process household data and create structures for analysis.
"""
function create_household_structures(hh)
    vs = Symbol.(names(hh))
    hd = householdprocess(hh, vs; ids=ids)

    noupd_hh = [
        :building_id, :village_code, :hh_resp_name, 
        :hh_survey_start, :data_source_hh, :hh_wealth, 
        :wave, :hh_new_building
    ]
    
    h4 = hhwave(hd, noupd_hh; ids=ids, wave=4)
    
    return h4, hd
end

"""
add_members_to_households!(hd, rd)

Add member information to household data structures.
"""
function add_members_to_households!(hd, rd)
rx = DataFrame(:name => String[], :wave => Int[], :building_id => String[])

    for y in values(rd)
        for w in 1:4
            o = get(y.building_id, w, missing)
            if !ismissing(o)
                push!(rx, [y.name, w, o])
            end
        end
    end
    
    rxb = @chain rx begin
        groupby([:building_id, :wave])
        combine(:name => unique∘Ref => :names)
        sort([:building_id, :wave])
    end
    
    for (i, e) in enumerate(rxb.building_id)
        hdv = get(hd, e, missing)
        if !ismissing(hdv)
            hdv.members[rxb.wave[i]] = rxb.names[i]
        end
    end
    
    return nothing
end

"""
create_village_structures(vill)

Process village data and create structures for analysis.
"""
function create_village_structures(vill)
    vs = Symbol.(names(vill))
    vd = villageprocess(vill, vs)

    noupd_vill = [:village_code, :village_name]
    v4 = villwave(vd, noupd_vill; ids=ids, wave=3)
    
    return v4, vd
end

"""
create_combined_dataset(r4, h4, v4, mb)

Combine respondent, household, village, and microbiome data into one dataset.
"""
function create_combined_dataset(r4, h4, v4, mb, coplate, hc; savedict = true)
    println("Creating combined dataset...")

    # Rename imputation and waves columns to avoid conflicts
    rename!(r4, :impute => :impute_r, :waves => :waves_r)
    rename!(h4, :impute => :impute_h, :waves => :waves_h)
    rename!(v4, :impute => :impute_v, :waves => :waves_v)
    
    # Remove duplicated columns and wave column (all wave 4)
    select!(r4, Not(:municipality, :office))
    @assert all(h4.wave .== 4)
    select!(h4, Not(:wave))
    @assert all(r4.wave .== 4)
    select!(r4, Not(:wave))
    
    # Join household and village data
    hv4 = leftjoin(h4, v4, on = :village_code)
    
    # Join respondent with household and village data
    rhv4 = leftjoin(
        r4, 
        hv4,
        on = [:village_code, :building_id],
        matchmissing = :notequal
    )
    
    # Prepare microbiome data for joining
    select!(
        mb,
        Not([
            "village_code",
        ])
    )
    
    select!(mb, [
        :name, pers_vars..., :getmoney, :spend,
        :risk_score, :green_score, :purple_score,
        :cognitive_score, :impaired, :cognitive_status,
        :cohort, :mbset
    ])
    
    # Join microbiome data
    leftjoin!(rhv4, mb, on=[:name])
    
    # Join cooperation data
    leftjoin!(rhv4, coplate, on=[:name])
    
    if savedict
        # Save variable name dictionary
        BSON.bson(
            hc.write_path * "variable_namedict_" * hc.date_stamp * ".bson", 
            Dict(:namedict => hc.namedict)
        )
    end
    
    return rhv4
end

"""
process_cooperation_data()

Process cooperation and IHR data.
"""
function process_cooperation_data()
    pth = "../COOP/v1/"
    ihfiles = readdir(pth)

    cop, ihr = [
        CSV.read(pth*ihf, DataFrame; missingstring="NA") for ihf in ihfiles
    ]
    
    cop, ihr = clean_ihr(cop, ihr)
    
    return cop, ihr
end

"""
process_cooperation_rounds(cop)

Process cooperation data by round and create early/late variables.
"""
function process_cooperation_rounds(cop)
    coplate = @chain cop begin
        @subset((:round_n .> 7) .| ((:round_n .< 4)))
        @transform(:late = ifelse.(:round_n .> 4, true, false))
        groupby([:name, :village_code, :late])
        combine(:contributing => mean => :contributing)
        unstack(:late, :contributing; renamecols=x -> Symbol(:late_, x))
        rename(:late_false => :coop_early, :late_true => :coop_late)
        @transform(:coop_diff = :coop_late .- :coop_early)
    end

    select!(coplate, Not(:village_code))
    
    return coplate
end

"""
create_css_research_dataset(css, rhv4, ndf, ndf4)

Create the final CSS research dataset with all necessary variables.
"""
function create_css_research_dataset(css, rhv4, ndf, ndf4)
    # Create copy of CSS data
    cr = deepcopy(css)
    rename!(cr, :village_name => :village_name_css)

    # Join with respondent, household, and village data
    leftjoin!(
        cr, 
        rhv4;
        on=[:perceiver => :name, :village_code],
        matchmissing=:notequal
    )
    
    # Verify data integrity
    @assert css[!, [:perceiver, :alter1, :alter2, :relation]] == 
            cr[!, [:perceiver, :alter1, :alter2, :relation]]
    
    # Convert relation to categorical and code variables
    cr.relation = categorical(cr.relation)
    code_variables!(cr)
    
    # Add network data
    addnetworkdata!(cr, ndf)
    
    # Create simplified occupation variable
    cr.occ_simp = recode(cr.occupation,
        "Armed/police forces" => "Other",
        "Care work" => "Care work",
        "Dont_Know" => missing,
        "Emp. service/goods co." => "Other",
        "Farm owner" => "Other",
        "Merchant/bus. owner" => "Other",
        "Other" => "Other",
        "Profession" => "Other",
        "Retired/pensioned" => "Other",
        "Student" => "Other",
        "Trades" => "Other",
        "Unemp. disabled" => "Other",
        "Unemp. looking" => "Other",
        "Unemp: not looking" => "Other",
        "Work in field" => "Work in field"
    )
    
    # Create religious attendance variable
    cr.relig_weekly = recode(
        cr.relig_attend,
        "Never or almost never" => "<= Monthly",
        "Once or twice a year" => "<= Monthly",
        "Once a month" => "<= Monthly",
        "Once per week" => ">= Weekly",
        "More than once per week" => ">= Weekly"
    )
    
    # Convert to boolean
    cr.relig_weekly = passmissing(ifelse).(
        cr.relig_weekly .== ">= Weekly", true, false
    )
    
    # Create additional variables
    cr.age2 = (cr.age).^2
    cr.child = cr.children_under12 .> 0
    
    # Clean religion variable
    cr.religion_c = deepcopy(cr.religion)
    replace!(cr.religion_c, "Mormon" => missing, "Other" => missing)
    
    # Do the same for the respondent dataset
    rhv4.religion_c = deepcopy(rhv4.religion)
    replace!(rhv4.religion_c, "Mormon" => missing, "Other" => missing)
    
    # Create tie variables
    cssalt = tievariables(
        css, 
        ndf4, 
        rhv4;
        tie_variables=[
            :age,
            :man,
            :educated, 
            :wealth_d1_4, 
            :religion_c,
            :isindigenous,
            :risk_score, 
            :spend
        ],
        continuous_tie_variables=[
            :age, 
            :spend, 
            :risk_score, 
            :wealth_d1_4,
            :degree, 
            :degree_centrality,
            :betweenness, 
            :betweenness_centrality
        ]
    )
    
    # Add tie variables to cr dataset
    cr = hcat(cr, select(cssalt, Not(:relation, :alter1, :alter2)))
    
    # Free memory
    cssalt = nothing
    
    # Add population variable
    add_population_to_cr!(cr, rhv4)
    
    return cr
end

"""
add_population_to_cr!(cr, rhv4)

Add population count by village to the CSS research dataset.
"""
function add_population_to_cr!(cr, rhv4)
    rhv4_p = @chain rhv4 begin
        groupby(:village_code)
        combine(nrow => :population)
        dropmissing()
    end

    leftjoin!(cr, rhv4_p, on=:village_code)
    
    return nothing
end

## Main Execution

# ==========================================================

"""
main()

Main execution function that runs the entire data processing pipeline.
"""
function main(hc)
println("Starting Honduras data processing: \$(hc.date_stamp)")

    # Process respondent data
    resp, rd, r4 = process_respondent_data(hc)

    # Save respondent structures
    BSON.bson(hc.write_path * "respondent_structs_" * hc.date_stamp * ".bson", Dict(:rd => rd))

    # Save wave 4 respondent data
    BSON.bson(hc.write_path * "respondent_w4_" * hc.date_stamp * ".bson", Dict(:r4 => r4))
    
    # Process household data
    hh, h4, hd = process_household_data(rd, hc)

    # Save household structures
    BSON.bson(hc.write_path * "household_structs_" * hc.date_stamp * ".bson", Dict(:hd => hd))

    # Save wave 4 household data
    BSON.bson(hc.write_path * "household_w4_" * hc.date_stamp * ".bson", Dict(:h4 => h4))

    # Process microbiome data
    mb = process_microbiome_data(hc)

    # Save microbiome data
    BSON.bson(hc.write_path * "microbiome_data_" * hc.date_stamp * ".bson", Dict(:mb => mb))
    
    # Process village data
    vill, v4, vd = process_village_data(hc)

    # Save village structures
    BSON.bson(hc.write_path * "village_structs_" * hc.date_stamp * ".bson", Dict(:vd => vd))

    # Save wave 4 village data
    BSON.bson(hc.write_path * "village_w4_" * hc.date_stamp * ".bson", Dict(:v4 => v4))
    
    # Process cooperation data
    cop, ihr = process_cooperation_data(hc)

    # Save IHR data
    BSON.bson(hc.write_path * "ihr_data_" * hc.date_stamp * ".bson", Dict(:ihr => ihr))
    
    # Process cooperation data for joining
    coplate = process_cooperation_rounds(cop)

    # Create combined dataset
    rhv4 = create_combined_dataset(r4, h4, v4, mb, coplate, hc; savedict = true)
    
    # Save combined dataset
    BSON.bson(hc.write_path * "rhv4_" * hc.date_stamp * ".bson", Dict(:rhv4 => rhv4))

    # Process network data
    con, ndf = process_network_data(hc)

    # Save connection data
    BSON.bson(hc.write_path * "connections_data_" * hc.date_stamp * ".bson", Dict(:con => con))

    # Save network information
    BSON.bson(hc.write_path * "network_info_" * hc.date_stamp * ".bson", Dict(:ndf => ndf))
    
    # Process CSS data
    css, gt = process_css_data(ndf, con, hc; savedistances = true)

    # Save ground truth and CSS data
    BSON.bson(hc.write_path * "ground_truth_" * hc.date_stamp * ".bson", Dict(:gt => gt))
    BSON.bson(hc.write_path * "css_dis_" * hc.date_stamp * ".bson", Dict(:css => css))

    # Create final CSS research dataset
    cr = create_css_research_dataset(css, rhv4, ndf, ndf4)

    # Save main working data for the CSS project
    BSON.bson(hc.write_path * "cr_" * hc.date_stamp * ".bson", Dict(:cr => cr))
    
    println("Data processing complete! Output files saved to: $(hc.write_path)")
    
    return nothing
end

"""
    prepare_for_bson(df)
    
Convert problematic column types to BSON-compatible formats.
Handles all InlineStrings variants and other problematic types.
"""
function prepare_for_bson(df)
    df_copy = copy(df)
    
    for col in names(df_copy)
        col_type = eltype(df_copy[!, col])
        type_str = string(col_type)
        
        # Case 1: Direct InlineStrings
        if occursin("InlineStrings", type_str)
            if occursin("CategoricalValue", type_str)
                # Handle categorical columns with InlineStrings
                df_copy[!, col] = categorical(passmissing(String).(df_copy[!, col]))
            else
                # Handle regular InlineStrings columns
                df_copy[!, col] = passmissing(String).(df_copy[!, col])
            end
        
        # Case 2: Any type - check and convert each element
        elseif col_type == Any
            # Process each cell individually
            for i in 1:nrow(df_copy)
                val = df_copy[i, col]
                
                # Skip missing values
                if ismissing(val)
                    continue
                end
                
                # Check if the value contains InlineStrings
                if typeof(val) <: CSV.InlineStrings.InlineString
                    df_copy[i, col] = String(val)
                elseif val isa Vector && !isempty(val) && eltype(val) <: CSV.InlineStrings.InlineString
                    df_copy[i, col] = String.(val)
                end
            end
        
        # Case 3: Union{Missing, Nothing, Int64} - normalize Nothing to missing
        elseif Union{Missing, Nothing, Int64} == col_type
            # Convert Nothing to missing for consistency
            df_copy[!, col] = [v === nothing ? missing : v for v in df_copy[!, col]]
        end
    end
    
    return df_copy
end

# proceess and save individual demographic files
function demographics(hc)
    resp, rd, r4 = process_respondent_data(hc);

    # Save respondent structures
    # BSON.bson(hc.write_path * "respondent_structs_" * hc.date_stamp * ".bson", Dict(:rd => rd))

    # Save wave 4 respondent data
    BSON.bson(hc.write_path * "respondent_w4_" * hc.date_stamp * ".bson", Dict(:r4 => prepare_for_bson(r4)));

    # Save respondent data
    # BSON.bson(hc.write_path * "respondent_" * hc.date_stamp * ".bson", Dict(:r => prepare_for_bson(resp)));

    # Process household data
    hh, h4, hd = process_household_data(rd, hc);

    # Save household structures
    # BSON.bson(hc.write_path * "household_structs_" * hc.date_stamp * ".bson", Dict(:hd => hd))

    # Save wave 4 household data
    BSON.bson(hc.write_path * "household_w4_" * hc.date_stamp * ".bson", Dict(:h4 => prepare_for_bson(h4)))

    # Save household data
    # BSON.bson(hc.write_path * "household_" * hc.date_stamp * ".bson", Dict(:h => prepare_for_bson(hh)))

    # Process microbiome data
    mb = process_microbiome_data(hc);

    # Save microbiome data
    BSON.bson(hc.write_path * "microbiome_data_" * hc.date_stamp * ".bson", Dict(:mb => prepare_for_bson(mb)));

    # Process village data
    vill, v4, vd = process_village_data(hc);

    # Save village structures
    # BSON.bson(hc.write_path * "village_structs_" * hc.date_stamp * ".bson", Dict(:vd => vd))

    # Save wave 4 village data
    BSON.bson(hc.write_path * "village_w4_" * hc.date_stamp * ".bson", Dict(:v4 => prepare_for_bson(v4)));

    # Save village data
    # BSON.bson(hc.write_path * "village_" * hc.date_stamp * ".bson", Dict(:v => prepare_for_bson(vill)));

    # Process cooperation data
    cop, ihr = process_cooperation_data();

    # Process cooperation data for joining
    # simplified early, late, difference values
    coplate = process_cooperation_rounds(cop);

    # Save the cooperation data
    BSON.bson(hc.write_path * "coop_data_" * hc.date_stamp * ".bson",
        Dict(
            :cop => prepare_for_bson(cop),
            :coplate => prepare_for_bson(coplate),
        )
    );

    # Save IHR data
    BSON.bson(hc.write_path * "ihr_data_" * hc.date_stamp * ".bson", Dict(:ihr => prepare_for_bson(ihr)));

    return nothing
end

"""
    create_combined_demographics(hc::HondurasConfig)

Load individual datasets and create a combined research dataset with respondent, 
household, village, and microbiome data.

# Arguments
- `hc`: Honduras configuration object containing paths and date stamp

# Returns
- `rhv4`: Combined dataset with all research variables

"""
function create_combined_demographics(hc::HondurasConfig)
    # Define paths for all required data files
    resp_path = hc.write_path * "respondent_w4_" * hc.date_stamp * ".bson"
    hh_path = hc.write_path * "household_w4_" * hc.date_stamp * ".bson"
    village_path = hc.write_path * "village_w4_" * hc.date_stamp * ".bson"
    mb_path = hc.write_path * "microbiome_data_" * hc.date_stamp * ".bson"
    coop_path = hc.write_path * "coop_data_" * hc.date_stamp * ".bson"
    
    # Load datasets with error handling
    r4 = load_dataset(resp_path, :r4, "respondent")
    h4 = load_dataset(hh_path, :h4, "household")
    v4 = load_dataset(village_path, :v4, "village")
    mb = load_dataset(mb_path, :mb, "microbiome")
    
    # Load cooperation data
    coplate = try
        BSON.load(coop_path)[:coplate]
    catch e
        @warn "Cooperation data not loaded: $e"
        @info "Creating dataset without cooperation data"
        nothing
    end
    
    # Create the combined dataset
    @info "Merging datasets..."
    rhv4 = if isnothing(coplate)
        create_combined_dataset(r4, h4, v4, mb, hc; savedict=false)
    else
        create_combined_dataset(r4, h4, v4, mb, coplate, hc; savedict=false)
    end
    
    # Save the combined dataset
    output_path = hc.write_path * "rhv4_" * hc.date_stamp * ".bson"
    @info "Saving combined dataset to: $output_path"
    
    # Prepare dataset for BSON storage
    BSON.bson(output_path, Dict(:rhv4 => prepare_for_bson(rhv4)))
    
    return rhv4
end

"""
    load_dataset(path, key, dataset_name)

Helper function to load a dataset from BSON file with error handling.

# Arguments
- `path`: Path to the BSON file
- `key`: Symbol key for the dataset in the BSON file
- `dataset_name`: Human-readable name for error messages

# Returns
- The loaded dataset
"""
function load_dataset(path, key, dataset_name)
    try
        @info "Loading $dataset_name data from: $path"
        return BSON.load(path)[key]
    catch e
        error("Failed to load $dataset_name data: $e")
    end
end

"""
    create_css_data(hc::HondurasConfig)

Process and create Cognitive Social Structure (CSS) data by combining network data
with perception data and demographic information.

This function:
1. Loads the combined demographic dataset (rhv4)
2. Processes network connection data
3. Creates CSS perception datasets
4. Creates ground truth networks for comparison
5. Builds the final research-ready CSS dataset with all variables

# Arguments
- `hc`: Honduras configuration object containing paths and date stamp

# Returns
- `cr`: Research-ready CSS dataset with perception, network, and demographic variables

# Files Created
- connections_data_*.bson: Network connections data
- network_info_*.bson: Network structure and metrics
- ground_truth_*.bson: Actual network structures for validation
- css_dis_*.bson: CSS perception data with distances
- cr_*.bson: Main working dataset for CSS analysis

# Example
"""
function create_css_data(hc::HondurasConfig)
    @info "Creating CSS research dataset..."
    
    # Load the combined demographic dataset
    rhv4_path = hc.write_path * "rhv4_" * hc.date_stamp * ".bson"
    @info "Loading demographic data from: $rhv4_path"
    rhv4 = load_dataset(rhv4_path, :rhv4, "combined demographics")
    
    # Process network data
    @info "Processing network connections data..."
    con, ndf = process_network_data(hc)
    
    # Filter to wave 4 network data
    @info "Extracting wave 4 network data..."
    # ndf4 = @subset ndf :wave .== 4
    
    # Save connection data
    con_path = hc.write_path * "connections_data_" * hc.date_stamp * ".bson"
    @info "Saving connection data to: $con_path"
    BSON.bson(con_path, Dict(:con => prepare_for_bson(con)))
    
    # Save network information
    net_path = hc.write_path * "network_info_" * hc.date_stamp * ".bson"
    @info "Saving network metrics to: $net_path"
    BSON.bson(net_path, Dict(:ndf => prepare_for_bson(ndf)))
    
    # Process CSS perception data
    @info "Processing CSS perception data..."
    css, gt = process_css_data(ndf, con, hc; savedistances = true)

    # Save ground truth network data
    gt_path = hc.write_path * "ground_truth_" * hc.date_stamp * ".bson"
    @info "Saving ground truth data to: $gt_path"
    BSON.bson(gt_path, Dict(:gt => prepare_for_bson(gt)))
    
    # add building information for alters
    HondurasTools.add_building_info!(css, rhv4)
    rb = select(rhv4, [:name, :building_id])
    leftjoin!(css, rb, on = :perceiver => :name)

    # household distances
    hh_dists = hh_distances(css, hc)
    leftjoin!(css, hh_dists, on = [:village_code, :building_id, :building_id_a1, :building_id_a2])
    
    # Save CSS distance data
    css_path = hc.write_path * "css_dis_" * hc.date_stamp * ".bson"
    @info "Saving CSS distances to: $css_path"
    BSON.bson(css_path, Dict(:css => prepare_for_bson(css)))

    return nothing
end

function create_cr(hc::HondurasConfig)

    # Load the css data
    css_path = hc.write_path * "css_dis_" * hc.date_stamp * ".bson"
    @info "Loading css data from: $css_path"
    css = load_dataset(css_path, :css, "css data")

    # Load the combined demographic dataset
    rhv4_path = hc.write_path * "rhv4_" * hc.date_stamp * ".bson"
    @info "Loading demographic data from: $rhv4_path"
    rhv4 = load_dataset(rhv4_path, :rhv4, "combined demographics")
    
    # network info
    net_path = hc.write_path * "network_info_" * hc.date_stamp * ".bson"
    @info "Loading network data from: $net_path"
    ndf = load_dataset(net_path, :ndf, "network data")
    ndf4 = @subset ndf :wave .== 4;

    # Create final CSS research dataset with demographics and network metrics
    @info "Creating final research dataset..."
    cr = create_css_research_dataset(css, rhv4, ndf, ndf4)
    
    # Save main working data for the CSS project
    @info "Saving CSS research dataset to: $cr_path"
    cr_path = hc.write_path * "cr_" * hc.date_stamp * ".bson"
    BSON.bson(cr_path, Dict(:cr => prepare_for_bson(cr)))
    # cr_path = hc.write_path * "cr_" * hc.date_stamp * ".jld2"
    # JLD2.save_object(cr_path, cr)
    
    @info "CSS data processing complete! All files saved to: $(hc.write_path)"
    return cr
end
