# clean_outcomes.jl

function clean_outcomes(
    dfs::Vector{DataFrame},
    waves;
    namedict = nothing
)

    if isnothing(namedict)
        namedict = Dict{Symbol, Symbol}()
    end

    if 1 ∈ waves
        widx = findfirst(waves .== 1)
        nm1 = names(dfs[widx])

        wnme11 = nm1[occursin.("_w1", nm1)]
        strip_wave!(dfs[widx], wnme11, "_w1")
        dfs[widx][!, :wave] .= 1;
    end;

    if 2 ∈ waves
        widx = findfirst(waves .== 2)
        nm2 = names(dfs[widx])

        wnme21 = nm2[occursin.("_w1", nm2)]
        select!(dfs[widx], Not(wnme21))

        wnme22 = nm2[occursin.("_w2", nm2)]
        strip_wave!(dfs[widx], wnme22, "_w2")
        dfs[widx][!, :wave] .= 2;
    end;

    if 3 ∈ waves
        widx = findfirst(waves .== 3)
        nm3 = names(dfs[widx])
        
        wnme31 = nm3[occursin.("_w1", nm3)]
        select!(dfs[widx], Not(wnme31))
        
        wnme32 = nm3[occursin.("_w2", nm3)]
        select!(dfs[widx], Not(wnme32))
    
        wnme33 = nm3[occursin.("_w3", nm3)]
        strip_wave!(dfs[widx], wnme33, "_w3")
        dfs[widx][!, :wave] .= 3;
    end;

    if 4 ∈ waves
        widx = findfirst(waves .== 4)
        nm4 = names(dfs[widx])

        wnme41 = nm4[occursin.("_w1", nm4)];
        select!(dfs[widx], Not(wnme41));

        wnme42 = nm4[occursin.("_w2", nm4)];
        select!(dfs[widx], Not(wnme42));

        wnme43 = nm4[occursin.("_w3", nm4)]
        select!(dfs[widx], Not(wnme43))

        wnme44 = nm4[occursin.("_w4", nm4)];
        strip_wave!(dfs[widx], wnme44, "_w4")

        dfs[widx][!, :wave] .= 4;
    end;
    
    regularizecols!(dfs)
    df = reduce(vcat, dfs);

    rename!(df, :respondent_master_id => :name);
    namedict[:name] = :respondent_master_id;

    return df
end

export clean_outcomes
