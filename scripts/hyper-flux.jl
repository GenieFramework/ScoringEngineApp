using BSON
using CSV
using DataFrames
using Random
using ScoringEngineApp.ScoringEngine

using Distributed
@everywhere using Statistics: mean
@everywhere using Flux
@everywhere using Flux: params, update!
@everywhere using Flux.Losses: logitbinarycrossentropy

results_path = joinpath(@__DIR__, "..", "assets")
isdir(results_path) || mkdir(results_path)
ENV["RESULTS_FILE"] = results_path

@info "nworkers" nworkers()
@info "workers" workers()

@info "Initializing assets"
const assets_path = joinpath(@__DIR__, "..", "assets")
const preproc_flux = BSON.load(joinpath(assets_path, "preproc-flux.bson"), ScoringEngine)[:preproc]
const adapter_flux = BSON.load(joinpath(assets_path, "adapter-flux.bson"), ScoringEngine)[:adapter]

df_tot = ScoringEngine.load_data(joinpath(assets_path, "training_data.csv"))

# set target
transform!(df_tot, "claim_amount" => ByRow(x -> x > 0 ? 1.0f0 : 0.0f0) => "event")

# train/eval split
Random.seed!(123)
df_train, df_eval = ScoringEngine.data_splits(df_tot, 0.9)

df_train = preproc_flux(df_train)
df_eval = preproc_flux(df_eval)

x_train, y_train = adapter_flux(df_train, true)
x_eval, y_eval = adapter_flux(df_eval, true)

@everywhere function loss(m, x, y)
    p = m(x)
    l = logitbinarycrossentropy(p, y; agg=mean)
    return l
end

# cb() = @show(loss(X_eval, y_eval))
@everywhere function logloss(data, m)
    logloss = 0.0
    count = 0
    for (x, y) in data
        p = m(x)
        logloss += logitbinarycrossentropy(p, y; agg=sum)
        count += size(x)[end]
    end
    return logloss / count
end

@everywhere function train_loop!(m, θ, opt, loss; dtrain, deval=nothing)
    for d in dtrain
        grads = gradient(θ) do
            loss(m, d...)
        end
        update!(opt, θ, grads)
    end
    metric = deval === nothing ? logloss(dtrain, m) : logloss(deval, m)
    println(metric)
end

@everywhere function fit(; nrounds, num_feats, h1, dtrain, deval)

    m = Chain(
        BatchNorm(num_feats),
        Dense(num_feats, h1, relu),
        Dropout(0.5),
        Dense(h1, 32, relu),
        SkipConnection(Dense(32, 32, relu), +),
        Dense(32, 1),
        x -> reshape(x, :))

    opt = ADAM(1e-3)
    θ = params(m)

    for i in 1:nrounds
        train_loop!(m, θ, opt, loss, dtrain=dtrain, deval=deval)
    end

    eval_metric = logloss(deval, m)
    return (
        eval_metric=eval_metric,
        h1=h1,
        m=m)
end

num_feats = size(x_train, 1)
nrounds = 25

[@spawnat p x_train = x_train for p in workers()]
[@spawnat p y_train = y_train for p in workers()]
[@spawnat p x_eval = x_eval for p in workers()]
[@spawnat p y_eval = y_eval for p in workers()]

h1_list = 32:32:256
length(h1_list)
@time results = pmap(h1_list) do h1
    dtrain = Flux.Data.DataLoader((x_train, y_train), batchsize=1024, shuffle=true)
    deval = Flux.Data.DataLoader((x_eval, y_eval), batchsize=1024, shuffle=false)
    fit(; nrounds, num_feats, h1, dtrain, deval)
end

df_results = map(results) do n
    (h1=n[:h1], eval_metric=n[:eval_metric])
end |> DataFrame

m_best = results[findmin(df_results[:, :eval_metric])[2]][:m]

CSV.write(joinpath(results_path, "hyper-flux.csv"), df_results)
BSON.bson(joinpath(results_path, "model-flux.bson"), Dict(:model => m_best))