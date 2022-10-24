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

    # remove wave from village name variables, since they are going to be
    # combined into a single DataFrame with consistent naming
    village_vars = Dict(
        "village_code_w" => :village_code,
        "village_name_w" => :village_name,
        "municipality_w" => :municipality
    );

    for (i, w) in enumerate(waves)
        nme = names(conns[i])
        handle_villagevars!(conns[i], w, nme, village_vars)
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
        nminter = intersect([names(e) for e in conns]...)
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

function handle_villagevars!(connsi, w, nme, village_vars)
    for (k, v) in village_vars
        kw = k * string(w)
        if any(occursin.(kw, nme))
            rename!(connsi, Symbol(kw) => v,)
        end
    end
end
