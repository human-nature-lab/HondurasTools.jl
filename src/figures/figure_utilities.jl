# figure_utilities.jl

"""
        ratecolor(x)

## Description

"""
function ratecolor(x)
    return if x == :tpr
        yale.blues[3]
    elseif (x == :fpr) | (x == :tnr)
        # yale.accent[2]
        columbia.secondary[1]
    elseif (x == :peirce) | (x == :j)
        yale.blues[3]-columbia.secondary[1]
        # yale.accent[1]
    else
        oi[7]
    end
end

export ratecolor

"""
        chanceline!(ax)

## Description

Add line of chance to ROC-space plot, the line L"y = x".
"""
function chanceline!(ax; linestyle = :dot, color = yale.grays[1], tr = 0.9)
    lines!(ax, (0.0:0.1:1.0), 0:0.1:1.0; linestyle, color = (color, tr))
end

"""
        improvementline!(ax)

## Description

Add direction of improvement to ROC-space plot. The line represents the
direction along which acuracy improves without changing the ratio TPR:FPR.

This is the line L"y = 1 - x".
"""
function improvementline!(ax; tr = 0.9, linestyle = :dash)
    # line of improvement
    lines!(ax, (0.5:-0.1:0), 0.5:0.1:1; linestyle, color = (yale.accent[1], tr))
    lines!(ax, (1:-0.1:0.5), 0:0.1:0.5; linestyle, color = (yale.accent[2], tr))
end
