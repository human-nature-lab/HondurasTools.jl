# effects!.jl

import Effects:effects!,typify,_difference_method!,something,_responsename

"""
        effects!(
            reference_grid::DataFrame, model::RegressionModel, vcmat;
            eff_col = nothing, err_col = :err, typical = mean, invlink = identity,
        )

## Description

Alternate version of effects! where the variance-covariance matrix is, `vcmat`, is specified explicitly.

`vcov` argument in package-defined version does not take a matrix, but a function that produces the matrix based on a single argument (the model itself).

Consequently, it is not (easily, at least) suitable for 2nd stage adjustment.
"""
function effects!(
    reference_grid::DataFrame, model::RegressionModel, vcmat;
    eff_col = nothing, err_col = :err, typical = mean, invlink = identity,
)
    # right now this is written for a RegressionModel and implicitly assumes
    # the existence of an appropriate formula method
    form = formula(model)

    form_typical = typify(
        reference_grid, form, modelmatrix(model); typical = typical
    )
    X = modelcols(form_typical, reference_grid)
    eff = X * coef(model)
    err = sqrt.(diag(X * vcmat * X'))
    _difference_method!(eff, err, model, invlink)
    reference_grid[!, something(eff_col, _responsename(model))] = eff
    reference_grid[!, err_col] = err
    return reference_grid
    # XXX remove DataFrames dependency
    # this doesn't work for a DataFrame and isn't mutating
    # return (; reference_grid..., depvar => eff, err_col => err)
end

export effects!

"""
Alternate version that does not write to the dataframe
"""
function effects!(yhat, reference_grid::DataFrame, model::RegressionModel;
    typical=mean, invlink=identity,
    vcov=StatsBase.vcov)
    # right now this is written for a RegressionModel and implicitly assumes
    # the existence of an appropriate formula method
    form = formula(model)
    form_typical = typify(reference_grid, form, modelmatrix(model); typical=typical)
    X = modelcols(form_typical, reference_grid)
    eff = X * coef(model)
    err = sqrt.(diag(X * vcov(model) * X'))
    _difference_method!(eff, err, model, invlink)
    yhat .= eff
    # ε .= err
end

export effects!

"""
        varcov_boot(y)

## Description

Boostrapped variance-covariance matrix from bootparams type object. `Y` is the organized-into-vectors version.
"""
function varcov_boot(y)
    mlen = length(y[1]);
    Y = [[y[j][k] for j in 1:length(y)] for k in 1:mlen];
    VC = fill(NaN, mlen, mlen);
    for i in 1:mlen; VC[i,i] = var(Y[i]) end;

    for i in 1:mlen
        for j in 1:mlen
            if i != j
                VC[i, j] = cov(Y[i], Y[j])
            end
        end
    end
    return VC
end

export varcov_boot

"""
        boot_varcov(y)

## Description

Boostrapped variance-covariance matrix from bootparams type object. `Y` is the organized-into-vectors version.
"""
function boot_varcov(Y)
    mlen = length(Y)
    VC = fill(NaN, mlen, mlen);
    for i in 1:mlen; VC[i,i] = var(Y[i]) end;

    for i in 1:mlen
        for j in 1:mlen
            if i != j
                VC[i, j] = cov(Y[i], Y[j])
            end
        end
    end
    return VC
end

export boot_varcov

function boot_effects!(rx2, mx, oc, vcmat, invlink)
    effects!(rx2, mx, vcmat; invlink)
    rx2[!, :lower] = rx2[!, oc] - rx2.err * 1.96
    rx2[!, :upper] = rx2[!, oc] + rx2.err * 1.96
    return rx2
end

export boot_effects!