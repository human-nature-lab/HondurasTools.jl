# clean_mb_data.jl

"""
        clean_microbiome(mb1, mb2)
        
Clean the microbiome data, retaining the union of cohort columns and filling
absent values with missing. Adds `cohort` (1 or 2); this is not an HMB wave ID.
Donation amounts accept integers or integer strings; absent donation columns are allowed.

ARGS
≡≡≡≡≡≡≡≡≡≡

- mb1: cohort 1 raw data
- mb2: cohort 2 raw data

"""
function clean_microbiome(mb1, mb2; kwargs...)
    clean_microbiome([mb1, mb2], [1, 3]; kwargs...)
end

"""
    clean_microbiome(tables::Vector{DataFrame}, administrations::AbstractVector;
                     nokeymiss=true, namedict=nothing)

Clean HMB administrations: 1 = cohort 1 baseline, 2 = cohort 1 follow-up,
3 = cohort 2. Preserves one row per `(name, cohort, administration)` and rejects
duplicate observations. Missing person/village IDs are dropped only when
`nokeymiss=true`. The two-table method maps to administrations `[1, 3]`.
"""
function clean_microbiome(tables::Vector{DataFrame}, administrations::AbstractVector;
                          nokeymiss=true, namedict=nothing)
    !isempty(tables) && length(tables) == length(administrations) ||
        throw(ArgumentError("Supply one HMB administration per nonempty table list"))
    allunique(administrations) && all(a -> a isa Integer && a in 1:3, administrations) ||
        throw(ArgumentError("HMB administrations must be distinct integers in 1:3"))
    for (table, administration) in zip(tables, administrations)
        _require_columns(table, [:respondent_master_id, :village_code,
            :lives_in_village, :works_in_village], "clean_microbiome administration $administration")
    end
    namedict = isnothing(namedict) ? Dict{Symbol,Symbol}() : namedict
    tables = deepcopy(tables)
    for (table, administration) in zip(tables, administrations)
        table[!, :cohort] = fill(administration == 3 ? 2 : 1, nrow(table))
        table[!, :administration] = fill(administration, nrow(table))
    end
    mb = vcat(tables...; cols=:union)
    rename!(mb, :respondent_master_id => :name)
    nokeymiss && dropmissing!(mb, [:village_code, :name])
    keys = [:name, :cohort, :administration]
    known = dropmissing(mb, :name)
    any(nonunique(known, keys)) && throw(ArgumentError("Duplicate HMB person/administration observations"))

    mb_desc = _fast_desc(mb);

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
            :cohort,
            :administration,
            risk_vars...
        );

        risk = process_risk(risk; keys=keys)

        mb = leftjoin(mb, risk; on=keys, validate=(false, true), matchmissing=:notequal)
    end
    
    if :cognitive_status ∈ mb_desc.variable
        mb.cognitive_status = categorical(mb.cognitive_status; ordered = true);
        levels!(mb.cognitive_status, ["none", "impairment", "dementia"]);
    end

    if :mb_a0100 ∈ mb_desc.variable
        mb.mb_a0100 = categorical(mb.mb_a0100)
        rename!(mb, :mb_a0100 => :whereborn)
        namedict[:whereborn] = :mb_a0100
    end
    
    if :mb_a0200 ∈ mb_desc.variable
        mb.mb_a0200 = categorical(mb.mb_a0200)
        rename!(mb, :mb_a0200 => :dept)
        namedict[:dept] = :mb_a0200
    end
    
    if :mb_a0300 ∈ mb_desc.variable
        rename!(mb, :mb_a0300 => :mb_municipality)
        namedict[:mb_municipality] = :mb_a0300
    end
    
    if :mb_a0400 ∈ mb_desc.variable
        rename!(mb, :mb_a0400 => :country)
        namedict[:country] = :mb_a0400
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
        namedict[:eth_Lenca] = :mb_a0500a
    end

    if :mb_ab0100 ∈ mb_desc.variable
        rename!(mb, :mb_ab0100 => :spend)
        mb.spend = convertspend.(mb.spend)
        namedict[:spend] = :mb_ab0100
    end

    for v in [:mb_ab0110, :mb_ab0120]
        if v ∈ mb_desc.variable
            irrelreplace!(mb, v)
            mb[!, v] = categorical(mb[!, v])
        end
    end

    if :mb_ab0200 ∈ mb_desc.variable
        rename!(mb, :mb_ab0200 => :leavevillage)
        namedict[:leavevillage] = :mb_ab0200
    end

    if :mb_b0100 ∈ mb_desc.variable
        rename!(mb, :mb_b0100 => :mb_health)
        namedict[:mb_health] = :mb_b0100
    end

    if :mb_b1700 ∈ mb_desc.variable
        rename!(mb, :mb_b1700 => :mb_chronic)
        namedict[:mb_chronic] = :mb_b1700
    end

    if :mb_c0000 ∈ mb_desc.variable
        rename!(mb, :mb_c0000 => :getmoney)
        namedict[:getmoney] = :mb_c0000
        mb[!, :getmoney] = map(mb.getmoney) do x
            ismissing(x) && return missing
            if x isa Real
                isfinite(x) && isinteger(x) || throw(ArgumentError("Donation must be an integer amount: $x"))
                return Int(x)
            end
            return something(tryparse(Int, strip(string(x))), missing)
        end
    end


    # 19 villages that are in the study
    microbiome_villages = [
        5
        14
        17
        21
        26
        41
        58
        73
        89
        110
        116
        118
        140
        144
        145
        162
        163
        169
        174
    ];
    mb[!, :mbset] = mb.village_code .∈ Ref(microbiome_villages)

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

    mbpairs = (
        :mb_ba0100 => :feel_nervous,
        :mb_ba0400 => :trouble_relax,
        :mb_ba0600 => :irritable,
        :mb_ba0700 => :afraid,
        :mb_ba0800 => :little_pleasure,
    )

    for mbpair in mbpairs
        if first(mbpair) ∈ mb_desc.variable
            rename!(mb, mbpair)
            namedict[mbpair[2]] = mbpair[1]
        end
    end

    for (src, dst) in (
        :bfi10_extraversion => :extraversion,
        :bfi10_agreeableness => :agreeableness,
        :bfi10_conscientiousness => :conscientiousness,
        :bfi10_neuroticism => :neuroticism,
        :bfi10_openness_to_experience => :openness_to_experience,
    )
        if src ∈ mb_desc.variable
            rename!(mb, src => dst)
            namedict[dst] = src
        end
    end
    
    return mb
end

export clean_microbiome, microbiome_villages
