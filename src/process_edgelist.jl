# process_edgelist.jl

"""
        process_edgelist!(
            edgelist;
            relations = nothing,
            symmetric = true,
            alter_source = false,
            alter₁ = :ego,
            alter₂ = :alter,
            restrict = true
        )

Preprocess the connections data (e.g., "honduras_connections_WAVE3_v3.csv").
N.B. that the same edge will be repeated for each relationship that exists.

ARGS
====

- `relations` : If relations is not specified, all relations will be included, otherwise, specify a vector (of strings) for each desired relationship.
- `symmetric` : If symmetric, the edges will be sorted based on the respondent ids.
- `alter_source` : If true, assume that alter_source exists in the input connections data, and filter to alter_source = 1.
- `alter₁` : the column name that gives the first node.
- `alter₂` : the column name that gives the second node.

"""
function process_edgelist!(
    edgelist;
    relations = nothing,
    symmetric = true,
    alter_source = false,
    alter₁ = :ego,
    alter₂ = :alter,
    restrict = true
)

    # filter to those that received a survey
    if alter_source
        deleteat!(edgelist, conn.alter_source .!= 1)
    end

    # filter to those in the desired relationship(s)
    if !isnothing(relations)
        deleteat!(edgelist, edgelist.relationship .∉ Ref(relations));
    end

    # Sort the edges into alphabetical order (of the respondent id)
    # (so that an edge is not counted twice accidentally,
    # due to different order)
    if symmetric
        sortedges!(edgelist[!, alter₁], edgelist[!, alter₂])
    end

    if restrict
        select!(edgelist, [alter₁, alter₂])
    end

    return edgelist
end

function process_edgelist(
    edgelist_input;
    relations = nothing,
    symmetric = true,
    alter_source = false,
    alter₁ = :ego,
    alter₂ = :alter,
    restrict = true
)

    edgelist = deepcopy(edgelist_input)

    process_edgelist!(
        edgelist;
        relations = relations,
        symmetric = symmetric,
        alter_source = alter_source,
        alter₁ = alter₁,
        alter₂ = alter₂,
        restrict = restrict
    )

    return edgelist
end
