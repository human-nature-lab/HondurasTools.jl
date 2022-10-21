# css_process.jl
# process the raw (not pre-processed by Liza) CSS data from Trellis

function process_raw(raw, key)
    out = DataFrame(
        :perceiver => String[],
        :edge_id => String[],
        :question => Int[],
        :ego_resp => String[],
        :alter_resp => String[]
    );

    process_raw!(out, raw);
    out = leftjoin(out, key, on = :edge_id);

    return out
end

function process_raw!(out, raw)
    for r in eachrow(raw)
        if occursin(";", r.eg9999)
            lnp = split(r.eg9999, ";");
            pairnum = length(lnp)
            
            for c1 in 1:6
                o_count = "0" * string(c1) * "00"
                for (c2, j) in zip(1:2:80, 1:40)
                    try
                        i_count_1 = "_r" * if c2 < 10
                            "0" * string(c2)
                        else
                            string(c2)
                        end

                        i_count_2 = "_r" * if c2+1 < 10
                            "0" * string(c2+1)
                        else
                            string(c2+1)
                        end

                        # idx = findfirst(names(raw) .== "eg" * o_count * i_count);

                        push!(
                            out,
                            [
                                r[:respondent_master_id],
                                lnp[j],
                                c1,
                                r["eg" * o_count * i_count_1],
                                r["eg" * o_count * i_count_2]
                            ]
                        )
                    catch
                        error(println(r, c1, c2, j))
                    end
                end
            end
        end

    end
end

function process_key(key)
    key = key[.!(key.question_no_one .== "1"), :];

    select!(key, :edge_id, :ego_id, :alter_id);
    key = unique(key);

    sortedges!(key.ego_id, key.alter_id)
    return key
end

function process_edges!(edges, css_relationships)
    @subset!(edges, :alter_source .== 1, :same_village .== "1");
    select!(edges, Not([:same_village, :alter_source]))
    @subset!(edges, :relationship .∈ Ref(css_relationships));
    sortedges!(edges.ego, edges.alter)
end

# """
# prepare the edges to be joined to the css data
# we want wide format for kin, 
# """
# function edgesprocess!()
#     # sort and collapse
#     # did we sort css (check above)???
#     # yes but not in the processing function -> resolve

