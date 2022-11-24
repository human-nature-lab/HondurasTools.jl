# clean_css.jl
# clean the (Liza-processed) data

function clean_css!(css)

    rename!(
        css,
        # :repeat1 => :order,
        :respondent_master_id => :perceiver,
        :ego_id => :alter1,
        :alter_id => :alter2,
        # :eg0100 => :knows_source, -> use knows ego
        # :eg0200 => :knows_target, -> use knows alter
        :knows_ego => :knows_alter1,
        :knows_alter => :knows_alter2,
        :eg0300 => :know_each_other,
        :eg0400 => :spend_free_time,
        :eg0500 => :personal_relationship,
        :eg0600 => :are_related
    )

    relationship_questions = [
        :know_each_other, :spend_free_time, :personal_relationship, :are_related
    ];

    select!(
        css,
        [
            :village_code_w4,
            :perceiver,
            :order,
            :alter1, :alter2,
            :knows_alter1, :knows_alter2,
            relationship_questions...,
            :village_name_w4,
            :timing
        ]
    )

    for r in relationship_questions
        css[!, r] = clean_response.(css[!, r])
    end

end

function clean_response(x)
    return if !ismissing(x)
        # "None of the above"
        # "Parent/child"
        # "Siblings"
        # "Partners"
        if x == "yes"
            "Yes"
        else x
        end
    else
        missing
    end
end
