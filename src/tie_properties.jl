# tie_properties.jl

function amean!(cssalters, vbl)
    ab = Symbol(string(vbl) * "_mean_a")
    a1 = Symbol(string(vbl) * "_a1")
    a2 = Symbol(string(vbl) * "_a2")

    cssalters[!, ab] = (cssalters[!, a1] + cssalters[!, a2]) * inv(2);
end

export amean!

function adiff!(cssalters, vbl)
    ab = Symbol(string(vbl) * "_diff_a")
    a1 = Symbol(string(vbl) * "_a1")
    a2 = Symbol(string(vbl) * "_a2")

    cssalters[!, ab] = abs.(cssalters[!, a1] - cssalters[!, a2]);
end

export adiff!

function binarycat!(
    cssalters, vbl, va::x, vb::x; mixed = "Mixed"
) where x <: Tuple
    ab = Symbol(string(vbl) * "_a")
    a1 = Symbol(string(vbl) * "_a1")
    a2 = Symbol(string(vbl) * "_a2")
    cssalters[!, ab] = similar(cssalters[!, a1]);
    for (i, (v1, v2)) in enumerate(
        zip(cssalters[!, a1], cssalters[!, a2])
    )
        if !ismissing(v1) & !ismissing(v2)

            cssalters[i, ab] = if v1 == v2 == va[1]
                va[2]
            elseif v1 == v2 == vb[1]
                vb[2]
            else
                mixed
            end
        end
    end
end

export binarycat!

"""
        tievariables(
            css, ndf4, rhv4;
            tie_variables = [
                :age,
                :man,
                :educated, :wealth_d1_4, :religion_c,
                :isindigenous,
                :risk_score, :spend
            ],
            continuous_tie_variables = [
                :age, :spend, :risk_score, :wealth_d1_4,
                :degree, :degree_centrality,
                :betweenness, :betweenness_centrality
            ];
        )

## Description

Variables to include as tie properties.
"""
function tievariables(
    css, ndf4, rhv4;
    tie_variables = [
        :age,
        :man,
        :educated, :wealth_d1_4, :religion_c,
        :isindigenous,
        :risk_score, :spend
    ],
    continuous_tie_variables = [
        :age, :spend, :risk_score, :wealth_d1_4,
        :degree, :degree_centrality,
        :betweenness, :betweenness_centrality
    ]
)

    # network data
    rsel = select(rhv4, :name, tie_variables...);

    nsel = select(ndf4, :relation, :names, :degree, :degree_centrality, :betweenness, :betweenness_centrality);
    @subset! nsel :relation .∈ Ref(["free_time", "personal_private"]);
    nsel = flatten(nsel, names(nsel)[2:end]);
    rename!(nsel, :names => :name);

    # remove invalid nodes  
    @subset! nsel ((:name .!= "No_One") .& (:name .!= "Refused"))

    cssalt1 = css[!, [:alter1, :relation]];
    cssalt2 = css[!, [:alter2, :relation]];

    for (x, r) in zip([cssalt1, cssalt2], [:alter1, :alter2])
        leftjoin!(x, nsel; on = [r => :name, :relation])
    end

    for (x, r) in zip([cssalt1, cssalt2], [:alter1, :alter2])
        leftjoin!(x, rsel; on = [r => :name])
    end

    # test
    if !(cssalt1.alter1 == css.alter1) | !(cssalt2.alter2 == css.alter2)
        error("row mismatch")
    end

    for e in names(cssalt1)[3:end]
        rename!(cssalt1, e => e * "_a1")
    end

    for e in names(cssalt2)[3:end]
        rename!(cssalt2, e => e * "_a2")
    end

    cssalt = hcat(cssalt1, select(cssalt2, Not(:relation)));
    cssalt1 = nothing
    cssalt2 = nothing
    rsel = nothing
    nsel = nothing

    for cb in continuous_tie_variables
        amean!(cssalt, cb)
        adiff!(cssalt, cb)
    end

    # binary and categorical variables
    cssalt.man_a = gendercat.(cssalt.man_a1, cssalt.man_a2);

    cssalt.religion_c_a = passmissing(ifelse).(cssalt.religion_c_a1 .== cssalt.religion_c_a2, "Same", "Mixed")


    cssalt.religion_c_full_a = relcat.(cssalt.religion_c_a1, cssalt.religion_c_a2);
    cssalt.religion_c_full_a = categorical(cssalt.religion_c_full_a);

    #%%
    cssalt.isindigenous_a = indigcat.(cssalt.isindigenous_a1, cssalt.isindigenous_a2);
    cssalt.isindigenous_a = categorical(cssalt.isindigenous_a);

    #%%
    cssalt.educated_a = educat.(cssalt.educated_a1, cssalt.educated_a2);
    cssalt.educated_full_a = educat.(cssalt.educated_a1, cssalt.educated_a2; basic = false);
    for x in [:educated_a, :educated_full_a]
        cssalt[!, x] = categorical(cssalt[!, x])
    end

    # drop the individual alter values
    select!(cssalt, names(cssalt)[.!(occursin.("_a1", names(cssalt)) .| occursin.("_a2", names(cssalt)))])

    # test
    if !(cssalt.alter1 == cr.alter1) | !(cssalt.alter2 == cr.alter2)
        error("row mismatch")
    end
    return cssalt
end

export tievariables
