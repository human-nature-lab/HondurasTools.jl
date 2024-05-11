"""
    contrasttable(cts)

Generate a contrast contrast table from a set of formatted (combined for TPR and FPR, with J calculations performed already) reference grids that have been passed through emmpairs, `cts`, or have contrasts calculated already.
"""
function contrasttable(cts)
    dfe = deepcopy(cts);

    vs = ["tpr", "fpr", "j"]
    for v in vs
        dfe[!, "p_"*v] = round.(pvalue.(dfe[!, v], dfe[!, "err_" * v]); digits = 4)
    end
    vs = [:ci_tpr, :ci_fpr, :ci_j, :tpr, :fpr, :j]
    for v in vs
        dfe[!, v] = round.(dfe[!, v]; digits = 3);
    end

    # nicer contrast names for binary variables
    dfe.Contrast = replace(
        dfe.Contrast, "true > false" => "Yes > No", "false > true" => "No > Yes",
        "free_time > personal_private" => "Free Time > Personal Private"
    );

    dfe.Subject = ifelse.(occursin.("_a", string.(dfe[!, "vbl"])), "Tie", "Respondent")
    select!(dfe, Not(:vbl))

    dfl = stack(dfe, Not([:Contrast, :Subject, :Variable]));

    dfl.metric .= "";
    dfl.statistic .= "";
    for r in eachrow(dfl)
        sp = string.(split(r.variable, "_"))
        if length(sp) > 1
            r.statistic, r.metric = sp
        else
            r.statistic, r.metric = "estimate", sp[1]
        end
    end
    select!(dfl, Not(:variable))

    dfl.ord = ord.(dfl.statistic)
    sort!(dfl, [:Subject, :Variable, :Contrast, :metric, :ord])
    @subset! dfl :statistic .!= "err"

    dfw = @chain dfl begin
        groupby([:Contrast, :Variable, :Subject, :metric])
        combine(:value => Ref => :value)
    end

    dfw.value = [string.(d) for d in dfw.value]
    for i in 1:nrow(dfw)
        for j in 1:2; dfw.value[i][j] = dfw.value[i][j] * " \\ " end
    end
    dfw.value = reduce.(*, dfw.value)

    dout = unstack(dfw, [:Contrast, :Variable, :Subject], :metric, :value);

    select!(dout, :Subject, :Variable, :Contrast, :tpr, :fpr, :j)
    rename!(dout, :tpr => :TPR, :fpr => :FPR, :j => :J);

    dout.Variable[.!vecdiff(dout.Variable)] .= ""
    return dout
end

export contrasttable
