(pwd() != @__DIR__) && cd(@__DIR__) # allow starting app from bin/ dir

using ScoringEngineApp
const UserApp = ScoringEngineApp
ScoringEngineApp.main()
