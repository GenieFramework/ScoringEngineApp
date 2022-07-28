using Stipple
using StippleUI
using StipplePlotly

using Stipple.Pages
using Stipple.ModelStorage.Sessions

using ScoringEngineApp
using ScoringEngineApp.ScoringEngine

if Genie.Configuration.isprod()
  Genie.Assets.assets_config!([Genie, Stipple, StippleUI, StipplePlotly], host = "https://cdn.statically.io/gh/GenieFramework")
end

Page("/", view = "views/scoreboard.jl.html",
          layout = "layouts/app.jl.html",
          model = () -> ScoringEngineApp.ScoringEngine.Score |> init_from_storage |> ScoringEngine.handlers,
          context = @__MODULE__)
