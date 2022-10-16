# clean_connections.jl

"""
        clean_connections(con_paths)

Process the raw network data (on the server) for waves 1, 2, 3. Creates a DataFrame that contains each wave of data.

Filters to `alter_source = 1`, and `same_village =1`
"""
function clean_connections(
    conns::Vector{DataFrame},
    waves;
    alter_source = true,
    same_village = true,
    removemissing = true
)

    for (i, w) in enumerate(waves)
        rename!(
            conns[i],
            Symbol("village_code_w" * string(w)) => :village_code,
            Symbol("village_name_w" * string(w)) => :village_name,
            Symbol("municipality_w" * string(w)) => :municipality,
        )
        conns[i][!, :wave] .= w
    end

    conns = if length(conns) < 2
        conns[1]
    else
        #=
        if there are > 1 waves present
        take the common set of variables and combine into a single dataframe
        (this could also be done with regularize cols; but, it doesn'take
        seem necessary)
        =#
        nminter = intersect([names(e) for e in conns])
        reduce(vcat, [e[!, nminter] for e in conns]...);
    end
    
    if alter_source
        @subset!(conns, :alter_source .== 1)
    end

    if same_village
        @subset!(conns, :same_village .== 1)
    end

    if removemissing
        disallowmissing!(conns)
    end

    return conns
end
