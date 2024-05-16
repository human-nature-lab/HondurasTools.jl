# bootellipse.jl

function estextract(rx, r)
    a = if r == :tpr
        rx[[:tpr, :err_tpr]]
    elseif r == :fpr
        rx[[:fpr, :err_fpr]]
    elseif r == :j
        rx[[:j, :err_j]]
    end
    return a
end

export estextract

function bs_cov(tpr, fpr; iters = 20_000)
    dsts = (tpr = HondurasTools.Normal(tpr...), fpr = HondurasTools.Normal(fpr...), )
    pts = Vector{Point2f}(undef, iters)
    Threads.@threads for i in eachindex(pts)
        pts[i] = Point2f(rand(dsts.tpr), rand(dsts.fpr))
    end
    return cov(pts)
end

export bs_cov

"""
addΣ!(marginsdict)

## Description

Add bootstrapped Σ to calculate confidence ellipse to the margins dictionary.

"""
function addΣ!(marginsdict)
	for (_, (rg, _)) in marginsdict
		if "tpr" ∈ names(rg)
			rg.Σ = [bs_cov(estextract(rx, :tpr), estextract(rx, :fpr)) for rx in eachrow(rg)];
		end
	end
end

export addΣ!
