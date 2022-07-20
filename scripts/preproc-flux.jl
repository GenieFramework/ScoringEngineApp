include("../models/scoringengine/ScoringEngineExport.jl")

using DataFrames
using Statistics
using StatsBase: sample
using BSON
using CairoMakie
using Random

using Flux
using Flux: update!

global targetname = "event"

const result_path = joinpath(@__DIR__, "..", "assets")
const assets_path = joinpath(@__DIR__, "..", "assets")
df_tot = ScoringEngineExport.load_data("assets/training_data.csv")

# minimal DF verbs
dfg = groupby(df_tot, "pol_coverage")
df = combine(dfg, [:vh_age, :vh_value] .=>  mean ∘ skipmissing .=> [:vh_age, :vh_value])
select(df, ["pol_coverage", "vh_value"])

# set target
transform!(df_tot, "claim_amount" => ByRow(x -> x > 0 ? 1.0f0 : 0.0f0) => "event")

norm_feats = ["vh_age", "vh_value", "vh_speed", "vh_weight", "drv_age1",
    "pol_no_claims_discount", "pol_coverage", "density", 
    "drv_exp_yrs", "pol_duration", "pol_sit_duration",
    "drv_sex1", "has_drv2", "is_drv2_male"]

# train/eval split
Random.seed!(123)
df_train, df_eval = ScoringEngineExport.data_splits(df_tot, 0.9)

density(collect(skipmissing(df_train.vh_age)))
density(collect(skipmissing(df_train.drv_age1)))

preproc = ScoringEngineExport.build_preproc(df_train, norm_feats = norm_feats)
adapter = ScoringEngineExport.build_adapter_flux(norm_feats, targetname)

df_train_pre = preproc(df_train)

density(collect(skipmissing(df_train_pre.vh_age)))
density(collect(skipmissing(df_train_pre.drv_age1)))

BSON.bson("assets/preproc-flux.bson", Dict(:preproc => preproc))
BSON.bson("assets/adapter-flux.bson", Dict(:adapter => adapter))