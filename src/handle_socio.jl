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

    # symmetrizing
    sortedges!(cona.ego, cona.alter)

    recode_vars!(cona)

    con2 = @chain cona begin
        select(Not([:relationship, :question]))
        unique()
        groupby([:ego, :alter, :village_code, :wave])
        combine(:css_relationship => Ref∘unique => :relationships)
    end

    test_relations(con2)

    # both con2 and css are sorted
    sortedges!(css.alter1, css.alter2)

    # css (altered before to match con where possible)
    relationship_questions = [
        :know_each_other,
        :free_time, :personal_private,
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
        css2[!, :relationship],
        css2[!, :alter1], css2[!, :alter2],
        tiedict
    )
    return css2
end
