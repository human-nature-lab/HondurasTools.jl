# css_socio.jl
# merge in the ground truth into the css data

function groundtruth(css, con, resp)

    known = select(
        css,
        [
            "perceiver",
            "alter1", "alter2", 
            "knows_alter1",
            "knows_alter2",
            "village_code"
            # "village_name", "timing", "order"
        ]
    ) |> unique;

    css2 = select(css, Not(["knows_alter1", "knows_alter2"]))

    css2 = stack(
        css2,
        ["know_each_other", "free_time", "personal_private", "are_related"];
        variable_name = :relation, value_name = :response
    )

    dropmissing!(css2)

    _con = deepcopy(con)
    # DONT SORT
    # sortedges!(_con.ego, _con.alter)

    kin_values = ["father", "mother", "sibling", "partner"]
    kin_dict = Dict(
        "father" => "Parent/child",
        "mother" => "Parent/child",
        "sibling" => "Siblings",
        "partner" => "Partners"
    )
    
    _con[!, :answer] = _con.relationship;
    kin_con = @views _con[_con.relationship .∈ Ref(kin_values), :];
    kin_con.answer = [
        get(kin_dict, e, "None of the above") for e in kin_con.relationship
    ];

    __con = @chain _con begin
        select([:ego, :alter, :answer, :wave, :village_code])
        unique()
        groupby([:ego, :alter, :village_code, :wave])
        combine(:answer => Ref∘unique => :answers)
    end;

    namedict = make_namedict(resp, __con)

    ___con = Dict{Tuple{String, String}, Vector{String}}();
    sizehint!(___con, 500000);

    # we need an additional check for prior waves to ensure that both elements of the pair exist in the data -- whether they are related or not

    for (i, (w, wx)) in enumerate(zip([4, 3, 1], [:w4, :w3, :w1]))
        empty!(___con)
        css2[!, wx] = Vector{Union{Missing, String}}(undef, nrow(css2));

        # connections data at wave w
        i__con = @views __con[__con.wave .== w, :]
        
        # use connections data at wave w to
        # fill dictionary for quick access to the relationships
        # between pairs (pairs without any relationships have no entries...)
        for (eg, al, an) in zip(i__con.ego, i__con.alter, i__con.answers)
            ___con[(eg, al)] = an
        end

        for (l, (a1, a2, rel, answ)) in enumerate(
                zip(css2.alter1, css2.alter2, css2.relation, css2.response)
            ) # N.B. not tracking village code
            
            # get the relations between those two at wave
            out1 = get(___con, (a1, a2), String[])
            out2 = get(___con, (a2, a1), String[])

            # check existence for each alter
            ca1 = get(namedict, a1, missing)
            ca2 = get(namedict, a2, missing)
            
            #=  check if i and j are present in respondent data at wave x
                for now, only check the wave, don't check whether the villages
                are the same
            =#

            # this conditional parses "No" does not exist vs. 
            # the tie could not possibly exist because at least one individual
            # is not even present at wave
            css2[l, wx] = tieverity(rel, answ, out1, out2, ca1, ca2, w)
        end
    end

    return css2, known
end

function make_namedict(resp, con)
    # __con
    # get the unique set of individuals, their waves and their villages at each wave
    # why are there more entries when we have the combination of
    # respondents and connections?
    # add village code if we want to track movement or limit to within village networks

    uresp = unique(resp[!, [:wave, :name, :village_code]]);
    xx = unique(con[!, [:wave, :ego, :alter, :village_code]]);
    ucon = unique(DataFrame(:wave => vcat(xx.wave, xx.wave), :name => vcat(xx.ego, xx.alter), :village_code => vcat(xx.village_code, xx.village_code)));
    ur = unique(vcat(uresp, ucon))
    sort!(ur, [:name, :wave, :village_code])
    ur = groupby(ur, [:name])
    ur = combine(ur, :wave => Ref => :waves, :village_code => Ref => :village_codes)
    
    return Dict(ur.name .=> tuple.(ur.waves, ur.village_codes))
end;

function tieverity(rel, answ, out1, out2, ca1, ca2, w)
    return if ismissing(ca1) | ismissing(ca2)
        # if not both are present
        "Not both present"
    elseif !((w ∈ ca1[1]) & (w ∈ ca2[1]))
        # if not both present at wave
        "Not both present at wave"
        # if there is a relationship but an alter does not exist at wave
        # c1 = (w ∈ ca1[1]) & (w ∈ ca2[1]);
        # if !c1 & (length(out) != 0)
        #     error("problem " * string(l) * ":" * string(w))
        # end
    else
        # if both are present at wave, evaluate the relationship

        # three cases
        # 1. know each other -> count if there is some relationship
        # 2. are related -> count if either nominates kin
        # 3. free time or personal private -> count if that tie is present in list

        if (rel == "know_each_other")
            p1 = (length(out1) > 0)
            p2 = (length(out2) > 0)
            tiedirection(p1, p2)

        elseif (rel == "are_related")
            p1 = answ ∈ out1
            p2 = answ ∈ out2

            # if either reports it, count it
            if p1 | p2
                answ
            else
                "None of the above"
            end

        else
            p1 = rel ∈ out1
            p2 = rel ∈ out2
            tiedirection(p1, p2)

        end
    end
end

function tiedirection(p1, p2)
    return if p1 & !p2
        "Alter1"
    elseif !p1 & p2
        "Alter2"
    elseif p1 & p2
        "Yes"
    else
        "No"
    end
end

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
    return if length(con_rels) > 0
        if css_r == "know_each_other"
            "Yes"
        elseif css_r ∈ con_rels
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
                "None of the above"
            end
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

"""
        test_relations(con2)

Check for reasonability in the family data. Make sure that categories do not
overlap. If they do, we need to change some code.
"""
function test_relations(con2)
    for e in con2.relationships
        if ("Parent/child" ∈ e) & ("Siblings" ∈ e)
            error("ground truth problem")
        end
    end
    return true
end

"""
        recode_vars!(
            con;
            parent_child = ["father", "mother", "child_over12_other_house"]
        )

Use the CSS entries for the family relationships.
"""
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
