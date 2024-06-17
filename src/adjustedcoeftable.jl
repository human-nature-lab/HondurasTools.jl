# adjustedcoeftable.jl

function adjustedcoeftable(m, varcovmat; overwrite = false)

    # add "Adj." to name if we don't want to overwrite.
    se_name = ifelse(!overwrite, "Std. Error Adj.", "Std. Error")
    p_name = ifelse(!overwrite, "Pr(>|z|) Adj.", "Pr(>|z|)")
    l_name = ifelse(!overwrite, "Lower 95% Adj.", "Lower 95%")
    u_name = ifelse(!overwrite, "Upper 95% Adj.", "Upper 95%")

    m_c = coeftable(m) |> DataFrame;
    
    # adjusted se
    m_c[!, se_name] = sqrt.(diag(varcovmat));

    # adjusted p
    m_c[!, p_name] = pvalue.(m_c[!, "Coef."], m_c[!, se_name])

    # adjusted confidence intervals
    m_c[!, l_name] .= NaN
    m_c[!, u_name] .= NaN

    for (i, (e1, e2)) in (enumerate∘zip)(
        m_c[!, "Coef."], m_c[!, se_name]
    )
        m_c[i, l_name], m_c[i, u_name] = ci(e1, e2)
    end

    return m_c
end

export adjustedcoeftable
