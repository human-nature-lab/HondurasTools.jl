# css_socio.jl
# merge in the ground truth into the css data

TieDict = Dict{Tuple{String, String}, Vector{String}}

function test_relations(con2)
    for e in con2.relationships
        if ("parent_child" ∈ e) & ("sibling" ∈ e)
            error("ground truth problem")
        end
    end
    return true
end

function recode!(
    con;
    parent_child = ["father", "mother", "child_over12_other_house"]
)
    con[!, :css_relationship] .= "";
    for (i, e) in enumerate(con[!, :relationship])
        con[i, :css_relationship] = if e ∈ parent_child
            "parent_child"
        else
            e
        end
    end
end

"""
        mk_tiedict(con3)

Create a dict from the connections edgelist to a dictionary for quick parsing.
"""
function mk_tiedict(con3)
    tiedict = TieDict()
    @eachrow con3 begin
        tiedict[(:ego, :alter)] = :relationships
    end
    return tiedict
end

"""
Wrapper for get with modified functionality to maintain type-stability.
"""
function get(tiedict::TieDict, tple)
    return get(tiedict, tple, Vector{String}())
end

function checkrelation(css_r, css_rel, con_r, con_rels)
    return (css_r == css_rel) & (con_r ∈ con_rels)
end

function checkrelations(css_r, con_rels)
    return if checkrelation(
        css_r, "personal_relationship", "personal_private", con_rels
    )
        "Yes"
    elseif checkrelation(css_r, "spend_free_time", "free_time", con_rels)
        "Yes"
    elseif (css_r == "are_related")
        if "parent_child" ∈ con_rels
            "parent_child"
        elseif "sibling" ∈ con_rels
            "sibling"
        else
            "No"
        end
    else
        "No"
    end
end

"""
Iterate through the (appropriately stacked) css data and add the truth of each
tie from the sociocentric network, via tiedict.

While "know_each_other" does not have a direct match in the sociocentric
network, since we did not ask about this tie directly in W3 (or any wave). However, this is handled by supposing that it is true in the sociocentric
network if there is at least one tie (over all collected relationships) between
two individuals.
"""
function assign_socioties!(
    csssocio, cssrelationships, cssalter1s, cssalter2s, tiedict
)
    for (j, (r, a1, a2)) in enumerate(
        zip(cssrelationships, cssalter1s, cssalter2s)
    )

        csssocio[j] = if length(get(tiedict, (a1, a2))) > 0
            if r == "know_each_other"
                "Yes"
            else
                checkrelations(r, get(tiedict, (a1, a2)))
            end
        else
            "No"
        end
    end
end

"""
        handle_socio(con)

Add the truth of each tie from the sociocentric network, `con` to the
css data.

While "know_each_other" does not have a direct match in the sociocentric
network, since we did not ask about this tie directly in W3 (or any wave). However, this is handled by supposing that it is true in the sociocentric
network if there is at least one tie (over all collected relationships) between
two individuals.
"""
function handle_socio(css, con)

    cona = deepcopy(con)

    sortedges!(cona.ego, cona.alter)

    recode!(cona)

    con2 = @chain cona begin
        select(Not([:relationship, :question]))
        unique()
        groupby([:ego, :alter, :village_code, :wave])
        combine(:css_relationship => Ref∘unique => :relationships)
    end

    test_relations(con2)

    # both con2 and css are sorted
    sortedges!(css.alter1, css.alter2)

    relationship_questions = [
        :know_each_other, :spend_free_time, :personal_relationship,
        :are_related
    ];

    css2 = stack(
        css,
        relationship_questions,
        [
            :village_code_w4, :perceiver, :alter1, :alter2,
            :knows_alter1, :knows_alter2
        ];
        variable_name = :relationship,
        value_name = :response
    );

    tiedict = mk_tiedict(con2);

    css2[!, :socio] = fill("", nrow(css2));
    assign_socioties!(
        css2[!, :socio],
        css2[!, :relationship], css2[!, :alter1], css2[!, :alter2], tiedict
    )
    return css2
end
