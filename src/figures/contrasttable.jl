# contrasttable.jl
# contrast_table_typ utilities

# statistic order in table
@inline ord(x) = if x == "ci"
    2
elseif x == "p"
    3
elseif x == "estimate"
    1
else 4
end

# find change points in a vector
function vecdiff(x)
    b = Vector{Bool}(undef, length(x))
    for i in 2:length(x)
        b[i] = x[i] == x[i-1]
    end
    b[1] = false
    return .!b
end

"""
    contrasttable(cts)

Generate a contrast contrast table from a set of formatted (combined for TPR and FPR, with J calculations performed already) reference grids that have been passed through emmpairs, `cts`, or have contrasts calculated already.

Preparation for convertion to Typst table.
"""
function contrasttable(cts)
    dfe = deepcopy(cts);

    vs = ["tpr", "fpr", "j"]
    for v in vs
        dfe[!, "p_"*v] = ifelse(
            eltype(dfe[!, v]) <: AbstractFloat,
            round.(pvalue.(dfe[!, v], dfe[!, "err_" * v]); digits = 4),
            v
        )
    end
    vs = [:ci_tpr, :ci_fpr, :ci_j, :tpr, :fpr, :j]
    for v in vs
        dfe[!, v] = round.(dfe[!, v]; digits = 3);
    end

    # nicer contrast names for binary variables
    dfe.Contrast = replace(
        dfe.Contrast, "true > false" => "Yes > No", "false > true" => "No > Yes",
        "free_time > personal_private" => "Free Time > Personal Private",
        "personal_private > free_time" => "Personal Private > Free Time"
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

    dout.vardiff = .!vecdiff(dout.Variable)
    dout.Variable[.!vecdiff(dout.Variable)] .= ""
    return dout
end

export contrasttable

function contrast_table_rg(rg, e; emptyval = NaN)
    
    df_ = deepcopy(rg)
    
    c1 = "tpr" ∈ names(df_)
    c2 = "fpr" ∈ names(df_)

    if c1
        df_tpr = select(df_, e, :tpr, :err_tpr)
        x1 = empairs(df_tpr; eff_col = :tpr, err_col = :err_tpr)
        x1.ci_tpr = ci.(x1.tpr, x1.err_tpr)
    end

    if c2
        df_fpr = select(df_, e, :fpr, :err_fpr)
        x2 = empairs(df_fpr; eff_col = :fpr, err_col = :err_fpr)
        x2.ci_fpr = ci.(x2.fpr, x2.err_fpr)
    end

    if c1 & c2
        df_j = select(df_, e, :j, :err_j)
        x3 = empairs(df_j; eff_col = :j, err_col = :err_j)
        x3.ci_j = ci.(x3.j, x3.err_j)
    end

    return if c1 & c2
        hcat(
            x1,
            x2[!, [:fpr, :err_fpr, :ci_fpr]],
            x3[!, [:j, :err_j, :ci_j]]
        )
    elseif c1 & !c2
        x1.fpr .= emptyval
        x1.err_fpr .= emptyval
        x1.ci_fpr = [(emptyval, emptyval) for _ in 1:nrow(x1)]
        x1.j .= emptyval
        x1.err_j .= emptyval
        x1.ci_j = [(emptyval, emptyval) for _ in 1:nrow(x1)]
        x1
    elseif !c1 & c2
        x2.tpr .= emptyval
        x2.err_tpr .= emptyval
        x2.ci_tpr = [(emptyval, emptyval) for _ in 1:nrow(x2)]
        x2.j .= emptyval
        x2.err_j .= emptyval
        x2.ci_j = [(emptyval, emptyval) for _ in 1:nrow(x2)]
        x2
    end
end

function var_add!(
    cts, e, md; rounddigits = 2, allcomb = false, dosort = true
)

    rg, mrgvarname = md[e]
    df_ = @subset rg .!$kin

    if (eltype(df_[!, e]) <: AbstractFloat) & !allcomb
        @subset! df_ $e .∈ Ref(extrema(df_[!, e]))
        if !isnothing(rounddigits)
            df_[!, e] = round.(df_[!, e]; digits = rounddigits)
        end
    end
    
    if dosort
        sort!(df_, e; rev = true)
    end

    ct = contrast_table_rg(df_, e)
    rename!(ct, e => :Contrast)
    ct.Variable .= mrgvarname;
    ct.vbl .= e;
    append!(cts, ct)
end

export var_add!

function var_add!(
    cts, e, mrgvarname, df; rounddigits = 2, dosort = true
)

    df_ = deepcopy(df)

    if (eltype(df_[!, e]) <: AbstractFloat)
        if !isnothing(rounddigits)
            df_[!, e] = round.(df_[!, e]; digits = rounddigits)
        end
    end
    
    if dosort
        sort!(df_, e; rev = true)
    end

    ct = contrast_table_rg(df_, e)
    rename!(ct, e => :Contrast)
    ct.Variable .= mrgvarname;
    ct.vbl .= e;

    append!(cts, ct)
end

export var_add!
