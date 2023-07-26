# groundtruth.jl

function widecon(con; sort = false)
    _con = deepcopy(con)

    if sort
        sortedges!(_con.ego, _con.alter)
    end

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
    return __con
end

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

    css2 = DataFrames.stack(
        css2,
        ["know_each_other", "free_time", "personal_private", "are_related"];
        variable_name = :relation, value_name = :response
    )

    dropmissing!(css2)

    __con = widecon(con; sort = false)
    
    namedict = make_namedict(resp, __con)

    ___con = Dict{Tuple{String, String}, Vector{String}}();
    sizehint!(___con, 500000);

    # we need an additional check for prior waves to ensure that both elements of the pair exist in the data -- whether they are related or not

    for (i, (w, wx)) in enumerate(zip([4, 3, 1], [:w4, :w3, :w1]))
        empty!(___con)
        # note the ground truth status of the tie for the relation
        css2[!, wx] = Vector{Union{Missing, String}}(missing, nrow(css2));
        # separately track whether a tie is truly kin
        kinvar = Symbol("kin_" * string(wx))
        css2[!, kinvar] = Vector{Union{Missing, Bool}}(missing, nrow(css2));

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
            css2[l, kinvar] = kinstatus(out1, out2)
        end
    end

    css2.kin = Vector{Union{Missing, Bool}}(missing, nrow(css2))
    for i in 1:length(css2.kin)
        css2[i, :kin] = passmissing(any)(
            [css2.kin_w4[i], css2.kin_w3[i], css2.kin_w3[i]]
        )
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

"""
        tieverity(rel, answ, out1, out2, ca1, ca2, w)

### Description

Determines the truth of a CSS response, noting the directionality of the tie.

### Arguments

- `rel` : relationship string
- `answ` : true relationship string
- `w` : wave

"""
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
            tiedirection(rel ∈ out1, rel ∈ out2)
        end
    end
end

function kinstatus(out1, out2)
    p1 = (length(out1) > 0)
    p2 = (length(out2) > 0)
    if p1 | p2 
        # if either nominates, count it
        for ax in [out1, out2]
            for e in ax
                if e == "are_related" # ["Parent/child", "Siblings", "Partners"]
                    return true
                end
            end
        end
        # if return is not triggered by presence
        return false
    else
        false
    end
end

"""
        tiedirection(p1, p2)

Determine the direction of the tie.
- both nominate => "Yes"
- alter 1 nominates => "Alter1"
- alter 2 nominates => "Alter2"
- neither nominates => "No"

"""
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
