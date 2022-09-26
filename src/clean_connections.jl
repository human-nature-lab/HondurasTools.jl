# clean_connections.jl

"""
        clean_connections(con_paths)

Process the raw network data (on the server) for waves 1, 2, 3. Creates a DataFrame that contains each wave of data.

Filters to `alter_source = 1`, and `same_village =1`
"""
function clean_connections(
    con_paths; alter_source = true, same_village = true
)

    conns = [CSV.read(
        con_path, DataFrame; missingstring = "NA"
    ) for con_path in con_paths];

    for w in 1:3
        rename!(
            conns[w],
            Symbol("village_code_w" * string(w)) => :village_code,
            Symbol("village_name_w" * string(w)) => :village_name,
            Symbol("municipality_w" * string(w)) => :municipality,
        )
    end

    for i in 1:3; conns[i][!, :wave] .= i end
    
    namesinter = intersect(names(conns[1]), names(conns[2]), names(conns[3]));
    conns = vcat([conns[i][!, namesinter] for i in 1:3]...);
    
    if alter_source
        @subset!(conns, :alter_source .== 1)
    end
    if same_village
        @subset!(conns, :same_village .== 1)
    end
    disallowmissing!(conns)
    return conns
end