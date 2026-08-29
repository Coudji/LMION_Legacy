require "LMION/Core"

LMION.Build = LMION.Build or {}
local Build = LMION.Build

Build.ID = "LMION_Build"
Build.VERSION = "0.0.6-dev"

require "LMION/Build/LargeGateProfiles"
require "LMION/Build/VanillaLargeGateLeafConstruction"
require "LMION/Build/GarageConstruction"
require "LMION/Build/GarageBuildCursor"

LMION.registerModule(Build.ID, Build)
LMION.log("Build", "loaded " .. Build.VERSION)

return Build
