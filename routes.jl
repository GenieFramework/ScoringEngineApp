using Stipple
using StippleUI
using StipplePlotly

using Stipple.Pages
using Stipple.ModelStorage.Sessions

using ScoringEngineApp
using ScoringEngineApp.ScoringEngine


Page("/", view = "views/hello.jl.html",
          layout = "layouts/app.jl.html",
          model = () -> ScoringEngineApp.ScoringEngine.Score |> init_from_storage |> ScoringEngine.handlers,
          context = @__MODULE__)
