# adjustedcoeftable.jl

function adjustedcoeftable(m, varcovmat)
    m_c = coeftable(m) |> DataFrame;
    m_c[!, "Std. Error Adj."] = sqrt.(diag(varcovmat));

    m_c[!, "Pr(>|z|) Adj."] = pvalue.(m_c[!, "Coef."], m_c[!, "Std. Error Adj."])

    m_c[!, "Lower 95% Adj."] .= NaN
    m_c[!, "Upper 95% Adj."] .= NaN

    for (i, (e1, e2)) in (enumerate∘zip)(m_c[!, "Coef."], m_c[!, "Std. Error Adj."])
        m_c[i, "Lower 95% Adj."], m_c[i, "Upper 95% Adj."] = ci(e1, e2)
    end
    return m_c
end

export adjustedcoeftable
