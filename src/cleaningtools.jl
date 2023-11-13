# cleaningtools.jl

function strclean!(v, nv, rf, rf_desc, namedict)
    if v ∈ rf_desc.variable
        namedict[nv] = v;
        rename!(rf, v => nv);
        irrelreplace!(rf, nv);
    end
end

function bstrclean!(v, nv, rf, rf_desc, namedict)
    if v ∈ rf_desc.variable
        namedict[nv] = v;
        rename!(rf, v => nv);
        irrelreplace!(rf, nv);
        binarize!(rf, nv);
    end
end

function numclean!(v, nv, rf, rf_desc, namedict; tpe = Int)
    if v ∈ rf_desc.variable
        namedict[nv] = v;
        rename!(rf, v => nv);
        irrelreplace!(rf, nv);
        # fpass step in case parser has mixed and/or weird typing
        fpass = passmissing(string).(rf[!, nv])
        rf[!, nv] = passmissing(parse).(tpe, fpass);
    end;
end

export strclean!, bstrclean!
export numclean!
