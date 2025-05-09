# clean_household.jl

"""
toiletify(ts, tt)

`ts` toilet shared, `tt` toilet type.
Create a combined variable that makes more sense.
N.B. this outputs a `Tuple`.
"""
function toiletify(ts, tt)
    c1 = ismissing(ts)
    c2 = ismissing(tt)
    c3 = (tt == "No facility (other location)") | (tt == "No facility (outdoors)") | (tt == "No facility (other home/establishment)")
    return if c1 & c2
        missing, missing
    elseif coalesce(c3, false)
        "No toilet", "No toilet"
    elseif !c1
        if ts
            "Shared", tt
        elseif !ts
            "Yes", tt
        end
    # Judgement for a few cases -> assume they don't share
    # if they report a toilet
    elseif c1 & !c2
        "Yes", tt
    end
end

"""
        clean_household(hh, waves; nokeymiss = true)

Clean the household level data. `hh` must be a vector of dataframes. Data must Must be ordered by and match `waves`.

ARGS
≡≡≡≡≡≡≡≡≡≡

- resp: a vector of DataFrames, with entries for each wave of the data.
- waves: indicate the wave of each DataFrame in the same order as resp.
- nokeymiss = true : whether to filter to not missing on key variables: village code and building id

"""
function clean_household(
    hh::Vector{DataFrame}, waves; nokeymiss = true, namedict = nothing)

    if isnothing(namedict)
        namedict = Dict{Symbol, Symbol}()
    end

    # check presence of each wave
    # remove `_wx` suffix

    if 1 ∈ waves
        widx = findfirst(waves .== 1)

        hnme1 = names(hh[widx]);
        hh[widx][!, :wave] .= 1;
        whnme11 = hnme1[occursin.("_w1", hnme1)];
        strip_wave!(hh[widx], whnme11, "_w1")
    end

    if 2 ∈ waves
        widx = findfirst(waves .== 2)

        hnme2 = names(hh[widx]);
        hh[widx][!, :wave] .= 2;
        # no 21
        whnme22 = hnme2[occursin.("_w2", hnme2)];
        strip_wave!(hh[widx], whnme22, "_w2")
    end
       
    if 3 ∈ waves
        widx = findfirst(waves .== 3)

        hnme3 = names(hh[widx]);
        hh[widx][!, :wave] .= 3;
        whnme33 = hnme3[occursin.("_w3", hnme3)];
        strip_wave!(hh[widx], whnme33, "_w3")
    end

    if 4 ∈ waves
        widx = findfirst(waves .== 4)

        hnme4 = names(hh[widx]);
        hh[widx][!, :wave] .= 4;
        whnme44 = hnme4[occursin.("_w4", hnme4)];
        strip_wave!(hh[widx], whnme44, "_w4")
    end

    # make a common set of columns that includes all unique
    # (e.g., if column only present a wave 1, it is present)
    regularizecols!(hh)

    # combine waves
    hh = reduce(vcat, hh);

    # raw data description contains variable list and types
    hh_desc = describe(hh);

    # remove irrelevant variables
    for x in [
        :l0900, :l1800, :l1900, :l8888, :l9999,
        :household_id, :skip_glitch]
        if x ∈ hh_desc.variable
            select!(hh, Not(x))
        end
    end

    # rename to avoid conflicts with other data
    rename!(hh, :survey_start => :hh_survey_start);
    rename!(hh, :new_building => :hh_new_building);

    v = :household_wealth_index
    if v ∈ hh_desc.variable
        rename!(hh, v => :hh_wealth_orig);
        namedict[:hh_wealth_orig] = :household_wealth_index
    end

    strclean!(:l0700, :toilettype, hh, hh_desc, namedict);
    bstrclean!(:l0800, :toiletshared, hh, hh_desc, namedict);

    # add `toilet` and `toiletkind`
    if (:l0800 ∈ hh_desc.variable) & (:l0700 ∈ hh_desc.variable)
        hh.toilet = missings(String, nrow(hh));
        hh.toiletkind = missings(String, nrow(hh));

        for (i, (ts, tt)) in (enumerate∘zip)(hh.toiletshared, hh.toilettype)
            hh.toilet[i], hh.toiletkind[i] = toiletify(ts, tt)
        end

        replace!(hh.toiletkind, "Other" => missing)
    end

    let st = [
            (:l0100, :children_under12),
            (:l0200, :girls_under12),
            (:l0300, :boys_under12)
        ]
        for (v, nv) in st
            numclean!(v, nv, hh, hh_desc, namedict)
        end
    end
    
    let xs = [
            (:l0900a, :electricity),
            (:l0900b, :radio),
            (:l0900c, :tv),
            (:l0900d, :cell),
            (:l0900e, :landline),
            (:l0900f, :fridge),
            (:l0900g, :noneof)
        ];

        for (a, b) in xs
            if Symbol(a) ∈ hh_desc.variable
                rename!(hh, a => b)
                namedict[b] = a
                irrelreplace!(hh, b)
                # if is not missing, then it is true
                # collected in all waves
                oldvals = copy(hh[!, Symbol(b)])
                hh[!, Symbol(b)] = missings(Bool, nrow(hh))
                for (i, e) in enumerate(oldvals)
                    # w = hh[i, :wave]
                    if ismissing(e)
                        hh[i, Symbol(b)] = false
                    else
                        hh[i, Symbol(b)] = true
                    end
                end
            end
        end
    end
    
    strclean!(:l0400, :watersource, hh, hh_desc, namedict)

    replace!(
        hh.watersource,
        "Cart with small tank" => "Cart with tank",
        "Dug well (proctected)" => "Dug well (prot.)",
        "Dug well (unprotected)" => "Dug well (unprot.)",
        # "Other", "Rainwater"
        "Surface water (river/dam/lake/pond/stream/canal/irrigation channel)" => "Surface water",
        # "Tanker truck"
        "Water from spring (protected)" => "Spring (prot.)",
        "Water from spring (unproctected)" => "Spring (unprot.)",
        # "Well with tube",
        "bottle water" => "Bottle water",
        "Other" => missing
    );

    bstrclean!(:l0600, :cleaningagent, hh, hh_desc, namedict);
    bstrclean!(:l1200, :kitchen, hh, hh_desc, namedict);

    let xs = [
            (:l1000, :cooktype),
            (:l1100, :cookfueltype),
            (:l1300, :flooring),
            (:l1400, :windows),
            (:l1500, :walltype),
            (:l1600, :roofing),
        ];

        for (v, nv) in xs
            strclean!(v, nv, hh, hh_desc, namedict)
        end
    end

    allowmissing!(hh, :cooktype)
    replace!(hh.cooktype, "Other" => missing)
    replace!(hh.cooktype, 
        "None (there is no stove/firebox)" => "None",
        "Furnace/firebox without a chimney" => "Furnace no chimney",
        "Furnace/firebox with a chimney" => "Furnace chimney"
    );

    replace!(hh.walltype, "Other" => missing)
    replace!(hh.roofing, "Other" => missing)

    allowmissing!(hh, :cookfueltype);
    replace!(hh.cookfueltype, "Keronsene" => "Kerosene");
    replace!(hh.cookfueltype, "Other" => missing);

    vs = [:l1700, :l0010]
    nvs = [:sleepingrooms, :over12live]
    for (nv, v) in zip(nvs, vs)
        numclean!(v, nv, hh, hh_desc, namedict)
    end

    strclean!(:l0500, :handwash, hh, hh_desc, namedict)
    replace!(
        hh.handwash,
        "Not observed" => "None",
        "Observed, water not available" => "No water",
        "Observed, water available" => "Water"
    )

    # hh respondent master id? is this the person who
    # reported the `hh` values?
    rename!(hh, "respondent_master_id" => "hh_resp_name")
    namedict[:hh_resp_name] = :respondent_master_id

    # filters
    let
        # remove columns in hh  (they are in village-level)
        dups = [:village_name, :municipality, :office];
        select!(hh, Not(dups))
        # not sure how there are wave 4 variables that are all missing
    end
    
    if nokeymiss
        dropmissing!(hh, :village_code);
        dropmissing!(hh, :building_id);
    end

    let # recode `data_source_hh`
        hh.data_source_hh = replace(
            hh.data_source_hh,
            1 => "Surveyed, Reported",
            2 => "Surveyed, Not reported",
            3 => "Not surveyed, not reported"
        );
    end
    return hh
end

export clean_household
