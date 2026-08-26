require "LMION/Core"

LMION.Build = LMION.Build or {}
local Build = LMION.Build

Build.ID = "LMION_Build"
Build.VERSION = "0.0.5-dev"

--[[
Build.lua is the module bootstrap. Large-gate profile derivation and vanilla
SpriteConfig ownership are kept in focused modules because they have different
lifecycle responsibilities.
]]
require "LMION/Build/LargeGateProfiles"
require "LMION/Build/VanillaLargeGateSplit"

LMION.registerModule(Build.ID, Build)
LMION.log("Build", "loaded " .. Build.VERSION)

return Build
