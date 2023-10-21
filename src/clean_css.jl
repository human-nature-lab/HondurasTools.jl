# clean_css.jl
# clean the (Liza-processed) data


function clean_css!(css)

    dropmissing!(css, [:completed_at, :edge_id, :ego_id, :alter_id]);
    
    rename!(
        css,
        :repeat1 => :order,
        :respondent_master_id => :perceiver,
        :ego_id => :alter1,
        :alter_id => :alter2,
        # :eg0100 => :knows_source, -> use knows ego
        # :eg0200 => :knows_target, -> use knows alter
        :knows_ego => :knows_alter1,
        :knows_alter => :knows_alter2,
        :eg0300 => :know_each_other,
        :eg0600 => :are_related,
        # rename to concord with connections data
        :eg0400 => :free_time,
        :eg0500 => :personal_private,
        :village_code_w4 => :village_code,
        :village_name_w4 => :village_name
    )

    # remove problem rows
    @subset!(css, :alter1 .!= :alter2);
    @subset!(css, :perceiver .!= :alter2);
    @subset!(css, :perceiver .!= :alter1);
    sortedges!(css.alter1, css.alter2)

    relationship_questions = [
        :know_each_other, :free_time, :personal_private, :are_related
    ];

    select!(
        css,
        [
            :village_code,
            :perceiver,
            :order,
            :alter1, :alter2,
            :knows_alter1, :knows_alter2,
            relationship_questions...,
            :village_name,
            :timing
        ]
    )


    for r in relationship_questions
        replace!(
            css[!, r], "yes" => "Yes", "no" => "No",
            "Dont_Know" => "Don't Know"
        )
    end    
end

"""
        assign_kin!(css, con)

Add kin variable to css.
"""
function assign_kin!(css, con)
    kin = [
        "child_over12_other_house", "father", "mother", "sibling", "partner"
    ];
    conrel = con[con.relationship .∈ Ref(kin), :];
    select!(conrel, [:ego, :alter, :village_code]);
    sortedges!(conrel.ego, conrel.alter);
    conrel = unique(conrel); # list of true kin relationships
    conrel[!, :kin] .= true

    leftjoin!(
        css, conrel,
        on = [:alter1 => :ego, :alter2 => :alter, :village_code]
    )
    css.kin[ismissing.(css.kin)] .= false;
    disallowmissing!(css, :kin)

end
