# clean_css.jl
# clean the (Liza-processed) data

function clean_css(css)
    
    clean_css!(css)
    
    css.response = string.(css.response);
    
    try
        .!isnothing(fakemissing.(css.response))
    catch
        css.response = [x == "missing" ? missing : x for x in css.response];
    end;

    order_adjust!(css)

    css = handle_socio(css, con; checkfamily = false);
end

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

    @subset!(css, :alter1 .!= :alter2);
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
        elseif x == "no"
            "No"
        else x
        end
    else
        missing
    end
end

function assign_kin!(css, con)
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
