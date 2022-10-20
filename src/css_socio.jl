# css_socio.jl
# merge in the ground truth into the css data

TieDict = Dict{Tuple{String, String}, Vector{String}}

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
                # there there is at least one tie between
                # the alters in the edgelist, then say that
                # they "know each other"
                "Yes"
            else
                checkrelations(r, get(tiedict, (a1, a2)))
            end
        else
            "No"
        end
    end
end

function checkrelations(css_r, con_rels)
    return if css_r ∈ con_rels
        # if there is a direct match for the css2 relationship in 
        # the con_rels set, "Yes" the tie is true
        # this should happen for "personal_private" and "free_time"
        # otherwise that perceived tie does not exist in the sociocentric
        # network
        "Yes"
    elseif (css_r == "are_related")
        # there is a switch for "are_related":
        # we are not checking if the relationship is present
        # but the particular response, which we propogate if there is
        # a match
        # these should not overlap in the sociocentric network, so
        # this logic flow is OK
        if "Siblings" ∈ con_rels
            "Siblings"
        elseif "Parent/child" ∈ con_rels
            "Parent/child"
        elseif "Partners" ∈ con_rels
            "Partners"
        else
            "No"
        end
    else
        "No"
    end
end

"""
Wrapper for get with modified functionality to maintain type-stability.
"""
function get(tiedict::TieDict, tple)
    return get(tiedict, tple, Vector{String}())
end

function test_relations(con2)
    for e in con2.relationships
        if ("Parent/child" ∈ e) & ("Siblings" ∈ e)
            error("ground truth problem")
        end
    end
    return true
end

function recode_vars!(
    con;
    parent_child = ["father", "mother", "child_over12_other_house"]
)
    con[!, :css_relationship] .= "";
    for (i, e) in enumerate(con[!, :relationship])
        con[i, :css_relationship] = if e ∈ parent_child
            "Parent/child"
        elseif e == "sibling"
            "Siblings"
        elseif e == "partner"
            "Partners"            
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
