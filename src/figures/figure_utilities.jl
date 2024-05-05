# figure_utilities.jl

"""
        ratecolor(x)

## Description

"""
function ratecolor(x)
    return if x == :tpr
        oi[5]
    elseif x == :fpr
        oi[6]
    elseif (x == :peirce) | (x == :j)
        oi[7]
    else
        oi[2]
    end
end

"""
        chanceline!(ax)

## Description

Add line of chance to ROC-space plot, the line L"y = x".
"""
function chanceline!(ax)
    lines!(ax, (0.0:0.1:1.0), 0:0.1:1.0; linestyle = :dot, color = (:black))
end

"""
        improvementline!(ax)

## Description

Add direction of improvement to ROC-space plot. The line represents the
direction along which acuracy improves without changing the ratio TPR:FPR.

This is the line L"y = 1 - x".
"""
function improvementline!(ax)
    # line of improvement
    lines!(ax, (0.5:-0.1:0), 0.5:0.1:1; linestyle = :solid, color = oi[3])
    lines!(ax, (1:-0.1:0.5), 0:0.1:0.5; linestyle = :solid, color = oi[6])
end
