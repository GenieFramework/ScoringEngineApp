module ScoringEngineDemo

using Flux, EvoTrees, Loess
using EvoTrees: predict
using DataFrames, CSV
using StipplePlotly, PlotlyBase

using StatsBase: sample, quantile
using Statistics: mean, std

export logit
export one_way_data, one_way_plot, one_way_plot_weights

export get_shap_importance,
    get_shap_effect,
    plot_shap_importance,
    plot_shap_effect,
    get_shap_explain,
    plot_shap_explain

const j_blue = "#4063D8"
const j_green = "#389826"
const j_purple = "#9558B2"
const j_red = "#CB3C33"

include("preproc-utils.jl")
include("model.jl")
include("plots.jl")
include("explain.jl")

end
