# networktools.jl

"""
        reciprocated(con)

Add a column indicating whether tie is recipricated. In constrast to using
non-unique, this marks both directions.

"""
function reciprocated(con)
    df = select(con, [:ego, :alter, :relationship, :village_code, :wave]);
    sortedges!(df.ego, df.alter)
    nu = df[nonunique(df), :]; # one of every duplicate
    nu2 = deepcopy(nu);
    rename!(nu2, :ego => :a, :alter => :ego)
    rename!(nu2, :a => :alter)
    append!(nu, nu2)
    nu[!, :reciprocated] .= true; # both directions (both are true for duplicated entries under ego-alter sort)

    # match duplicated entries to each direction present in the con data
    con = leftjoin(con, nu, on = [:ego, :alter, :relationship, :village_code, :wave]);
    con.reciprocated[ismissing.(con.reciprocated)] .= false
    disallowmissing!(con, :reciprocated)
    return con
end
