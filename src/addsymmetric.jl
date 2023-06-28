# addsymmetric.jl

function addsymmetric!(con)
    kin = [
        "father", "mother", "sibling", "child_over12_other_house", "partner"
    ];
    kindict = Dict(
        "father" => "Parent/child",
        "mother" => "Parent/child",
        "child_over12_other_house" => "Parent/child",
        "sibling" => "Siblings",
        "partner" => "Partners"
    );

    con.kintype = Vector{Union{String, Missing}}(missing, nrow(con));
    fcon = @views con[con.relationship .∈ Ref(kin), :];
    for (i, e) in enumerate(fcon.relationship)
        fcon.kintype[i] = get(kindict, e, e)
    end

    con.relationship[con.relationship .∈ Ref(kin)] .= "are_related";

    # create unordered `tie` variable
    # that indexes the unique pairs (without reference to order)
    con.tie = Vector{Set{String}}(undef, nrow(con))
    for (i, (z1, z2)) in enumerate(zip(con.ego, con.alter))
        con.tie[i] = Set([z1, z2])
    end;

    # track whether relationship is symmetric/reciprocated
    con.symmetric = fill(false, nrow(con))

    gc = groupby(con, [:tie, :relationship, :wave, :village_code, :kintype])

    if sort(unique(combine(gc, nrow => :count).count)) != [1,2]
        error("problem")
    end

    for gr in gc
        if nrow(gr) == 2
            con[parentindices(gr)[1], :symmetric] .= true
        end
    end

    intr = intersect(con.ego, con.alter);
    interdict = Dict(intr .=> true)
    con.alter_as_ego = Vector{Bool}(undef, nrow(con))
    for (i, e) in enumerate(con.alter)
        con.alter_as_ego[i] = get(interdict, e, false)
    end
end
