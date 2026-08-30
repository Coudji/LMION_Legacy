local LMION = require "LMION/API"
local Bootstrap = require "LMION/Core/Bootstrap"
local Diagnostics = require "LMION/Core/Diagnostics"

Bootstrap.run(LMION)
Diagnostics.logBootstrap(LMION)


local function onGameBoot()
    Diagnostics.logGameBoot(LMION)
end


Events.OnGameBoot.Add(onGameBoot)
