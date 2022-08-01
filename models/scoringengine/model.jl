"""
logit

The logit function is the quantile function associated with the standard logistic distribution.
"""
logit(x::Real) = 1 / (1 + exp(-x))
logit(x::AbstractVector) = 1 ./ (1 .+ exp.(-x))
