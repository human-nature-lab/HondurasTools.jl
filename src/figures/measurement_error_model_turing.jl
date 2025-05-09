# turing_two.jl

using Turing, Distributions, FillArrays
using DataFrames
import RDatasets

# Set a seed for reproducibility.
using Random
Random.seed!(0)

# Import the "Default" dataset.
data = RDatasets.dataset("datasets", "mtcars");

# Show the first six rows of the dataset.
first(data, 6)

# Import the "Default" dataset.
data = RDatasets.dataset("datasets", "mtcars");

# Show the first six rows of the dataset.
first(data, 6)

# Bayesian linear regression.
@model function linear_regression(x, y)
    # Set variance prior.
    σ² ~ truncated(Normal(0, 100); lower=0)

    # Set intercept prior.
    intercept ~ Normal(0, sqrt(3))

    # Set the priors on our coefficients.
    nfeatures = size(x, 2)
    coefficients ~ MvNormal(Zeros(nfeatures), 10.0 * I)

    # Calculate all the mu terms.
    mu = intercept .+ x * coefficients
    return y ~ MvNormal(mu, σ² * I)
end

train = Matrix(select(data, Not(:MPG, :HP)))[:, 2:end]

model = linear_regression(train, data.MPG)
chain = sample(model, NUTS(0.65), 1_000)

# assume HP is uncertain

# Bayesian linear regression.
@model function linear_regression_error(x, x_meas, x_var, y)
    N = length(y)
    
    # Set variance prior.
    σ² ~ truncated(Normal(0, 100); lower=0)
    
    # priors for latent variable x_true params
    μ_x ~ Normal(0, 10)
    σ_x ~ truncated(Normal(0, 100); lower=0)

    # Priors for the latent variable x_true
    x_true = Vector{Real}(undef, N)
    for i in 1:N
        x_true[i] ~ Normal(μ_x, σ_x)
    end

    # Measurement model: relate latent x_true to observed x_meas
    for i in 1:N
        x_meas[i] ~ Normal(x_true[i], x_var[i])
    end

    # Set intercept prior.
    intercept ~ Normal(0, sqrt(3))

    # Set the priors on our coefficients.
    nfeatures = size(x, 2)
    coefficients ~ MvNormal(Zeros(nfeatures), 10.0 * I)

    γ ~ Normal(0, 10.0)

    # Calculate all the mu terms.
    mu = intercept .+ x * coefficients .+ x_true * γ
    return y ~ MvNormal(mu, σ² * I)
end

vr = fill(0.1, nrow(data))
model2 = linear_regression_error(train, data.HP, vr, data.MPG)
chain2 = sample(model2, NUTS(0.65), 1_000)

df2 = DataFrame(chain2)

select(df2, Between("coefficients[1]", "coefficients[9]"), "γ")

std(df2.γ)

vr2 = fill(100, nrow(data))
model3 = linear_regression_error(train, data.HP, vr2, data.MPG)
chain3 = sample(model3, NUTS(0.65), 1_000)

df3 = DataFrame(chain3)

std(df3.γ)