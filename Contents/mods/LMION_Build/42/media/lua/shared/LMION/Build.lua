require "LMION/Core"

LMION.Build = LMION.Build or {}
local Build = LMION.Build

Build.ID = "LMION_Build"
Build.VERSION = "0.0.5-dev"

require "LMION/Build/LargeGateProfiles"
require "LMION/Build/VanillaLargeGateSplit"

LMION.registerModule(Build.ID, Build)
LMION.log("Build", "loaded " .. Build.VERSION)

return Build
