# leveljoins

function leveljoins(resp, hh, vill; rwave = 4, hhwave = 3, vwave = 3)
    resp4 = @subset resp :wave .== rwave;
    vill3 = @subset vill :wave .== hhwave;
    hh4 = @subset hh :wave .== vwave;

    [select!(df, Not(:wave)) for df in [resp4, vill3, hh4]];
    
    # make joinable
    if "electricity" ∈ names(vill3)
        rename!(vill3, "electricity" => "electricity_village")
    end
    
    for x in [:office, :municipality, :village_name]
        if string(x) ∈ names(hh4)
            select!(hh4, Not(x))
        end
    end

    for x in [:office, :municipality, :village_name]
        if string(x) ∈ names(vill3)
            select!(vill3, Not(x))
        end
    end
    
    dropmissing!(hh4, :building_id);
    dropmissing!(vill3, :village_code);

    leftjoin!(hh4, vill3, on = [:village_code]);
    leftjoin!(resp4, hh4, on = [:building_id, :village_code])

    return resp4
end;

export leveljoins
