# prepare_css.jl

"""
        prepare_css(css, edges, resp; confilter = true)

Take the data that Liza will give and prepare it for general use.
filtercon = true filters the connections data to the correct set of relationships for CSS.
"""
function prepare_css(css, edges, resp; confilter = true)

    clean_css!(css)
    # dropmissing!(css)

    resp = clean_respondent(
        [resp], [4];
        selected = :all, nokeymiss = true, onlycomplete = true
    );

    ###

    # edges

    con = clean_connections(
        [edges],
        [4];
        alter_source = true,
        same_village = true,
        removemissing = true
    )

    sort!(con, [:wave, :village_code, :relationship, :ego, :alter])

    if confilter
        relationships = [
            "free_time",
            "personal_private",
            "father", "mother", "sibling", "child_over12_other_house",
            "partner"
        ];

        con = @subset(con, :relationship .∈ Ref(relationships))
    end

    return css, con, resp
end

"""
        prepare_css(css, edges; confilter = true)

Take the data that Liza will give and prepare it for general use.
filtercon = true filters the connections data to the correct set of relationships for CSS.
"""
function prepare_css(css, edges; confilter = true)

    clean_css!(css)
    dropmissing!(css)

    ###

    # edges

    con = clean_connections(
        [edges],
        [4];
        alter_source = true,
        same_village = true,
        removemissing = true
    )

    sort!(con, [:wave, :village_code, :relationship, :ego, :alter])

    if confilter
        relationships = [
            "free_time",
            "personal_private",
            "father", "mother", "sibling", "child_over12_other_house",
            "partner"
        ];

        con = @subset(con, :relationship .∈ Ref(relationships))
    end

    # rename to concord with con data
    rename!(
        css,
        :spend_free_time => :free_time,
        :personal_relationship => :personal_private
    )

    return css, con
end
